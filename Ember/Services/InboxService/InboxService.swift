import Foundation

// MARK: - InboxService

/// WebSocket client that connects to the OpenClaw Gateway for inbox message triage.
/// Maintains its own connection, independent of `OpenClawService`, so the inbox
/// subscription stays alive regardless of which AI chat provider is selected.
///
/// Protocol flow:
///   1. Connect to the Gateway and send `register` with `["inbox"]` capability.
///   2. Send `inbox_subscribe` to start receiving triaged messages.
///   3. Receive `inbox_messages` (batch) and `inbox_update` (single) events.
///   4. Optionally send `inbox_refresh`, `inbox_read`, `inbox_config` commands.
final class InboxService: InboxServiceProtocol, @unchecked Sendable {

    // MARK: - Configuration

    let configuredURL: String

    // MARK: - Private State

    private let gatewayURL: URL?
    private let session: URLSession
    private let lock = NSLock()

    private var webSocketTask: URLSessionWebSocketTask?
    private var connected: Bool = false
    private var subscriptionTask: Task<Void, Never>?

    // MARK: - Init

    init(gatewayURL: String, session: URLSession = .shared) {
        self.configuredURL = gatewayURL
        self.gatewayURL = URL(string: gatewayURL)
        self.session = session
    }

    // MARK: - Connection

    private func connect() async throws {
        lock.lock()
        if connected && webSocketTask != nil {
            lock.unlock()
            return
        }
        lock.unlock()

        guard let url = gatewayURL else {
            throw InboxServiceError.invalidConfiguration("Invalid gateway URL: \(configuredURL)")
        }

        let task = session.webSocketTask(with: url)
        task.resume()

        // Registration handshake.
        let registerPayload: [String: Any] = [
            "type": "register",
            "client": "ember-ios",
            "version": "1.0",
            "capabilities": ["inbox"]
        ]
        let data = try JSONSerialization.data(withJSONObject: registerPayload)
        try await task.send(.string(String(data: data, encoding: .utf8) ?? "{}"))

        lock.lock()
        self.webSocketTask = task
        self.connected = true
        lock.unlock()

        startPingLoop(for: task)
    }

    private func disconnect() {
        lock.lock()
        let task = webSocketTask
        webSocketTask = nil
        connected = false
        lock.unlock()

        task?.cancel(with: .goingAway, reason: nil)
    }

    private func startPingLoop(for task: URLSessionWebSocketTask) {
        Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard !Task.isCancelled else { return }

                do {
                    try await task.sendPing { error in
                        if let error {
                            self?.handleConnectionDrop(for: task)
                            _ = error
                        }
                    }
                } catch {
                    self?.handleConnectionDrop(for: task)
                    return
                }
            }
        }
    }

    // MARK: - InboxServiceProtocol

    func subscribe() -> AsyncThrowingStream<InboxEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { [weak self] in
                guard let self else {
                    continuation.finish(throwing: InboxServiceError.cancelled)
                    return
                }

                do {
                    try await self.connect()

                    guard let wsTask = self.lockedWebSocketTask() else {
                        continuation.finish(throwing: InboxServiceError.connectionFailed)
                        return
                    }

                    // Send subscribe command.
                    let subscribePayload = try JSONSerialization.data(
                        withJSONObject: ["type": "inbox_subscribe"]
                    )
                    try await wsTask.send(
                        .string(String(data: subscribePayload, encoding: .utf8) ?? "{}")
                    )

                    continuation.yield(.connected)

                    // Listen for events.
                    while !Task.isCancelled {
                        let message: URLSessionWebSocketTask.Message
                        do {
                            message = try await wsTask.receive()
                        } catch {
                            self.handleConnectionDrop(for: wsTask)
                            continuation.yield(.disconnected)
                            continuation.finish(
                                throwing: InboxServiceError.networkError(underlying: error)
                            )
                            return
                        }

                        let responseData: Data
                        switch message {
                        case .string(let text):
                            responseData = Data(text.utf8)
                        case .data(let data):
                            responseData = data
                        @unknown default:
                            continue
                        }

                        guard let json = try? JSONSerialization.jsonObject(
                            with: responseData
                        ) as? [String: Any] else {
                            continue
                        }

                        let messageType = json["type"] as? String ?? ""

                        switch messageType {
                        case "inbox_messages":
                            if let messagesJSON = json["messages"],
                               let messagesData = try? JSONSerialization.data(withJSONObject: messagesJSON) {
                                let decoder = JSONDecoder()
                                decoder.dateDecodingStrategy = .iso8601
                                if let messages = try? decoder.decode([InboxMessage].self, from: messagesData) {
                                    continuation.yield(.messages(messages))
                                }
                            }

                        case "inbox_update":
                            if let messageJSON = json["message"],
                               let messageData = try? JSONSerialization.data(withJSONObject: messageJSON) {
                                let decoder = JSONDecoder()
                                decoder.dateDecodingStrategy = .iso8601
                                if let inboxMessage = try? decoder.decode(InboxMessage.self, from: messageData) {
                                    continuation.yield(.update(inboxMessage))
                                }
                            }

                        case "inbox_read_confirmed":
                            if let messageID = json["messageId"] as? String {
                                continuation.yield(.readConfirmed(messageID: messageID))
                            }

                        case "pong", "registered", "ack":
                            continue

                        case "error":
                            let errorMessage = json["message"] as? String ?? "Unknown gateway error"
                            continuation.finish(
                                throwing: InboxServiceError.serverError(errorMessage)
                            )
                            return

                        default:
                            continue
                        }
                    }

                    continuation.finish(throwing: InboxServiceError.cancelled)

                } catch is CancellationError {
                    continuation.finish(throwing: InboxServiceError.cancelled)
                } catch let error as InboxServiceError {
                    continuation.finish(throwing: error)
                } catch {
                    continuation.finish(
                        throwing: InboxServiceError.networkError(underlying: error)
                    )
                }
            }

            lock.lock()
            subscriptionTask = task
            lock.unlock()

            continuation.onTermination = { [weak self] _ in
                task.cancel()
                self?.lock.lock()
                self?.subscriptionTask = nil
                self?.lock.unlock()
            }
        }
    }

    func requestRefresh() async throws {
        guard let wsTask = lockedWebSocketTask() else {
            throw InboxServiceError.connectionFailed
        }
        let payload = try JSONSerialization.data(withJSONObject: ["type": "inbox_refresh"])
        try await wsTask.send(.string(String(data: payload, encoding: .utf8) ?? "{}"))
    }

    func markAsRead(messageID: String) async throws {
        guard let wsTask = lockedWebSocketTask() else {
            throw InboxServiceError.connectionFailed
        }
        let payload: [String: Any] = ["type": "inbox_read", "messageId": messageID]
        let data = try JSONSerialization.data(withJSONObject: payload)
        try await wsTask.send(.string(String(data: data, encoding: .utf8) ?? "{}"))
    }

    func sendConfig(vips: [String], topics: [String]) async throws {
        guard let wsTask = lockedWebSocketTask() else {
            throw InboxServiceError.connectionFailed
        }
        let payload: [String: Any] = [
            "type": "inbox_config",
            "vips": vips,
            "topics": topics
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        try await wsTask.send(.string(String(data: data, encoding: .utf8) ?? "{}"))
    }

    func unsubscribe() {
        lock.lock()
        subscriptionTask?.cancel()
        subscriptionTask = nil
        lock.unlock()

        disconnect()
    }

    // MARK: - Private Helpers

    private func lockedWebSocketTask() -> URLSessionWebSocketTask? {
        lock.lock()
        defer { lock.unlock() }
        return webSocketTask
    }

    private func handleConnectionDrop(for task: URLSessionWebSocketTask) {
        lock.lock()
        if webSocketTask === task {
            connected = false
            webSocketTask = nil
        }
        lock.unlock()
    }

    deinit {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}

// MARK: - InboxServiceError

enum InboxServiceError: LocalizedError {
    case invalidConfiguration(String)
    case connectionFailed
    case networkError(underlying: Error)
    case serverError(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let detail):
            return "Invalid inbox configuration: \(detail)"
        case .connectionFailed:
            return "Could not connect to the inbox gateway."
        case .networkError(let underlying):
            return "Inbox network error: \(underlying.localizedDescription)"
        case .serverError(let message):
            return "Inbox server error: \(message)"
        case .cancelled:
            return "Inbox subscription cancelled."
        }
    }
}
