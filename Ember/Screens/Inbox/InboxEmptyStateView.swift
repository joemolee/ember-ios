import SwiftUI

// MARK: - InboxEmptyStateView

/// Shown when inbox is disabled or no messages match the current filter.
struct InboxEmptyStateView: View {

    enum Reason {
        case disabled
        case noMessages
        case noMatchingFilter
    }

    let reason: Reason

    var body: some View {
        VStack(spacing: EmberTheme.Spacing.lg) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundStyle(Color.ember.textSecondary.opacity(0.4))

            VStack(spacing: EmberTheme.Spacing.sm) {
                Text(title)
                    .font(EmberTheme.Typography.headline)
                    .foregroundStyle(Color.ember.textPrimary)

                Text(subtitle)
                    .font(EmberTheme.Typography.body)
                    .foregroundStyle(Color.ember.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(EmberTheme.Spacing.xl)
    }

    // MARK: - Content

    private var iconName: String {
        switch reason {
        case .disabled: return "tray.slash"
        case .noMessages: return "tray"
        case .noMatchingFilter: return "line.3.horizontal.decrease.circle"
        }
    }

    private var title: String {
        switch reason {
        case .disabled: return "Inbox Disabled"
        case .noMessages: return "No Messages"
        case .noMatchingFilter: return "No Matches"
        }
    }

    private var subtitle: String {
        switch reason {
        case .disabled:
            return "Enable the unified inbox in Settings to aggregate messages from iMessage, Slack, and Teams."
        case .noMessages:
            return "New triaged messages from your connected platforms will appear here."
        case .noMatchingFilter:
            return "No messages match the current filter. Try selecting a different platform."
        }
    }
}

// MARK: - Preview

#Preview("InboxEmptyStateView — All Reasons") {
    TabView {
        InboxEmptyStateView(reason: .disabled)
            .tabItem { Text("Disabled") }

        InboxEmptyStateView(reason: .noMessages)
            .tabItem { Text("Empty") }

        InboxEmptyStateView(reason: .noMatchingFilter)
            .tabItem { Text("No Match") }
    }
    .background(Color.ember.background)
}
