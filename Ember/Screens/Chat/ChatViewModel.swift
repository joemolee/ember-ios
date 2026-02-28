import Foundation

@Observable
@MainActor
final class ChatViewModel {

    // MARK: - Published State

    var conversation: Conversation
    var inputText: String = ""
    var isStreaming: Bool = false
    var error: String?

    // MARK: - Dependencies

    private let aiService: any AIServiceProtocol
    private let hapticService: HapticService
    private let model: String

    // MARK: - Private

    private var streamingTask: Task<Void, Never>?

    // MARK: - Init

    init(
        conversation: Conversation = Conversation(),
        aiService: any AIServiceProtocol,
        hapticService: HapticService = HapticService(),
        model: String = "claude-sonnet-4-20250514"
    ) {
        self.conversation = conversation
        self.aiService = aiService
        self.hapticService = hapticService
        self.model = model
    }

    // MARK: - Actions

    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isStreaming else { return }

        // Create and append the user message
        let userMessage = Message(role: .user, content: trimmed)
        conversation.messages.append(userMessage)
        conversation.updatedAt = Date()

        // Auto-generate title from first user message
        if conversation.title == "New Conversation" {
            let titleSource = trimmed.prefix(40)
            conversation.title = titleSource.count < trimmed.count
                ? String(titleSource) + "..."
                : String(titleSource)
        }

        // Clear input immediately
        inputText = ""

        // Haptic on send
        hapticService.onSend()

        // Create a placeholder assistant message for streaming
        let assistantMessage = Message(role: .assistant, content: "", isStreaming: true)
        conversation.messages.append(assistantMessage)
        let assistantIndex = conversation.messages.count - 1

        isStreaming = true
        error = nil

        // Build conversation history (exclude the placeholder assistant message)
        let history = Array(conversation.messages.dropLast())

        streamingTask = Task { [weak self] in
            guard let self else { return }

            do {
                let stream = aiService.sendMessage(
                    trimmed,
                    conversationHistory: Array(history.dropLast()),
                    model: model
                )

                for try await token in stream {
                    guard !Task.isCancelled else { break }
                    self.conversation.messages[assistantIndex].content += token
                    self.conversation.updatedAt = Date()
                }

                // Mark streaming complete
                self.conversation.messages[assistantIndex].isStreaming = false
                self.isStreaming = false
                self.hapticService.onResponseComplete()

            } catch is CancellationError {
                self.conversation.messages[assistantIndex].isStreaming = false
                self.isStreaming = false
            } catch let aiError as AIServiceError where aiError.errorDescription != nil {
                self.conversation.messages[assistantIndex].isStreaming = false
                self.isStreaming = false
                if case .cancelled = aiError {
                    // Cancellation is not an error to display
                } else {
                    self.error = aiError.errorDescription
                    self.hapticService.onError()
                }
            } catch {
                self.conversation.messages[assistantIndex].isStreaming = false
                self.isStreaming = false
                self.error = error.localizedDescription
                self.hapticService.onError()
            }

            // Remove the assistant message if it ended up empty (e.g., immediate error)
            if self.conversation.messages[assistantIndex].content.isEmpty {
                self.conversation.messages.remove(at: assistantIndex)
            }
        }
    }

    func cancelStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        aiService.cancelCurrentRequest()
        isStreaming = false
    }

    func clearError() {
        error = nil
    }
}
