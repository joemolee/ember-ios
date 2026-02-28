import Foundation
import Observation
import UIKit

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

    // MARK: - Memory Data

    /// All memories synced from the Gateway.
    var memories: [Memory] = []

    // MARK: - Briefing Data

    /// All briefings received from the Gateway, sorted newest first.
    var briefings: [Briefing] = []

    /// The most recent briefing, if any.
    var latestBriefing: Briefing? {
        briefings.first
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

    /// Notification service for push and local notifications.
    let notificationService = NotificationService()

    /// Local file-based cache for inbox messages.
    private let inboxStore = InboxMessageStore()

    /// Local file-based cache for memories.
    private let memoryStore = MemoryStore()

    /// Local file-based cache for briefings.
    private let briefingStore = BriefingStore()

    // MARK: - Push State

    /// The APNs device token, if registered.
    var deviceToken: String?

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

        // Load cached memories and briefings.
        Task { [weak self] in
            guard let self else { return }
            let cachedMemories = await memoryStore.load()
            let cachedBriefings = await briefingStore.load()
            await MainActor.run {
                if self.memories.isEmpty && !cachedMemories.isEmpty {
                    self.memories = cachedMemories
                }
                if self.briefings.isEmpty && !cachedBriefings.isEmpty {
                    self.briefings = cachedBriefings.sorted { $0.date > $1.date }
                }
            }
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
                        self.handleGatewayEvent(event)
                    }
                }
            } catch {
                // Stream ended (disconnect, cancel, or error). Handled via .disconnected event.
            }
        }

        // Send current config to gateway after connection.
        Task {
            try? await service.sendConfig(
                vips: settings.inboxVIPs,
                topics: settings.inboxPriorityTopics
            )

            // Request memory sync if enabled.
            if settings.memoryEnabled {
                try? await service.requestMemorySync()
            }

            // Send briefing config if enabled.
            if settings.briefingEnabled {
                try? await service.sendBriefingConfig(
                    enabled: true,
                    time: settings.briefingTime,
                    timezone: settings.briefingTimezone,
                    sources: settings.briefingSources.map(\.rawValue)
                )
            }

            // Send device token if we have one.
            if let token = deviceToken {
                try? await service.sendDeviceToken(token)
            }
        }
    }

    /// Stops the inbox service and cancels the subscription.
    /// Clears memory and briefing state cleanly.
    func stopInbox() {
        inboxSubscriptionTask?.cancel()
        inboxSubscriptionTask = nil
        inboxService?.unsubscribe()
        inboxService = nil
    }

    // MARK: - Gateway Event Handling

    /// Processes an incoming `GatewayEvent` from the service.
    func handleGatewayEvent(_ event: GatewayEvent) {
        switch event {
        // Inbox events
        case .messages(let messages):
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
                inboxMessages.append(message)
                inboxMessages.sort {
                    if $0.triage.urgency != $1.triage.urgency {
                        return $0.triage.urgency < $1.triage.urgency
                    }
                    return $0.timestamp > $1.timestamp
                }
            }
            Task { await inboxStore.save(inboxMessages) }

            // Post local notification for urgent messages when notifications are enabled.
            if settings.notificationsEnabled && message.triage.urgency == .urgent && !message.isRead {
                Task {
                    await notificationService.postUrgentMessageNotification(
                        sender: message.senderName,
                        preview: message.preview,
                        messageID: message.originalMessageID
                    )
                }
            }

        case .readConfirmed(let messageID):
            if let index = inboxMessages.firstIndex(where: { $0.originalMessageID == messageID }) {
                inboxMessages[index].isRead = true
            }
            Task { await inboxStore.save(inboxMessages) }

        // Memory events
        case .memoryList(let memoryList):
            handleMemoryList(memoryList)

        case .memoryCreated(let memory):
            handleMemoryCreated(memory)

        case .memoryUpdated(let memory):
            handleMemoryUpdated(memory)

        case .memoryDeleted(let memoryId):
            handleMemoryDeleted(memoryId)

        // Briefing events
        case .briefing(let briefing):
            handleBriefing(briefing)

        // Push events
        case .deviceTokenConfirmed:
            break

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

    // MARK: - Memory Lifecycle

    /// Handles a full memory list sync from the gateway.
    private func handleMemoryList(_ memoryList: [Memory]) {
        memories = memoryList.sorted { $0.updatedAt > $1.updatedAt }
        Task { await memoryStore.save(memories) }
    }

    /// Handles a newly created memory from the gateway.
    private func handleMemoryCreated(_ memory: Memory) {
        // Insert at the beginning (most recent first).
        memories.insert(memory, at: 0)
        Task { await memoryStore.save(memories) }
    }

    /// Handles an updated memory from the gateway.
    private func handleMemoryUpdated(_ memory: Memory) {
        if let index = memories.firstIndex(where: { $0.id == memory.id }) {
            memories[index] = memory
        } else {
            memories.insert(memory, at: 0)
        }
        Task { await memoryStore.save(memories) }
    }

    /// Handles a deleted memory notification from the gateway.
    private func handleMemoryDeleted(_ memoryId: String) {
        memories.removeAll { $0.id == memoryId }
        Task { await memoryStore.save(memories) }
    }

    /// Requests deletion of a memory via the gateway.
    func requestMemoryDelete(id: String) {
        // Optimistically remove locally.
        memories.removeAll { $0.id == id }
        Task { await memoryStore.save(memories) }
        Task { try? await inboxService?.deleteMemory(id: id) }
    }

    // MARK: - Briefing Lifecycle

    /// Handles a new briefing from the gateway.
    private func handleBriefing(_ briefing: Briefing) {
        // Prepend to the list (newest first).
        briefings.insert(briefing, at: 0)
        Task { await briefingStore.save(briefings) }

        // Post local notification if enabled.
        if settings.notificationsEnabled {
            Task {
                await notificationService.postBriefingNotification(
                    title: briefing.title,
                    summary: briefing.summary,
                    briefingID: briefing.id
                )
            }
        }
    }

    /// Sends the current briefing configuration to the gateway.
    func sendBriefingConfig() {
        Task {
            try? await inboxService?.sendBriefingConfig(
                enabled: settings.briefingEnabled,
                time: settings.briefingTime,
                timezone: settings.briefingTimezone,
                sources: settings.briefingSources.map(\.rawValue)
            )
        }
    }

    // MARK: - Push Notification Registration

    /// Registers the APNs device token and sends it to the gateway.
    func registerDeviceToken(_ token: String) {
        deviceToken = token
        notificationService.setDeviceToken(token)
        Task { try? await inboxService?.sendDeviceToken(token) }
    }
}
