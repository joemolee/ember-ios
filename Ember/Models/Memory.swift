import Foundation

// MARK: - MemoryCategory

/// Classification of a Gateway-managed memory.
enum MemoryCategory: String, Codable, CaseIterable, Identifiable {
    case preference
    case fact
    case correction
    case context

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .preference: return "Preference"
        case .fact: return "Fact"
        case .correction: return "Correction"
        case .context: return "Context"
        }
    }

    var iconName: String {
        switch self {
        case .preference: return "heart.fill"
        case .fact: return "brain.head.profile"
        case .correction: return "arrow.triangle.2.circlepath"
        case .context: return "info.circle.fill"
        }
    }
}

// MARK: - MemorySource

/// How a memory was created.
enum MemorySource: String, Codable {
    case conversation
    case manual
    case inferred
}

// MARK: - Memory

/// A fact, preference, correction, or context that the Gateway AI remembers across conversations.
/// The `id` is Gateway-assigned and opaque to iOS.
struct Memory: Identifiable, Codable, Equatable {
    let id: String
    let category: MemoryCategory
    let content: String
    let source: MemorySource
    let createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        category: MemoryCategory,
        content: String,
        source: MemorySource = .conversation,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.content = content
        self.source = source
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
