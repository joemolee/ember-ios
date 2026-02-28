import Foundation
import Observation

// MARK: - InboxViewModel

/// Presentation logic for the inbox screen. Handles filtering, sorting, refresh,
/// and mark-as-read by delegating to `AppState`.
@Observable
@MainActor
final class InboxViewModel {

    // MARK: - State

    var selectedPlatform: MessagePlatform?
    var selectedMessage: InboxMessage?
    var isRefreshing: Bool = false

    // MARK: - Dependencies

    private let appState: AppState

    // MARK: - Init

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Computed

    /// Messages filtered by the selected platform and user's urgency threshold,
    /// already sorted by urgency then timestamp from AppState.
    var filteredMessages: [InboxMessage] {
        appState.inboxMessages.filter { message in
            // Platform filter.
            if let platform = selectedPlatform, message.platform != platform {
                return false
            }
            // Source filter from settings.
            if !appState.settings.inboxSources.contains(message.platform) {
                return false
            }
            // Urgency threshold filter.
            if message.triage.urgency > appState.settings.inboxUrgencyThreshold {
                return false
            }
            return true
        }
    }

    /// Messages grouped by urgency for section display.
    var groupedMessages: [(urgency: UrgencyLevel, messages: [InboxMessage])] {
        let grouped = Dictionary(grouping: filteredMessages) { $0.triage.urgency }
        return UrgencyLevel.allCases.compactMap { level in
            guard let messages = grouped[level], !messages.isEmpty else { return nil }
            return (urgency: level, messages: messages)
        }
    }

    var isInboxEnabled: Bool {
        appState.settings.inboxEnabled && appState.settings.selectedProvider == .openClaw
    }

    var unreadCount: Int {
        appState.unreadUrgentCount
    }

    // MARK: - Actions

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            try await appState.inboxService?.requestRefresh()
        } catch {
            // Swallow — the user sees the current cached messages.
        }
    }

    func markAsRead(_ message: InboxMessage) {
        appState.markInboxMessageRead(message)
    }

    func selectMessage(_ message: InboxMessage) {
        selectedMessage = message
        if !message.isRead {
            markAsRead(message)
        }
    }
}
