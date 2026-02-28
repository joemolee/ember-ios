import SwiftUI

// MARK: - InboxScreen

/// Root inbox screen: filter bar, grouped message list, pull-to-refresh, and detail sheet.
struct InboxScreen: View {

    // MARK: - State

    @State private var viewModel: InboxViewModel

    // MARK: - Init

    init(appState: AppState) {
        _viewModel = State(initialValue: InboxViewModel(appState: appState))
    }

    // MARK: - Body

    var body: some View {
        Group {
            if !viewModel.isInboxEnabled {
                InboxEmptyStateView(reason: .disabled)
            } else if viewModel.filteredMessages.isEmpty && viewModel.selectedPlatform == nil {
                InboxEmptyStateView(reason: .noMessages)
            } else if viewModel.filteredMessages.isEmpty {
                VStack(spacing: 0) {
                    InboxFilterBar(selectedPlatform: $viewModel.selectedPlatform)
                        .padding(.vertical, EmberTheme.Spacing.sm)
                    InboxEmptyStateView(reason: .noMatchingFilter)
                }
            } else {
                messageListView
            }
        }
        .background(Color.ember.background)
        .navigationTitle("Inbox")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.ember.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(item: $viewModel.selectedMessage) { message in
            InboxMessageDetailSheet(message: message) {
                viewModel.markAsRead(message)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Message List

    private var messageListView: some View {
        ScrollView {
            VStack(spacing: 0) {
                InboxFilterBar(selectedPlatform: $viewModel.selectedPlatform)
                    .padding(.vertical, EmberTheme.Spacing.sm)

                LazyVStack(spacing: EmberTheme.Spacing.sm, pinnedViews: [.sectionHeaders]) {
                    ForEach(viewModel.groupedMessages, id: \.urgency) { group in
                        Section {
                            ForEach(group.messages) { message in
                                InboxMessageCard(message: message) {
                                    viewModel.selectMessage(message)
                                }
                                .padding(.horizontal, EmberTheme.Spacing.md)
                            }
                        } header: {
                            sectionHeader(for: group.urgency)
                        }
                    }
                }
                .padding(.bottom, EmberTheme.Spacing.lg)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Section Header

    private func sectionHeader(for urgency: UrgencyLevel) -> some View {
        HStack {
            Text(urgency.displayName.uppercased())
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.ember.textSecondary)

            Spacer()
        }
        .padding(.horizontal, EmberTheme.Spacing.md)
        .padding(.vertical, EmberTheme.Spacing.xs)
        .background(Color.ember.background.opacity(0.95))
    }
}

// MARK: - Preview

#Preview("InboxScreen — With Messages") {
    @Previewable @State var appState: AppState = {
        let state = AppState()
        state.settings.selectedProvider = .openClaw
        state.settings.inboxEnabled = true
        state.inboxMessages = [
            InboxMessage(
                platform: .iMessage,
                senderName: "Lindsay",
                senderIdentifier: "+15551234567",
                content: "Hey, can you review the Q3 budget deck before the 3pm meeting?",
                conversationContext: "Direct Message",
                triage: TriageResult(urgency: .urgent, reasoning: "From your manager"),
                originalMessageID: "imsg-001"
            ),
            InboxMessage(
                platform: .slack,
                senderName: "Daniel Henderson",
                senderIdentifier: "U12345",
                content: "The staging deploy is blocked on a failing integration test.",
                conversationContext: "#engineering",
                triage: TriageResult(urgency: .important, reasoning: "Deployment blocked"),
                originalMessageID: "slack-001"
            ),
        ]
        return state
    }()

    NavigationStack {
        InboxScreen(appState: appState)
    }
    .environment(appState)
    .preferredColorScheme(.dark)
}

#Preview("InboxScreen — Empty") {
    @Previewable @State var appState: AppState = {
        let state = AppState()
        state.settings.selectedProvider = .openClaw
        state.settings.inboxEnabled = true
        return state
    }()

    NavigationStack {
        InboxScreen(appState: appState)
    }
    .environment(appState)
    .preferredColorScheme(.dark)
}

#Preview("InboxScreen — Disabled") {
    @Previewable @State var appState = AppState()

    NavigationStack {
        InboxScreen(appState: appState)
    }
    .environment(appState)
    .preferredColorScheme(.dark)
}
