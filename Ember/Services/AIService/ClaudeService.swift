import Foundation

final class ClaudeService: AIServiceProtocol, @unchecked Sendable {

    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let anthropicVersion = "2023-06-01"
    private let maxTokens = 4096
    private let session: URLSession
    private let keychainService: KeychainService

    private var currentTask: Task<Void, Never>?
    private let lock = NSLock()

    var isAvailable: Bool {
        guard let key = try? keychainService.retrieve(key: "claude_api_key") else {
            return false
        }
        return !key.isEmpty
    }

    var providerName: String { "Claude" }

    init(
        keychainService: KeychainService = .shared,
        session: URLSession = .shared
    ) {
        self.keychainService = keychainService
        self.session = session
    }

    func sendMessage(
        _ content: String,
        conversationHistory: [Message],
        model: String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard let apiKey = try keychainService.retrieve(key: "claude_api_key"),
                          !apiKey.isEmpty else {
                        continuation.finish(throwing: AIServiceError.invalidAPIKey)
                        return
                    }

                    let request = try buildRequest(
                        content: content,
                        conversationHistory: conversationHistory,
                        model: model,
                        apiKey: apiKey
                    )

                    let parser = SSEStreamParser()

                    let (bytes, response) = try await session.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: AIServiceError.networkError(
                            underlying: URLError(.badServerResponse)
                        ))
                        return
                    }

                    guard (200...299).contains(httpResponse.statusCode) else {
                        // Attempt to read the error body
                        var errorBody = ""
                        for try await line in bytes.lines {
                            errorBody.append(line)
                            if errorBody.count > 2000 { break }
                        }
                        continuation.finish(throwing: AIServiceError.serverError(
                            statusCode: httpResponse.statusCode,
                            message: errorBody.isEmpty ? "Unknown server error" : errorBody
                        ))
                        return
                    }

                    // Stream SSE bytes line by line
                    for try await line in bytes.lines {
                        if Task.isCancelled {
                            continuation.finish(throwing: AIServiceError.cancelled)
                            return
                        }

                        // URLSession.bytes.lines strips the newline; we need to re-add
                        // the double-newline delimiter for SSE parsing
                        let events = parser.parse(line + "\n\n")

                        for event in events {
                            // Check for API-level errors
                            if let errorMessage = parser.extractError(from: event) {
                                continuation.finish(throwing: AIServiceError.streamingError(errorMessage))
                                return
                            }

                            // Extract text deltas
                            if let text = parser.extractTextDelta(from: event) {
                                continuation.yield(text)
                            }

                            // End of stream
                            if parser.isMessageStop(event) {
                                continuation.finish()
                                return
                            }
                        }
                    }

                    // Stream ended naturally (server closed connection)
                    continuation.finish()

                } catch is CancellationError {
                    continuation.finish(throwing: AIServiceError.cancelled)
                } catch let error as AIServiceError {
                    continuation.finish(throwing: error)
                } catch {
                    continuation.finish(throwing: AIServiceError.networkError(underlying: error))
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
    }

    // MARK: - Private

    private func buildRequest(
        content: String,
        conversationHistory: [Message],
        model: String,
        apiKey: String
    ) throws -> URLRequest {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        // Build messages array from conversation history + current message
        var apiMessages: [[String: String]] = []

        for message in conversationHistory {
            switch message.role {
            case .user:
                apiMessages.append(["role": "user", "content": message.content])
            case .assistant:
                apiMessages.append(["role": "assistant", "content": message.content])
            case .system:
                // System messages are handled separately in the Claude API
                break
            }
        }

        // Append the current user message
        apiMessages.append(["role": "user", "content": content])

        // Extract system message if present
        let systemMessage = conversationHistory
            .first(where: { $0.role == .system })?
            .content

        var body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "messages": apiMessages,
            "stream": true
        ]

        if let systemMessage {
            body["system"] = systemMessage
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
}
