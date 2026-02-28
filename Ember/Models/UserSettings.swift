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

        // Backward-compatible: new inbox fields default gracefully when absent.
        inboxEnabled = try container.decodeIfPresent(Bool.self, forKey: .inboxEnabled) ?? false
        inboxSources = try container.decodeIfPresent(Set<MessagePlatform>.self, forKey: .inboxSources) ?? Set(MessagePlatform.allCases)
        inboxUrgencyThreshold = try container.decodeIfPresent(UrgencyLevel.self, forKey: .inboxUrgencyThreshold) ?? .informational
        inboxVIPs = try container.decodeIfPresent([String].self, forKey: .inboxVIPs) ?? []
        inboxPriorityTopics = try container.decodeIfPresent([String].self, forKey: .inboxPriorityTopics) ?? []
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
    }
}
