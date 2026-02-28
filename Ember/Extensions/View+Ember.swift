import SwiftUI

// MARK: - Ember View Modifiers

extension View {

    /// Adds a subtle radial glow effect behind the view.
    /// - Parameters:
    ///   - color: The glow color. Defaults to `Color.ember.primary`.
    ///   - radius: The blur radius of the glow. Defaults to 12.
    /// - Returns: A view with a radial glow applied beneath it.
    func emberGlow(color: Color = Color.ember.primary, radius: CGFloat = 12) -> some View {
        modifier(EmberGlowModifier(color: color, radius: radius))
    }

    /// Applies themed card styling: surface background, rounded corners, and shadow.
    /// - Returns: A view styled as an Ember card.
    func emberCard() -> some View {
        modifier(EmberCardModifier())
    }

    /// Applies the standard Ember shadow.
    /// - Returns: A view with the Ember card shadow applied.
    func emberShadow() -> some View {
        modifier(EmberShadowModifier())
    }
}

// MARK: - Glow Modifier

private struct EmberGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                color
                    .opacity(0.4)
                    .blur(radius: radius)
            )
    }
}

// MARK: - Card Modifier

private struct EmberCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        let shadow = EmberTheme.Shadow.card

        content
            .padding(EmberTheme.Spacing.md)
            .background(Color.ember.surface)
            .clipShape(RoundedRectangle(cornerRadius: EmberTheme.Radii.medium, style: .continuous))
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

// MARK: - Shadow Modifier

private struct EmberShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        let shadow = EmberTheme.Shadow.card

        content
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}
