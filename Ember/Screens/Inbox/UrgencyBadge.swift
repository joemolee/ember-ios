import SwiftUI

// MARK: - UrgencyBadge

/// A colored capsule displaying the urgency level. Urgent badges get a subtle glow.
struct UrgencyBadge: View {

    let urgency: UrgencyLevel

    var body: some View {
        Text(urgency.displayName)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(backgroundColor)
            .clipShape(Capsule())
            .modifier(UrgentGlowModifier(isUrgent: urgency == .urgent))
    }

    // MARK: - Colors

    private var foregroundColor: Color {
        switch urgency {
        case .urgent: return .white
        case .important: return .black.opacity(0.85)
        case .informational: return Color.ember.textPrimary
        case .low: return Color.ember.textSecondary
        }
    }

    private var backgroundColor: Color {
        switch urgency {
        case .urgent: return .orange
        case .important: return .yellow
        case .informational: return Color.ember.surface
        case .low: return Color.ember.surface.opacity(0.6)
        }
    }
}

// MARK: - Urgent Glow Modifier

private struct UrgentGlowModifier: ViewModifier {
    let isUrgent: Bool

    func body(content: Content) -> some View {
        if isUrgent {
            content
                .shadow(color: .orange.opacity(0.4), radius: 6, x: 0, y: 0)
                .shadow(color: .orange.opacity(0.2), radius: 12, x: 0, y: 0)
        } else {
            content
        }
    }
}

// MARK: - Preview

#Preview("UrgencyBadge — All Levels") {
    VStack(spacing: EmberTheme.Spacing.md) {
        ForEach(UrgencyLevel.allCases, id: \.rawValue) { level in
            UrgencyBadge(urgency: level)
        }
    }
    .padding(EmberTheme.Spacing.lg)
    .background(Color.ember.background)
}
