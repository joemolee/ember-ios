import SwiftUI

// MARK: - AppRouter

/// Typed navigation router using NavigationPath for the Ember app.
/// Manages the navigation stack and provides methods for programmatic navigation.
@Observable
final class AppRouter {

    // MARK: - Navigation State

    var path = NavigationPath()

    // MARK: - Destination

    /// All possible navigation destinations within the app.
    enum Destination: Hashable {
        case chat(Conversation)
        case settings
        case newChat
        case inbox
        case memory
        case briefing

        // Conversation is Equatable but not Hashable by default.
        // Provide explicit Hashable conformance by hashing the discriminator
        // and, for .chat, the conversation's stable UUID.
        func hash(into hasher: inout Hasher) {
            switch self {
            case .chat(let conversation):
                hasher.combine(0)
                hasher.combine(conversation.id)
            case .settings:
                hasher.combine(1)
            case .newChat:
                hasher.combine(2)
            case .inbox:
                hasher.combine(3)
            case .memory:
                hasher.combine(4)
            case .briefing:
                hasher.combine(5)
            }
        }

        static func == (lhs: Destination, rhs: Destination) -> Bool {
            switch (lhs, rhs) {
            case (.chat(let a), .chat(let b)):
                return a == b
            case (.settings, .settings):
                return true
            case (.newChat, .newChat):
                return true
            case (.inbox, .inbox):
                return true
            case (.memory, .memory):
                return true
            case (.briefing, .briefing):
                return true
            default:
                return false
            }
        }
    }

    // MARK: - Navigation Methods

    /// Push a new destination onto the navigation stack.
    func navigate(to destination: Destination) {
        path.append(destination)
    }

    /// Pop all views and return to the root (ConversationListScreen).
    func popToRoot() {
        path = NavigationPath()
    }

    /// Pop the topmost view from the navigation stack.
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
