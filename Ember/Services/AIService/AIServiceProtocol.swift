import Foundation

protocol AIServiceProtocol: Sendable {
    func sendMessage(
        _ content: String,
        conversationHistory: [Message],
        model: String
    ) -> AsyncThrowingStream<String, Error>

    func cancelCurrentRequest()

    var isAvailable: Bool { get }
    var providerName: String { get }
}

enum AIServiceError: LocalizedError {
    case invalidAPIKey
    case networkError(underlying: Error)
    case serverError(statusCode: Int, message: String)
    case streamingError(String)
    case cancelled
    case invalidConfiguration(String)

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid or missing API key. Please check your API key in Settings."
        case .networkError(let underlying):
            return "Network error: \(underlying.localizedDescription). Please check your internet connection."
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message)"
        case .streamingError(let detail):
            return "Streaming error: \(detail)"
        case .cancelled:
            return "Request was cancelled."
        case .invalidConfiguration(let detail):
            return "Invalid configuration: \(detail)"
        }
    }
}
