import SwiftUI

// MARK: - PulsingDot

/// A voice recording activity indicator composed of three pulsing dots
/// in a row with staggered timing to create a wave effect.
/// The entire indicator is hidden when `isActive` is false.
struct PulsingDot: View {

    // MARK: - Properties

    /// Controls whether the pulsing animation is visible and running.
    @Binding var isActive: Bool

    /// The color of the dots. Defaults to the ember primary orange.
    var color: Color

    /// Diameter of each individual dot.
    private let dotSize: CGFloat = 12

    /// Per-dot stagger delay in seconds.
    private let staggerDelay: Double = 0.22

    // MARK: - Init

    init(isActive: Binding<Bool>, color: Color = Color.ember.primary) {
        self._isActive = isActive
        self.color = color
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: EmberTheme.Spacing.xs) {
            ForEach(0..<3, id: \.self) { index in
                SinglePulsingDot(
                    color: color,
                    size: dotSize,
                    delay: Double(index) * staggerDelay,
                    isActive: isActive
                )
            }
        }
        .opacity(isActive ? 1 : 0)
        .animation(.easeInOut(duration: 0.25), value: isActive)
    }
}

// MARK: - SinglePulsingDot

/// A single animated dot that scales and fades in a continuous loop.
private struct SinglePulsingDot: View {

    let color: Color
    let size: CGFloat
    let delay: Double
    let isActive: Bool

    @State private var isAnimating: Bool = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(isAnimating ? 1.4 : 1.0)
            .opacity(isAnimating ? 0.6 : 1.0)
            .animation(
                isActive
                    ? .easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                    : .default,
                value: isAnimating
            )
            .onChange(of: isActive) { _, active in
                if active {
                    // Small task-yield so the stagger delay is respected
                    // before the animation loop begins.
                    Task {
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        isAnimating = true
                    }
                } else {
                    isAnimating = false
                }
            }
            .onAppear {
                guard isActive else { return }
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    isAnimating = true
                }
            }
    }
}

// MARK: - Preview

#Preview("PulsingDot — Interactive") {
    @Previewable @State var isActive: Bool = true

    VStack(spacing: EmberTheme.Spacing.xl) {
        // Default ember primary color
        PulsingDot(isActive: $isActive)

        // Glow color variant
        PulsingDot(isActive: $isActive, color: Color.ember.glow)

        // Toggle control
        Button(isActive ? "Stop Recording" : "Start Recording") {
            isActive.toggle()
        }
        .font(EmberTheme.Typography.body)
        .foregroundStyle(Color.ember.primary)
        .padding(.top, EmberTheme.Spacing.lg)

        // Usage context — simulated mic button row
        HStack(spacing: EmberTheme.Spacing.md) {
            Image(systemName: "mic.fill")
                .font(.title2)
                .foregroundStyle(isActive ? Color.ember.primary : Color.ember.textSecondary)
                .animation(.emberSubtle, value: isActive)

            PulsingDot(isActive: $isActive)

            Spacer()

            Text(isActive ? "Listening…" : "Tap to speak")
                .font(EmberTheme.Typography.caption)
                .foregroundStyle(Color.ember.textSecondary)
        }
        .padding(EmberTheme.Spacing.md)
        .background(Color.ember.surface)
        .clipShape(RoundedRectangle(cornerRadius: EmberTheme.Radii.large, style: .continuous))
    }
    .padding(EmberTheme.Spacing.xl)
    .background(Color.ember.background)
}
