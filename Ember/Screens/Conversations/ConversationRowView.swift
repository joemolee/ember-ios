import SwiftUI

// MARK: - ConversationRowView

/// A single conversation row displaying title, message preview, relative timestamp,
/// an optional accent bar for the most recent conversation, and a trailing chevron.
struct ConversationRowView: View {

    // MARK: - Properties

    let conversation: Conversation
    var isMostRecent: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: EmberTheme.Spacing.sm) {
            // Left accent bar for the most recent conversation
            accentBar

            // Content
            VStack(alignment: .leading, spacing: EmberTheme.Spacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(conversation.title)
                        .font(EmberTheme.Typography.headline)
                        .foregroundStyle(Color.ember.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Text(conversation.updatedAt.timeAgo)
                        .font(EmberTheme.Typography.caption)
                        .foregroundStyle(Color.ember.textSecondary)
                }

                HStack {
                    Text(conversation.preview)
                        .font(EmberTheme.Typography.body)
                        .foregroundStyle(Color.ember.textSecondary)
                        .lineLimit(2)

                    Spacer(minLength: EmberTheme.Spacing.sm)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.ember.textSecondary.opacity(0.5))
                }
            }
        }
        .padding(.vertical, EmberTheme.Spacing.sm)
        .contentShape(Rectangle())
    }

    // MARK: - Accent Bar

    @ViewBuilder
    private var accentBar: some View {
        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
            .fill(isMostRecent ? Color.ember.primary : Color.clear)
            .frame(width: 3)
            .frame(maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("ConversationRowView") {
    let sampleConversations = [
        Conversation(
            title: "Swift Concurrency",
            messages: [
                Message(role: .user, content: "Explain async/await in Swift"),
                Message(role: .assistant, content: "Swift concurrency is built around three core concepts: async/await, actors, and structured concurrency.")
            ],
            updatedAt: Date()
        ),
        Conversation(
            title: "Recipe Ideas",
            messages: [
                Message(role: .user, content: "What can I make with chicken and rice?"),
                Message(role: .assistant, content: "Here are some great chicken and rice recipes you might enjoy...")
            ],
            updatedAt: Date().addingTimeInterval(-3600)
        ),
        Conversation(
            title: "Empty Chat",
            messages: [],
            updatedAt: Date().addingTimeInterval(-86400)
        ),
    ]

    VStack(spacing: 0) {
        ForEach(Array(sampleConversations.enumerated()), id: \.element.id) { index, conversation in
            ConversationRowView(
                conversation: conversation,
                isMostRecent: index == 0
            )
            .padding(.horizontal, EmberTheme.Spacing.md)

            if index < sampleConversations.count - 1 {
                Divider()
                    .padding(.leading, EmberTheme.Spacing.xl)
            }
        }
    }
    .background(Color.ember.background)
}
