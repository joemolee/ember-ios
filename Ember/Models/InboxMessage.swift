import Foundation

// MARK: - MessagePlatform

/// The messaging platform a triaged message originated from.
enum MessagePlatform: String, Codable, CaseIterable, Identifiable {
    case iMessage
    case slack
    case teams

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .iMessage: return "iMessage"
        case .slack: return "Slack"
        case .teams: return "Teams"
        }
    }
}

// MARK: - UrgencyLevel

/// AI-determined urgency level, ordered from most to least urgent.
enum UrgencyLevel: String, Codable, CaseIterable, Comparable {
    case urgent
    case important
    case informational
    case low

    /// Enables `Comparable` so messages can be sorted by urgency.
    private var sortOrder: Int {
        switch self {
        case .urgent: return 0
        case .important: return 1
        case .informational: return 2
        case .low: return 3
        }
    }

    static func < (lhs: UrgencyLevel, rhs: UrgencyLevel) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    var displayName: String {
        switch self {
        case .urgent: return "Urgent"
        case .important: return "Important"
        case .informational: return "Info"
        case .low: return "Low"
        }
    }
}

// MARK: - TriageResult

/// The AI triage output for a single message: urgency classification and reasoning.
struct TriageResult: Codable, Equatable {
    let urgency: UrgencyLevel
    let reasoning: String
}

// MARK: - InboxMessage

/// A triaged message from iMessage, Slack, or Teams, pushed by the OpenClaw Gateway.
struct InboxMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let platform: MessagePlatform
    let senderName: String
    let senderIdentifier: String
    let content: String
    let timestamp: Date
    let conversationContext: String
    let triage: TriageResult
    var isRead: Bool
    let originalMessageID: String

    init(
        id: UUID = UUID(),
        platform: MessagePlatform,
        senderName: String,
        senderIdentifier: String,
        content: String,
        timestamp: Date = Date(),
        conversationContext: String = "",
        triage: TriageResult,
        isRead: Bool = false,
        originalMessageID: String
    ) {
        self.id = id
        self.platform = platform
        self.senderName = senderName
        self.senderIdentifier = senderIdentifier
        self.content = content
        self.timestamp = timestamp
        self.conversationContext = conversationContext
        self.triage = triage
        self.isRead = isRead
        self.originalMessageID = originalMessageID
    }
}

// MARK: - InboxMessage Helpers

extension InboxMessage {
    /// Short preview of the message body, truncated to 120 characters.
    var preview: String {
        if content.count <= 120 { return content }
        return String(content.prefix(120)) + "..."
    }
}
