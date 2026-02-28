import SwiftUI

// MARK: - ChatScreen

/// The main chat screen that composes the message list, input bar, and
/// speech recognition into a full conversation interface.
struct ChatScreen: View {

    // MARK: - State

    @State private var viewModel: ChatViewModel
    @State private var speechService: AppleSpeechService
    @State private var showErrorAlert: Bool = false

    // MARK: - Init

    init(
        aiService: any AIServiceProtocol,
        conversation: Conversation = Conversation(),
        hapticService: HapticService = HapticService()
    ) {
        _viewModel = State(initialValue: ChatViewModel(
            conversation: conversation,
            aiService: aiService,
            hapticService: hapticService
        ))
        _speechService = State(initialValue: AppleSpeechService())
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                MessageListView(
                    messages: viewModel.conversation.messages,
                    isStreaming: viewModel.isStreaming
                )

                // Input bar
                ChatInputBar(
                    text: $viewModel.inputText,
                    onSend: {
                        stopRecordingIfNeeded()
                        viewModel.sendMessage()
                    },
                    onVoiceToggle: {
                        toggleVoiceInput()
                    },
                    isStreaming: viewModel.isStreaming,
                    isRecording: speechService.isListening
                )
            }
            .background(Color.ember.background)
            .navigationTitle(viewModel.conversation.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ember.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isStreaming {
                        Button {
                            viewModel.cancelStreaming()
                        } label: {
                            Image(systemName: "stop.circle")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color.ember.primary)
                        }
                        .accessibilityLabel("Stop generating")
                    }
                }
            }
        }
        .onChange(of: viewModel.error) { _, newError in
            showErrorAlert = newError != nil
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.error {
                Text(errorMessage)
            }
        }
        .onChange(of: speechService.transcript) { _, newTranscript in
            if speechService.isListening && !newTranscript.isEmpty {
                viewModel.inputText = newTranscript
            }
        }
    }

    // MARK: - Voice Input

    private func toggleVoiceInput() {
        if speechService.isListening {
            speechService.stopListening()
        } else {
            Task {
                let authorized = await speechService.requestAuthorization()
                guard authorized else {
                    viewModel.error = "Speech recognition permission is required. Please enable it in Settings."
                    return
                }
                do {
                    speechService.transcript = ""
                    try speechService.startListening()
                } catch {
                    viewModel.error = error.localizedDescription
                }
            }
        }
    }

    private func stopRecordingIfNeeded() {
        if speechService.isListening {
            speechService.stopListening()
        }
    }
}

// MARK: - Preview Mock

/// A lightweight mock AI service for SwiftUI previews.
private final class PreviewAIService: AIServiceProtocol, @unchecked Sendable {
    var isAvailable: Bool { true }
    var providerName: String { "Preview" }

    func sendMessage(
        _ content: String,
        conversationHistory: [Message],
        model: String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let words = "This is a simulated response from the preview AI service. It streams token by token to demonstrate the streaming behavior.".split(separator: " ")
                for word in words {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms per word
                    if Task.isCancelled {
                        continuation.finish()
                        return
                    }
                    continuation.yield(String(word) + " ")
                }
                continuation.finish()
            }
        }
    }

    func cancelCurrentRequest() {}
}

#Preview("ChatScreen") {
    ChatScreen(
        aiService: PreviewAIService(),
        conversation: Conversation(
            title: "Swift Concurrency",
            messages: [
                Message(role: .user, content: "Explain Swift concurrency in simple terms."),
                Message(
                    role: .assistant,
                    content: """
                    Swift concurrency is built around three core concepts:

                    1. **async/await** -- Write asynchronous code that reads like synchronous code
                    2. **Actors** -- Protect mutable state from data races
                    3. **Structured concurrency** -- Task lifetimes are scoped and predictable

                    Think of it like a restaurant: `async` marks a dish that takes time to prepare, `await` is you waiting for your order, and actors are the kitchen staff ensuring only one person uses each station at a time.
                    """
                ),
            ]
        )
    )
}

#Preview("ChatScreen - Empty") {
    ChatScreen(aiService: PreviewAIService())
}
