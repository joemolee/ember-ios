import Foundation

enum AIProvider: String, Codable, CaseIterable, Identifiable {
    case claude
    case openClaw

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claude: return "Claude (Direct)"
        case .openClaw: return "OpenClaw Gateway"
        }
    }

    var description: String {
        switch self {
        case .claude: return "Connect directly to Claude API"
        case .openClaw: return "Connect via OpenClaw Gateway for memory, tools, and multi-provider routing"
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .claude: return true
        case .openClaw: return false
        }
    }

    var requiresGatewayURL: Bool {
        switch self {
        case .claude: return false
        case .openClaw: return true
        }
    }
}
