import SwiftUI

// MARK: - TypingIndicatorView

/// Three animated dots indicating the AI is thinking.
/// Each dot bounces upward with a staggered delay to create a wave effect.
struct TypingIndicatorView: View {

    let isVisible: Bool

    // MARK: - Constants

    private let dotSize: CGFloat = 8
    private let dotCount = 3
    private let bounceHeight: CGFloat = -6
    private let animationDuration: Double = 0.5
    private let staggerDelay: Double = 0.15

    var body: some View {
        HStack(spacing: EmberTheme.Spacing.xs + 2) {
            ForEach(0..<dotCount, id: \.self) { index in
                BouncingDot(
                    size: dotSize,
                    color: Color.ember.textSecondary,
                    bounceHeight: bounceHeight,
                    duration: animationDuration,
                    delay: Double(index) * staggerDelay,
                    isAnimating: isVisible
                )
            }
        }
        .padding(.horizontal, EmberTheme.Spacing.md)
        .padding(.vertical, EmberTheme.Spacing.sm + 2)
        .background(Color.ember.surface)
        .clipShape(RoundedRectangle(cornerRadius: EmberTheme.Radii.medium, style: .continuous))
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.25), value: isVisible)
    }
}

// MARK: - BouncingDot

/// A single dot that bounces vertically in a continuous loop.
private struct BouncingDot: View {

    let size: CGFloat
    let color: Color
    let bounceHeight: CGFloat
    let duration: Double
    let delay: Double
    let isAnimating: Bool

    @State private var isBouncing: Bool = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .offset(y: isBouncing ? bounceHeight : 0)
            .animation(
                isAnimating
                    ? .easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                    : .default,
                value: isBouncing
            )
            .onChange(of: isAnimating) { _, active in
                if active {
                    isBouncing = true
                } else {
                    isBouncing = false
                }
            }
            .onAppear {
                guard isAnimating else { return }
                isBouncing = true
            }
    }
}

// MARK: - Preview

#Preview("TypingIndicatorView") {
    @Previewable @State var isVisible: Bool = true

    VStack(spacing: EmberTheme.Spacing.xl) {
        TypingIndicatorView(isVisible: isVisible)

        Button(isVisible ? "Hide Indicator" : "Show Indicator") {
            isVisible.toggle()
        }
        .font(EmberTheme.Typography.body)
        .foregroundStyle(Color.ember.primary)
    }
    .padding(EmberTheme.Spacing.lg)
    .background(Color.ember.background)
}
