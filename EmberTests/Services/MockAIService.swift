import Foundation
@testable import Ember

/// A configurable mock implementation of `AIServiceProtocol` for use in unit tests.
///
/// Usage:
/// ```swift
/// let mock = MockAIService()
/// mock.mockResponses = ["Hello", " world", "!"]
/// mock.tokenDelay = 0.0
///
/// let stream = mock.sendMessage("hi", conversationHistory: [], model: "test-model")
/// var collected = ""
/// for try await token in stream { collected += token }
/// // collected == "Hello world!"
/// ```
final class MockAIService: AIServiceProtocol, @unchecked Sendable {

    // MARK: - Configuration

    /// The sequence of string tokens that `sendMessage` will yield, in order.
    /// Defaults to a single "Hello, world!" token.
    var mockResponses: [String] = ["Hello, world!"]

    /// Delay (in seconds) inserted between yielding each token.
    /// Set to 0 for synchronous-style tests; leave at default for timing tests.
    var tokenDelay: TimeInterval = 0.01

    /// When set, `sendMessage` throws this error instead of yielding tokens.
    /// The error is thrown after the first token is requested (stream setup),
    /// which mirrors real-world async behaviour.
    var mockError: Error?

    /// Controls the value returned from the `isAvailable` computed property.
    var mockIsAvailable: Bool = true

    // MARK: - Tracking

    /// Number of times `sendMessage` was called.
    private(set) var sendMessageCallCount: Int = 0

    /// The `messages` array from the most recent `sendMessage` call, or `nil` if never called.
    private(set) var lastMessages: [Message]?

    /// The `model` string from the most recent `sendMessage` call, or `nil` if never called.
    private(set) var lastModel: String?

    /// The `content` string from the most recent `sendMessage` call, or `nil` if never called.
    private(set) var lastContent: String?

    /// Number of times `cancelCurrentRequest()` was called.
    private(set) var cancelCallCount: Int = 0

    // MARK: - AIServiceProtocol

    var isAvailable: Bool { mockIsAvailable }

    var providerName: String { "Mock" }

    func sendMessage(
        _ content: String,
        conversationHistory: [Message],
        model: String
    ) -> AsyncThrowingStream<String, Error> {
        // Capture all configuration values up-front so the closure does not
        // retain `self` while the async stream is alive (avoids retain cycles
        // and reflects how real implementations behave).
        sendMessageCallCount += 1
        lastContent = content
        lastMessages = conversationHistory
        lastModel = model

        let responses = mockResponses
        let delay = tokenDelay
        let error = mockError

        return AsyncThrowingStream { continuation in
            Task {
                // If an error is configured, throw it immediately.
                if let error {
                    continuation.finish(throwing: error)
                    return
                }

                for token in responses {
                    if Task.isCancelled {
                        continuation.finish(throwing: AIServiceError.cancelled)
                        return
                    }

                    if delay > 0 {
                        let nanoseconds = UInt64(delay * 1_000_000_000)
                        try? await Task.sleep(nanoseconds: nanoseconds)
                    }

                    if Task.isCancelled {
                        continuation.finish(throwing: AIServiceError.cancelled)
                        return
                    }

                    continuation.yield(token)
                }

                continuation.finish()
            }
        }
    }

    func cancelCurrentRequest() {
        cancelCallCount += 1
    }

    // MARK: - Helpers

    /// Resets all tracking counters and clears captured arguments.
    /// Does not change `mockResponses`, `tokenDelay`, `mockError`, or `mockIsAvailable`.
    func resetTracking() {
        sendMessageCallCount = 0
        lastMessages = nil
        lastModel = nil
        lastContent = nil
        cancelCallCount = 0
    }
}
