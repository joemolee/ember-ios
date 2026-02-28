import Foundation

@Observable
final class UserSettings: Codable {
    var selectedProvider: AIProvider = .claude
    var claudeModel: String = "claude-sonnet-4-20250514"
    var gatewayURL: String = "ws://localhost:3000"
    var hasCompletedOnboarding: Bool = false
    var hapticFeedbackEnabled: Bool = true
    var streamingEnabled: Bool = true

    // MARK: - Inbox Settings

    var inboxEnabled: Bool = false
    var inboxSources: Set<MessagePlatform> = Set(MessagePlatform.allCases)
    var inboxUrgencyThreshold: UrgencyLevel = .informational
    var inboxVIPs: [String] = []
    var inboxPriorityTopics: [String] = []

    // MARK: - Notification Settings

    var notificationsEnabled: Bool = false

    // MARK: - Memory Settings

    var memoryEnabled: Bool = true
    var memoryCategories: Set<MemoryCategory> = Set(MemoryCategory.allCases)

    // MARK: - Briefing Settings

    var briefingEnabled: Bool = false
    var briefingTime: String = "07:00"
    var briefingTimezone: String = TimeZone.current.identifier
    var briefingSources: Set<MessagePlatform> = Set(MessagePlatform.allCases)

    enum CodingKeys: String, CodingKey {
        case selectedProvider
        case claudeModel
        case gatewayURL
        case hasCompletedOnboarding
        case hapticFeedbackEnabled
        case streamingEnabled
        case inboxEnabled
        case inboxSources
        case inboxUrgencyThreshold
        case inboxVIPs
        case inboxPriorityTopics
        case notificationsEnabled
        case memoryEnabled
        case memoryCategories
        case briefingEnabled
        case briefingTime
        case briefingTimezone
        case briefingSources
    }

    init() {}

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selectedProvider = try container.decode(AIProvider.self, forKey: .selectedProvider)
        claudeModel = try container.decode(String.self, forKey: .claudeModel)
        gatewayURL = try container.decode(String.self, forKey: .gatewayURL)
        hasCompletedOnboarding = try container.decode(Bool.self, forKey: .hasCompletedOnboarding)
        hapticFeedbackEnabled = try container.decode(Bool.self, forKey: .hapticFeedbackEnabled)
        streamingEnabled = try container.decode(Bool.self, forKey: .streamingEnabled)

        // Backward-compatible: new fields default gracefully when absent.
        inboxEnabled = try container.decodeIfPresent(Bool.self, forKey: .inboxEnabled) ?? false
        inboxSources = try container.decodeIfPresent(Set<MessagePlatform>.self, forKey: .inboxSources) ?? Set(MessagePlatform.allCases)
        inboxUrgencyThreshold = try container.decodeIfPresent(UrgencyLevel.self, forKey: .inboxUrgencyThreshold) ?? .informational
        inboxVIPs = try container.decodeIfPresent([String].self, forKey: .inboxVIPs) ?? []
        inboxPriorityTopics = try container.decodeIfPresent([String].self, forKey: .inboxPriorityTopics) ?? []
        notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? false
        memoryEnabled = try container.decodeIfPresent(Bool.self, forKey: .memoryEnabled) ?? true
        memoryCategories = try container.decodeIfPresent(Set<MemoryCategory>.self, forKey: .memoryCategories) ?? Set(MemoryCategory.allCases)
        briefingEnabled = try container.decodeIfPresent(Bool.self, forKey: .briefingEnabled) ?? false
        briefingTime = try container.decodeIfPresent(String.self, forKey: .briefingTime) ?? "07:00"
        briefingTimezone = try container.decodeIfPresent(String.self, forKey: .briefingTimezone) ?? TimeZone.current.identifier
        briefingSources = try container.decodeIfPresent(Set<MessagePlatform>.self, forKey: .briefingSources) ?? Set(MessagePlatform.allCases)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(selectedProvider, forKey: .selectedProvider)
        try container.encode(claudeModel, forKey: .claudeModel)
        try container.encode(gatewayURL, forKey: .gatewayURL)
        try container.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
        try container.encode(hapticFeedbackEnabled, forKey: .hapticFeedbackEnabled)
        try container.encode(streamingEnabled, forKey: .streamingEnabled)
        try container.encode(inboxEnabled, forKey: .inboxEnabled)
        try container.encode(inboxSources, forKey: .inboxSources)
        try container.encode(inboxUrgencyThreshold, forKey: .inboxUrgencyThreshold)
        try container.encode(inboxVIPs, forKey: .inboxVIPs)
        try container.encode(inboxPriorityTopics, forKey: .inboxPriorityTopics)
        try container.encode(notificationsEnabled, forKey: .notificationsEnabled)
        try container.encode(memoryEnabled, forKey: .memoryEnabled)
        try container.encode(memoryCategories, forKey: .memoryCategories)
        try container.encode(briefingEnabled, forKey: .briefingEnabled)
        try container.encode(briefingTime, forKey: .briefingTime)
        try container.encode(briefingTimezone, forKey: .briefingTimezone)
        try container.encode(briefingSources, forKey: .briefingSources)
    }
}
