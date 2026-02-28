import Foundation
import Observation

// MARK: - AppState

/// Root application state that owns all services and shared data.
/// Acts as the single source of truth, loaded at app launch and persisted on changes.
@Observable
@MainActor
final class AppState {

    // MARK: - Data

    /// All saved conversations, sorted by most recently updated.
    var conversations: [Conversation] = []

    /// The conversation currently being viewed in the chat screen, if any.
    var activeConversation: Conversation?

    /// User preferences including provider selection, model, haptics, etc.
    var settings: UserSettings

    /// Typed navigation router driving the NavigationStack.
    var router: AppRouter

    // MARK: - Inbox Data

    /// All triaged inbox messages from the Gateway, sorted by urgency then timestamp.
    var inboxMessages: [InboxMessage] = []

    /// Count of unread urgent/important messages for the toolbar badge.
    var unreadUrgentCount: Int {
        inboxMessages.filter { !$0.isRead && $0.triage.urgency <= .important }.count
    }

    // MARK: - Owned Services

    /// The active AI service, resolved from `settings.selectedProvider`.
    private(set) var aiService: any AIServiceProtocol

    /// Haptic feedback service, kept in sync with `settings.hapticFeedbackEnabled`.
    let hapticService: HapticService

    /// On-device speech recognition service.
    let speechService: AppleSpeechService

    /// File-based persistence for conversations and UserDefaults-based for settings.
    let persistence: PersistenceService

    /// Inbox WebSocket service (separate from AI service).
    private(set) var inboxService: (any InboxServiceProtocol)?

    /// Local file-based cache for inbox messages.
    private let inboxStore = InboxMessageStore()

    // MARK: - Private

    /// Tracks the last-resolved provider so we only rebuild the service when it changes.
    private var lastResolvedProvider: AIProvider

    /// The background task that listens for inbox events.
    private var inboxSubscriptionTask: Task<Void, Never>?

    // MARK: - Init

    init(
        persistence: PersistenceService = .shared,
        keychainService: KeychainService = .shared
    ) {
        self.persistence = persistence

        // Load settings from disk (or fresh defaults on first launch).
        let loadedSettings = persistence.loadSettings()
        self.settings = loadedSettings

        // Initialise router.
        self.router = AppRouter()

        // Initialise services.
        self.hapticService = HapticService()
        self.speechService = AppleSpeechService()

        // Resolve the initial AI service based on the persisted provider.
        self.lastResolvedProvider = loadedSettings.selectedProvider
        switch loadedSettings.selectedProvider {
        case .claude:
            self.aiService = ClaudeService(keychainService: keychainService)
        case .openClaw:
            self.aiService = OpenClawService(gatewayURL: loadedSettings.gatewayURL)
        }

        // Sync haptic service to the persisted preference.
        self.hapticService.isEnabled = loadedSettings.hapticFeedbackEnabled

        // Load conversations from disk.
        do {
            self.conversations = try persistence.loadConversations()
        } catch {
            self.conversations = []
        }
    }

    // MARK: - Conversation Management

    /// Creates a new empty conversation, inserts it at the front of the list,
    /// persists it, and returns it.
    @discardableResult
    func createNewConversation() -> Conversation {
        let conversation = Conversation()
        conversations.insert(conversation, at: 0)

        // Persist immediately so it survives a crash.
        try? persistence.saveConversation(conversation)

        return conversation
    }

    /// Deletes a conversation by its ID from memory and disk.
    func deleteConversation(id: UUID) {
        conversations.removeAll { $0.id == id }

        if activeConversation?.id == id {
            activeConversation = nil
        }

        try? persistence.deleteConversation(id: id)
    }

    /// Persists the current conversations list and settings to disk.
    /// Call this on significant state changes and when the app backgrounds.
    func saveCurrentState() {
        // Save every conversation.
        for conversation in conversations {
            try? persistence.saveConversation(conversation)
        }

        // Save settings.
        persistence.saveSettings(settings)
    }

    // MARK: - Provider Resolution

    /// Switches the active AI service when `settings.selectedProvider` changes.
    /// Safe to call repeatedly -- it only rebuilds if the provider actually changed.
    func resolveAIService() {
        guard settings.selectedProvider != lastResolvedProvider else { return }

        lastResolvedProvider = settings.selectedProvider

        switch settings.selectedProvider {
        case .claude:
            aiService = ClaudeService()
        case .openClaw:
            aiService = OpenClawService(gatewayURL: settings.gatewayURL)
        }
    }

    // MARK: - Settings Sync

    /// Call after any settings mutation to keep services in sync and persist.
    func syncSettings() {
        // Keep haptic service in sync.
        hapticService.isEnabled = settings.hapticFeedbackEnabled

        // Re-resolve AI service if provider changed.
        resolveAIService()

        // If the gateway URL changed while OpenClaw is selected, rebuild the service.
        if settings.selectedProvider == .openClaw,
           let openClaw = aiService as? OpenClawService,
           openClaw.configuredURL != settings.gatewayURL {
            aiService = OpenClawService(gatewayURL: settings.gatewayURL)
        }

        // Persist settings.
        persistence.saveSettings(settings)
    }

    // MARK: - Conversation Updates

    /// Updates a conversation in the conversations array after it has been mutated
    /// (e.g. new messages appended). Call this from the chat screen when streaming
    /// finishes or the user navigates away.
    func updateConversation(_ conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        } else {
            conversations.insert(conversation, at: 0)
        }
        try? persistence.saveConversation(conversation)
    }

    // MARK: - Inbox Lifecycle

    /// Starts the inbox service if the user has enabled it and the provider is OpenClaw.
    /// Safe to call repeatedly — it tears down any existing subscription first.
    func startInboxIfNeeded() {
        guard settings.inboxEnabled,
              settings.selectedProvider == .openClaw else {
            stopInbox()
            return
        }

        // Rebuild the service if the URL changed or it doesn't exist yet.
        if let existing = inboxService as? InboxService,
           existing.configuredURL == settings.gatewayURL {
            // Already connected to the right URL — no-op.
        } else {
            stopInbox()
            inboxService = InboxService(gatewayURL: settings.gatewayURL)
        }

        // Load cached messages while we wait for the live stream.
        Task {
            let cached = await inboxStore.load()
            if inboxMessages.isEmpty && !cached.isEmpty {
                inboxMessages = cached
            }
        }

        guard inboxSubscriptionTask == nil, let service = inboxService else { return }

        inboxSubscriptionTask = Task { [weak self] in
            do {
                for try await event in service.subscribe() {
                    guard let self, !Task.isCancelled else { return }
                    await MainActor.run {
                        self.handleInboxEvent(event)
                    }
                }
            } catch {
                // Stream ended (disconnect, cancel, or error). Handled via .disconnected event.
            }
        }

        // Send current config to gateway.
        Task {
            try? await service.sendConfig(
                vips: settings.inboxVIPs,
                topics: settings.inboxPriorityTopics
            )
        }
    }

    /// Stops the inbox service and cancels the subscription.
    func stopInbox() {
        inboxSubscriptionTask?.cancel()
        inboxSubscriptionTask = nil
        inboxService?.unsubscribe()
        inboxService = nil
    }

    /// Processes an incoming `InboxEvent` from the service.
    func handleInboxEvent(_ event: InboxEvent) {
        switch event {
        case .messages(let messages):
            // Replace all messages with the fresh batch, deduplicating by originalMessageID.
            var seen = Set<String>()
            var deduped: [InboxMessage] = []
            for message in messages {
                if seen.insert(message.originalMessageID).inserted {
                    deduped.append(message)
                }
            }
            inboxMessages = deduped.sorted {
                if $0.triage.urgency != $1.triage.urgency {
                    return $0.triage.urgency < $1.triage.urgency
                }
                return $0.timestamp > $1.timestamp
            }
            Task { await inboxStore.save(inboxMessages) }

        case .update(let message):
            if let index = inboxMessages.firstIndex(where: { $0.originalMessageID == message.originalMessageID }) {
                inboxMessages[index] = message
            } else {
                // Insert at the correct position (urgency then timestamp).
                inboxMessages.append(message)
                inboxMessages.sort {
                    if $0.triage.urgency != $1.triage.urgency {
                        return $0.triage.urgency < $1.triage.urgency
                    }
                    return $0.timestamp > $1.timestamp
                }
            }
            Task { await inboxStore.save(inboxMessages) }

        case .readConfirmed(let messageID):
            if let index = inboxMessages.firstIndex(where: { $0.originalMessageID == messageID }) {
                inboxMessages[index].isRead = true
            }
            Task { await inboxStore.save(inboxMessages) }

        case .connected, .disconnected:
            break
        }
    }

    /// Marks a message as read locally and notifies the gateway.
    func markInboxMessageRead(_ message: InboxMessage) {
        if let index = inboxMessages.firstIndex(where: { $0.id == message.id }) {
            inboxMessages[index].isRead = true
        }
        Task { await inboxStore.save(inboxMessages) }
        Task { try? await inboxService?.markAsRead(messageID: message.originalMessageID) }
    }
}
