import SwiftUI
import MarkdownUI

// MARK: - MessageBubbleView

/// Renders a single chat message with different layouts for user vs assistant.
/// User messages appear right-aligned in an orange pill. Assistant messages
/// appear left-aligned with no bubble, rendered as Markdown.
struct MessageBubbleView: View {

    let message: Message

    // MARK: - Body

    var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: EmberTheme.Spacing.xs) {
            bubbleContent
            timestampLabel
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
    }

    // MARK: - Bubble Content

    @ViewBuilder
    private var bubbleContent: some View {
        switch message.role {
        case .user:
            userBubble
        case .assistant:
            assistantContent
        case .system:
            EmptyView()
        }
    }

    // MARK: - User Bubble

    private var userBubble: some View {
        Text(message.content)
            .font(EmberTheme.Typography.body)
            .foregroundStyle(.white)
            .padding(.horizontal, EmberTheme.Spacing.md)
            .padding(.vertical, EmberTheme.Spacing.sm + 2)
            .background(Color.ember.userBubble)
            .clipShape(RoundedRectangle(cornerRadius: EmberTheme.Radii.large + 4, style: .continuous))
            .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: .trailing)
    }

    // MARK: - Assistant Content

    private var assistantContent: some View {
        Group {
            if message.isStreaming {
                StreamingTextView(text: message.content, isStreaming: true)
            } else {
                Markdown(message.content)
                    .markdownTextStyle {
                        FontFamily(.system(.rounded))
                        FontSize(16)
                        ForegroundColor(Color.ember.textPrimary)
                    }
                    .markdownBlockStyle(\.codeBlock) { configuration in
                        configuration.label
                            .padding(EmberTheme.Spacing.sm)
                            .background(Color.ember.surface)
                            .clipShape(RoundedRectangle(cornerRadius: EmberTheme.Radii.small, style: .continuous))
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Timestamp

    private var timestampLabel: some View {
        Text(message.timestamp, style: .time)
            .font(EmberTheme.Typography.caption)
            .foregroundStyle(Color.ember.textSecondary)
    }
}

// MARK: - Preview

#Preview("MessageBubbleView") {
    VStack(spacing: EmberTheme.Spacing.md) {
        MessageBubbleView(
            message: Message(
                role: .user,
                content: "Hello! Can you explain how async/await works in Swift?"
            )
        )

        MessageBubbleView(
            message: Message(
                role: .assistant,
                content: """
                Sure! **async/await** is Swift's modern concurrency model. Here's the key idea:

                1. Mark functions with `async` to indicate they perform asynchronous work
                2. Use `await` to call those functions and suspend execution until the result is ready

                ```swift
                func fetchData() async throws -> Data {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    return data
                }
                ```

                The compiler ensures you handle suspension points correctly!
                """
            )
        )

        MessageBubbleView(
            message: Message(
                role: .user,
                content: "Thanks!"
            )
        )
    }
    .padding(EmberTheme.Spacing.md)
    .background(Color.ember.background)
}
