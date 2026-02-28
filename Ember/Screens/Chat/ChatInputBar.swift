import SwiftUI

// MARK: - ChatInputBar

/// The input area at the bottom of the chat screen.
/// Contains a multi-line text field, a voice recording button, and a send button.
struct ChatInputBar: View {

    // MARK: - Properties

    @Binding var text: String
    let onSend: () -> Void
    let onVoiceToggle: () -> Void
    let isStreaming: Bool
    let isRecording: Bool

    // MARK: - State

    @FocusState private var isFocused: Bool
    @State private var sendButtonGlow: Bool = false

    // MARK: - Derived

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isStreaming
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Top border line
            Rectangle()
                .fill(Color.ember.textSecondary.opacity(0.2))
                .frame(height: 0.5)

            HStack(alignment: .bottom, spacing: EmberTheme.Spacing.sm) {
                // Voice button
                voiceButton

                // Text input
                textInput

                // Send button
                sendButton
            }
            .padding(.horizontal, EmberTheme.Spacing.md)
            .padding(.vertical, EmberTheme.Spacing.sm + 2)
        }
        .background(Color.ember.surface)
        .onChange(of: canSend) { _, ready in
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                sendButtonGlow = ready
            }
            if !ready {
                sendButtonGlow = false
            }
        }
    }

    // MARK: - Voice Button

    private var voiceButton: some View {
        Button {
            onVoiceToggle()
        } label: {
            ZStack {
                Image(systemName: isRecording ? "mic.fill" : "mic")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isRecording ? Color.ember.primary : Color.ember.textSecondary)
                    .frame(width: 36, height: 36)

                if isRecording {
                    PulsingDot(isActive: .constant(true), color: Color.ember.primary)
                        .scaleEffect(0.5)
                        .offset(x: 14, y: -14)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRecording ? "Stop recording" : "Start voice input")
    }

    // MARK: - Text Input

    private var textInput: some View {
        TextField("Message Ember...", text: $text, axis: .vertical)
            .font(EmberTheme.Typography.body)
            .foregroundStyle(Color.ember.textPrimary)
            .tint(Color.ember.primary)
            .lineLimit(1...5)
            .focused($isFocused)
            .padding(.horizontal, EmberTheme.Spacing.sm + 4)
            .padding(.vertical, EmberTheme.Spacing.sm)
            .background(Color.ember.background)
            .clipShape(RoundedRectangle(cornerRadius: EmberTheme.Radii.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: EmberTheme.Radii.large, style: .continuous)
                    .stroke(
                        isFocused ? Color.ember.primary.opacity(0.4) : Color.ember.textSecondary.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .onSubmit {
                if canSend {
                    onSend()
                }
            }
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button {
            onSend()
        } label: {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(canSend ? Color.ember.primary : Color.ember.textSecondary.opacity(0.4))
                .shadow(
                    color: sendButtonGlow && canSend ? Color.ember.glow.opacity(0.6) : .clear,
                    radius: sendButtonGlow && canSend ? 8 : 0,
                    x: 0,
                    y: 0
                )
        }
        .buttonStyle(.plain)
        .disabled(!canSend)
        .animation(.emberSubtle, value: canSend)
        .accessibilityLabel("Send message")
    }
}

// MARK: - Preview

#Preview("ChatInputBar") {
    @Previewable @State var text: String = ""
    @Previewable @State var textWithContent: String = "Hello, how are you?"

    VStack {
        Spacer()

        // Empty state
        ChatInputBar(
            text: $text,
            onSend: {},
            onVoiceToggle: {},
            isStreaming: false,
            isRecording: false
        )

        // With content — send enabled
        ChatInputBar(
            text: $textWithContent,
            onSend: {},
            onVoiceToggle: {},
            isStreaming: false,
            isRecording: false
        )

        // Recording state
        ChatInputBar(
            text: $text,
            onSend: {},
            onVoiceToggle: {},
            isStreaming: false,
            isRecording: true
        )

        // Streaming state — send disabled
        ChatInputBar(
            text: $textWithContent,
            onSend: {},
            onVoiceToggle: {},
            isStreaming: true,
            isRecording: false
        )
    }
    .background(Color.ember.background)
}
