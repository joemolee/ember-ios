import SwiftUI

// MARK: - PlatformIcon

/// An SF Symbol in a colored circle representing the message source platform.
struct PlatformIcon: View {

    let platform: MessagePlatform
    var size: CGFloat = 32

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(backgroundColor)
            .clipShape(Circle())
    }

    // MARK: - Platform Styling

    private var symbolName: String {
        switch platform {
        case .iMessage: return "message.fill"
        case .slack: return "number"
        case .teams: return "person.3.fill"
        }
    }

    private var backgroundColor: Color {
        switch platform {
        case .iMessage: return .blue
        case .slack: return .purple
        case .teams: return .indigo
        }
    }
}

// MARK: - Preview

#Preview("PlatformIcon — All Platforms") {
    HStack(spacing: EmberTheme.Spacing.md) {
        ForEach(MessagePlatform.allCases) { platform in
            VStack(spacing: EmberTheme.Spacing.xs) {
                PlatformIcon(platform: platform)
                Text(platform.displayName)
                    .font(EmberTheme.Typography.caption)
                    .foregroundStyle(Color.ember.textSecondary)
            }
        }
    }
    .padding(EmberTheme.Spacing.lg)
    .background(Color.ember.background)
}
