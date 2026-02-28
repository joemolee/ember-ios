import SwiftUI

// MARK: - InboxMessageDetailSheet

/// Expanded view showing the full message content and AI triage reasoning.
struct InboxMessageDetailSheet: View {

    let message: InboxMessage
    let onMarkAsRead: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: EmberTheme.Spacing.lg) {
                    // Header: platform icon + sender + timestamp
                    headerSection

                    Divider()
                        .background(Color.ember.textSecondary.opacity(0.2))

                    // Full message content
                    contentSection

                    Divider()
                        .background(Color.ember.textSecondary.opacity(0.2))

                    // AI triage reasoning
                    triageSection

                    // Mark as read button
                    if !message.isRead {
                        markAsReadButton
                    }
                }
                .padding(EmberTheme.Spacing.md)
            }
            .background(Color.ember.background)
            .scrollContentBackground(.hidden)
            .navigationTitle("Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ember.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.ember.primary)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top, spacing: EmberTheme.Spacing.sm) {
            PlatformIcon(platform: message.platform, size: 44)

            VStack(alignment: .leading, spacing: EmberTheme.Spacing.xs) {
                Text(message.senderName)
                    .font(EmberTheme.Typography.headline)
                    .foregroundStyle(Color.ember.textPrimary)

                Text(message.senderIdentifier)
                    .font(EmberTheme.Typography.caption)
                    .foregroundStyle(Color.ember.textSecondary)

                if !message.conversationContext.isEmpty {
                    Text(message.conversationContext)
                        .font(EmberTheme.Typography.caption)
                        .foregroundStyle(Color.ember.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: EmberTheme.Spacing.xs) {
                UrgencyBadge(urgency: message.triage.urgency)
                Text(message.timestamp.chatTimestamp)
                    .font(EmberTheme.Typography.caption)
                    .foregroundStyle(Color.ember.textSecondary)
            }
        }
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
            Text("Message")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.ember.textSecondary)

            Text(message.content)
                .font(EmberTheme.Typography.body)
                .foregroundStyle(Color.ember.textPrimary)
        }
    }

    // MARK: - Triage

    private var triageSection: some View {
        VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
            HStack(spacing: EmberTheme.Spacing.xs) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.ember.primary)

                Text("AI Triage")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.ember.textSecondary)
            }

            Text(message.triage.reasoning)
                .font(EmberTheme.Typography.body)
                .foregroundStyle(Color.ember.textPrimary.opacity(0.9))
                .padding(EmberTheme.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.ember.surface)
                .clipShape(RoundedRectangle(cornerRadius: EmberTheme.Radii.medium, style: .continuous))
        }
    }

    // MARK: - Mark as Read

    private var markAsReadButton: some View {
        Button {
            onMarkAsRead()
            dismiss()
        } label: {
            HStack(spacing: EmberTheme.Spacing.sm) {
                Image(systemName: "checkmark.circle")
                Text("Mark as Read")
            }
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.ember.primary)
            .clipShape(RoundedRectangle(cornerRadius: EmberTheme.Radii.medium, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("InboxMessageDetailSheet") {
    InboxMessageDetailSheet(
        message: MockInboxService.sampleMessages[0],
        onMarkAsRead: {}
    )
}
