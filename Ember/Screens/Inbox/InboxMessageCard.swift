import SwiftUI

// MARK: - InboxMessageCard

/// A card displaying a triaged message with platform icon, sender, preview,
/// timestamp, and urgency badge.
struct InboxMessageCard: View {

    let message: InboxMessage
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: EmberTheme.Spacing.sm) {
                PlatformIcon(platform: message.platform)

                VStack(alignment: .leading, spacing: EmberTheme.Spacing.xs) {
                    // Top row: sender + timestamp
                    HStack {
                        Text(message.senderName)
                            .font(.system(size: 15, weight: message.isRead ? .regular : .semibold, design: .rounded))
                            .foregroundStyle(Color.ember.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text(message.timestamp.timeAgo)
                            .font(EmberTheme.Typography.caption)
                            .foregroundStyle(Color.ember.textSecondary)
                    }

                    // Context line (channel/conversation)
                    if !message.conversationContext.isEmpty {
                        Text(message.conversationContext)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.ember.textSecondary)
                            .lineLimit(1)
                    }

                    // Message preview
                    Text(message.preview)
                        .font(EmberTheme.Typography.caption)
                        .foregroundStyle(Color.ember.textPrimary.opacity(0.8))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Bottom row: urgency badge + unread indicator
                    HStack {
                        UrgencyBadge(urgency: message.triage.urgency)

                        Spacer()

                        if !message.isRead {
                            Circle()
                                .fill(Color.ember.primary)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
            .padding(EmberTheme.Spacing.md)
            .background(Color.ember.surface)
            .clipShape(RoundedRectangle(cornerRadius: EmberTheme.Radii.large, style: .continuous))
            .shadow(
                color: EmberTheme.Shadow.card.color,
                radius: EmberTheme.Shadow.card.radius,
                x: EmberTheme.Shadow.card.x,
                y: EmberTheme.Shadow.card.y
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("InboxMessageCard") {
    let sample = MockInboxService.sampleMessages

    ScrollView {
        VStack(spacing: EmberTheme.Spacing.sm) {
            ForEach(sample) { message in
                InboxMessageCard(message: message) {}
            }
        }
        .padding(EmberTheme.Spacing.md)
    }
    .background(Color.ember.background)
}
