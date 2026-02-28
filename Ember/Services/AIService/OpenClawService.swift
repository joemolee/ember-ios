import Foundation

// MARK: - OpenClawService

/// WebSocket-based AI service that connects to an OpenClaw Gateway.
/// Conforms to `AIServiceProtocol` and returns streamed responses as
/// `AsyncThrowingStream<String, Error>`, matching the `ClaudeService` contract.
///
/// Protocol flow:
///   1. Connect via `URLSessionWebSocketTask` to the configured gateway URL.
///   2. Send a `register` message with client metadata.
///   3. For each chat request, send a JSON payload with conversation history.
///   4. Receive streamed `chunk` messages, a final `done` message, or an `error`.
final class OpenClawService: AIServiceProtocol, @unchecked Sendable {

    // MARK: - Configuration

    /// The gateway URL this service was initialised with. Exposed so AppState
    /// can detect when the user changes the URL and needs a fresh instance.
    let configuredURL: String

    // MARK: - Private State

    private let gatewayURL: URL?
    private let session: URLSession
    private let lock = NSLock()

    /// The long-lived WebSocket connection to the gateway.
    private var webSocketTask: URLSessionWebSocketTask?

    /// The in-flight streaming Task, cancelled on `cancelCurrentRequest()`.
    private var currentTask: Task<Void, Never>?

    /// Tracks whether we have an active, connected WebSocket.
    private var connected: Bool = false

    /// Monotonically increasing request ID to correlate responses.
    private var requestCounter: UInt64 = 0

    // MARK: - AIServiceProtocol Properties

    var isAvailable: Bool {
        lock.lock()
        defer { lock.unlock() }
        return connected && webSocketTask != nil
    }

    var providerName: String { "OpenClaw Gateway" }

    // MARK: - Init

    /// - Parameters:
    ///   - gatewayURL: The WebSocket URL string (e.g. `ws://localhost:3000`).
    ///   - session: The URLSession to use. Defaults to `.shared`.
    init(gatewayURL: String, session: URLSession = .shared) {
        self.configuredURL = gatewayURL
        self.gatewayURL = URL(string: gatewayURL)
        self.session = session
    }

    // MARK: - Connection Lifecycle

    /// Opens the WebSocket connection and sends the initial `register` message.
    /// If already connected, this is a no-op.
    private func connect() async throws {
        lock.lock()
        if connected && webSocketTask != nil {
            lock.unlock()
            return
        }
        lock.unlock()

        guard let url = gatewayURL else {
            throw AIServiceError.invalidConfiguration(
                "Invalid gateway URL: \(configuredURL)"
            )
        }

        let task = session.webSocketTask(with: url)
        task.resume()

        // Send the registration handshake.
        let registerPayload: [String: Any] = [
            "type": "register",
            "client": "ember-ios",
            "version": "1.0",
            "capabilities": ["streaming"]
        ]
        let registerData = try JSONSerialization.data(withJSONObject: registerPayload)
        let registerString = String(data: registerData, encoding: .utf8) ?? "{}"
        try await task.send(.string(registerString))

        lock.lock()
        self.webSocketTask = task
        self.connected = true
        lock.unlock()

        // Start the ping loop to keep the connection alive.
        startPingLoop(for: task)
    }

    /// Gracefully closes the WebSocket connection.
    private func disconnect() {
        lock.lock()
        let task = webSocketTask
        webSocketTask = nil
        connected = false
        lock.unlock()

        task?.cancel(with: .goingAway, reason: nil)
    }

    /// Sends periodic pings to keep the WebSocket connection alive.
    /// The loop exits when the task is cancelled or the connection drops.
    private func startPingLoop(for task: URLSessionWebSocketTask) {
        Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                guard !Task.isCancelled else { return }

                do {
                    try await task.sendPing(pongReceiveHandler: { error in
                        if let error {
                            // Connection dropped; mark as disconnected.
                            self?.lock.lock()
                            if self?.webSocketTask === task {
                                self?.connected = false
                                self?.webSocketTask = nil
                            }
                            self?.lock.unlock()
                            _ = error // suppress unused warning
                        }
                    })
                } catch {
                    // sendPing threw -- connection is gone.
                    self?.lock.lock()
                    if self?.webSocketTask === task {
                        self?.connected = false
                        self?.webSocketTask = nil
                    }
                    self?.lock.unlock()
                    return
                }
            }
        }
    }

    // MARK: - AIServiceProtocol

    func sendMessage(
        _ content: String,
        conversationHistory: [Message],
        model: String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { [weak self] in
                guard let self else {
                    continuation.finish(throwing: AIServiceError.cancelled)
                    return
                }

                do {
                    // Ensure we have a live WebSocket connection.
                    try await self.connect()

                    guard let wsTask = self.lockedWebSocketTask() else {
                        continuation.finish(
                            throwing: AIServiceError.invalidConfiguration(
                                "WebSocket connection not available"
                            )
                        )
                        return
                    }

                    // Build the messages array for the gateway.
                    var apiMessages: [[String: String]] = []

                    for message in conversationHistory {
                        switch message.role {
                        case .user:
                            apiMessages.append([
                                "role": "user",
                                "content": message.content
                            ])
                        case .assistant:
                            apiMessages.append([
                                "role": "assistant",
                                "content": message.content
                            ])
                        case .system:
                            apiMessages.append([
                                "role": "system",
                                "content": message.content
                            ])
                        }
                    }

                    // Append the current user message.
                    apiMessages.append(["role": "user", "content": content])

                    // Assign a unique request ID.
                    self.lock.lock()
                    self.requestCounter += 1
                    let requestID = self.requestCounter
                    self.lock.unlock()

                    let chatPayload: [String: Any] = [
                        "type": "chat",
                        "requestId": requestID,
                        "messages": apiMessages,
                        "model": model,
                        "stream": true
                    ]

                    let chatData = try JSONSerialization.data(withJSONObject: chatPayload)
                    let chatString = String(data: chatData, encoding: .utf8) ?? "{}"
                    try await wsTask.send(.string(chatString))

                    // Listen for response chunks.
                    while !Task.isCancelled {
                        let message: URLSessionWebSocketTask.Message
                        do {
                            message = try await wsTask.receive()
                        } catch {
                            // WebSocket receive failed -- connection likely dropped.
                            self.handleConnectionDrop()
                            continuation.finish(
                                throwing: AIServiceError.networkError(underlying: error)
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
                        case "chunk":
                            if let chunkContent = json["content"] as? String {
                                continuation.yield(chunkContent)
                            }

                        case "done":
                            continuation.finish()
                            return

                        case "error":
                            let errorMessage = json["message"] as? String
                                ?? "Unknown gateway error"
                            continuation.finish(
                                throwing: AIServiceError.streamingError(errorMessage)
                            )
                            return

                        case "pong", "registered", "ack":
                            // Control messages -- ignore.
                            continue

                        default:
                            // Unknown message type -- skip.
                            continue
                        }
                    }

                    // Task was cancelled.
                    continuation.finish(throwing: AIServiceError.cancelled)

                } catch is CancellationError {
                    continuation.finish(throwing: AIServiceError.cancelled)
                } catch let error as AIServiceError {
                    continuation.finish(throwing: error)
                } catch {
                    continuation.finish(
                        throwing: AIServiceError.networkError(underlying: error)
                    )
                }
            }

            lock.lock()
            currentTask = task
            lock.unlock()

            continuation.onTermination = { [weak self] _ in
                task.cancel()
                self?.lock.lock()
                self?.currentTask = nil
                self?.lock.unlock()
            }
        }
    }

    func cancelCurrentRequest() {
        lock.lock()
        currentTask?.cancel()
        currentTask = nil
        lock.unlock()
        // The WebSocket connection is kept alive -- only the in-flight
        // streaming task is cancelled. The next sendMessage call will
        // reuse the existing connection.
    }

    // MARK: - Private Helpers

    /// Thread-safe accessor for the current WebSocket task.
    private func lockedWebSocketTask() -> URLSessionWebSocketTask? {
        lock.lock()
        defer { lock.unlock() }
        return webSocketTask
    }

    /// Marks the connection as dropped and clears the WebSocket reference.
    private func handleConnectionDrop() {
        lock.lock()
        connected = false
        webSocketTask = nil
        lock.unlock()
    }

    deinit {
        // Best-effort cleanup. In practice this runs when AppState swaps
        // the service instance on provider change.
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}
