import SwiftUI

// MARK: - GlowEffect ViewModifier

/// Applies a multi-layered radial glow effect to any view using stacked `.shadow` calls.
/// Multiple shadow passes with increasing radii simulate a soft, luminous glow.
struct GlowEffect: ViewModifier {

    // MARK: - Properties

    /// The color of the glow. Defaults to `Color.ember.glow`.
    var color: Color
    /// The maximum blur radius for the outermost glow layer. Defaults to `20`.
    var radius: CGFloat
    /// The overall opacity applied to the glow color. Defaults to `0.3`.
    var opacity: Double

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            // Inner glow — tight, intense core
            .shadow(
                color: color.opacity(opacity * 1.2),
                radius: radius * 0.25,
                x: 0,
                y: 0
            )
            // Mid glow — softens the falloff
            .shadow(
                color: color.opacity(opacity * 0.8),
                radius: radius * 0.55,
                x: 0,
                y: 0
            )
            // Outer glow — wide, diffused halo
            .shadow(
                color: color.opacity(opacity * 0.4),
                radius: radius,
                x: 0,
                y: 0
            )
    }
}

// MARK: - View Extension

extension View {

    /// Adds a soft radial glow behind the view using layered shadows.
    /// - Parameters:
    ///   - color: The glow color. Defaults to `Color.ember.glow`.
    ///   - radius: The outer blur radius. Defaults to `20`.
    ///   - opacity: The base opacity multiplier. Defaults to `0.3`.
    /// - Returns: A view with the glow effect applied.
    func glowEffect(
        color: Color = Color.ember.glow,
        radius: CGFloat = 20,
        opacity: Double = 0.3
    ) -> some View {
        modifier(GlowEffect(color: color, radius: radius, opacity: opacity))
    }
}

// MARK: - Preview

#Preview("GlowEffect — Variants") {
    VStack(spacing: EmberTheme.Spacing.xl) {
        // Default glow color (ember glow)
        Circle()
            .fill(Color.ember.primary)
            .frame(width: 60, height: 60)
            .glowEffect()

        // Custom primary color, tighter radius
        RoundedRectangle(cornerRadius: EmberTheme.Radii.medium, style: .continuous)
            .fill(Color.ember.surface)
            .frame(width: 180, height: 56)
            .overlay(
                Text("Ember Button")
                    .font(EmberTheme.Typography.body)
                    .foregroundStyle(Color.ember.primary)
            )
            .glowEffect(color: Color.ember.primary, radius: 14, opacity: 0.4)

        // High opacity, wide radius
        Image(systemName: "flame.fill")
            .font(.system(size: 48))
            .foregroundStyle(Color.ember.glow)
            .glowEffect(color: Color.ember.glow, radius: 30, opacity: 0.5)

        // Low intensity subtle glow
        Text("Subtle glow text")
            .font(EmberTheme.Typography.headline)
            .foregroundStyle(Color.ember.textPrimary)
            .glowEffect(color: Color.ember.glow, radius: 12, opacity: 0.15)
    }
    .padding(EmberTheme.Spacing.xxl)
    .background(Color.ember.background)
}
