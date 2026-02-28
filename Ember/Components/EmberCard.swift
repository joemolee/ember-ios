import SwiftUI

// MARK: - EmberCard

/// A themed card container following the Ember design system.
/// Provides a surface background, large rounded corners, a card shadow,
/// standard inner padding, an optional header, and generic ViewBuilder content.
struct EmberCard<Content: View>: View {

    // MARK: - Properties

    let header: String?
    let content: Content

    // MARK: - Init

    /// - Parameters:
    ///   - header: Optional title string rendered above the content in headline style.
    ///   - content: The body view built with the ViewBuilder closure.
    init(
        header: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        let shadow = EmberTheme.Shadow.card

        VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
            // Optional header
            if let title = header {
                Text(title)
                    .font(EmberTheme.Typography.headline)
                    .foregroundStyle(Color.ember.textPrimary)
            }

            // Caller-supplied content
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EmberTheme.Spacing.md)
        .background(Color.ember.surface)
        .clipShape(RoundedRectangle(cornerRadius: EmberTheme.Radii.large, style: .continuous))
        .shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}

// MARK: - Preview

#Preview("EmberCard — Variants") {
    ScrollView {
        VStack(spacing: EmberTheme.Spacing.md) {
            // Card with header and multi-line body
            EmberCard(header: "Recent Activity") {
                VStack(alignment: .leading, spacing: EmberTheme.Spacing.xs) {
                    Text("You asked Ember about sleep habits.")
                        .font(EmberTheme.Typography.body)
                        .foregroundStyle(Color.ember.textPrimary)

                    Text("Yesterday at 9:41 PM")
                        .font(EmberTheme.Typography.caption)
                        .foregroundStyle(Color.ember.textSecondary)
                }
            }

            // Card without header
            EmberCard {
                HStack(spacing: EmberTheme.Spacing.sm) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color.ember.primary)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("3-day streak")
                            .font(EmberTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.ember.textPrimary)

                        Text("Keep it going!")
                            .font(EmberTheme.Typography.caption)
                            .foregroundStyle(Color.ember.textSecondary)
                    }
                }
            }

            // Nested content example
            EmberCard(header: "Mood Check-in") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: EmberTheme.Spacing.sm) {
                    ForEach(["😊", "😐", "😔", "😤"], id: \.self) { emoji in
                        Text(emoji)
                            .font(.largeTitle)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(EmberTheme.Spacing.lg)
    }
    .background(Color.ember.background)
}
