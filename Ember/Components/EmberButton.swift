import SwiftUI

// MARK: - EmberButton

/// A themed button component following the Ember design system.
/// Supports primary and secondary styles, a loading state, and haptic feedback.
struct EmberButton: View {

    // MARK: - Style

    enum Style {
        /// Solid ember-orange background with white text.
        case primary
        /// Transparent background with ember-orange text and border.
        case secondary
    }

    // MARK: - Properties

    let label: String
    let style: Style
    let isLoading: Bool
    let action: () -> Void

    // MARK: - State

    @State private var isPressed: Bool = false
    @State private var hapticTrigger: Bool = false

    // MARK: - Init

    init(
        _ label: String,
        style: Style = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button {
            guard !isLoading else { return }
            hapticTrigger.toggle()
            action()
        } label: {
            buttonContent
        }
        .buttonStyle(EmberButtonStyle(style: style, isPressed: isPressed, isLoading: isLoading))
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isLoading else { return }
                    withAnimation(.emberSnappy) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.emberSnappy) { isPressed = false }
                }
        )
        .sensoryFeedback(.impact(flexibility: .soft), trigger: hapticTrigger)
        .disabled(isLoading)
    }

    // MARK: - Button Content

    @ViewBuilder
    private var buttonContent: some View {
        ZStack {
            // Visible label (hidden during loading)
            Text(label)
                .font(EmberTheme.Typography.body)
                .fontWeight(.semibold)
                .opacity(isLoading ? 0 : 1)

            // Loading spinner (visible during loading)
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: labelColor))
                    .scaleEffect(0.9)
            }
        }
        .foregroundStyle(labelColor)
        .frame(maxWidth: .infinity)
        .padding(.vertical, EmberTheme.Spacing.md)
        .padding(.horizontal, EmberTheme.Spacing.lg)
    }

    // MARK: - Derived Colors

    private var labelColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return Color.ember.primary
        }
    }
}

// MARK: - Button Style

private struct EmberButtonStyle: ButtonStyle {
    let style: EmberButton.Style
    let isPressed: Bool
    let isLoading: Bool

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed || isPressed

        configuration.label
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: EmberTheme.Radii.medium, style: .continuous))
            .overlay(borderOverlay)
            .shadow(
                color: glowColor(for: pressed),
                radius: pressed ? 16 : 0,
                x: 0,
                y: 0
            )
            .scaleEffect(pressed && !isLoading ? 0.97 : 1.0)
            .animation(.emberSnappy, value: pressed)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            Color.ember.primary
        case .secondary:
            Color.clear
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if style == .secondary {
            RoundedRectangle(cornerRadius: EmberTheme.Radii.medium, style: .continuous)
                .stroke(Color.ember.primary, lineWidth: 1.5)
        }
    }

    private func glowColor(for pressed: Bool) -> Color {
        guard pressed, style == .primary else { return .clear }
        return Color.ember.glow.opacity(0.5)
    }
}

// MARK: - Preview

#Preview("EmberButton — States") {
    VStack(spacing: EmberTheme.Spacing.md) {
        EmberButton("Get Started", style: .primary) {}

        EmberButton("Loading…", style: .primary, isLoading: true) {}

        EmberButton("Sign In with Email", style: .secondary) {}

        EmberButton("Loading…", style: .secondary, isLoading: true) {}
    }
    .padding(EmberTheme.Spacing.lg)
    .background(Color.ember.background)
}
