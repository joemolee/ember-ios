import SwiftUI

// MARK: - EmberBadge

/// A notification count badge rendered as a small red circle with a number.
/// Overlays on toolbar buttons (e.g., the inbox icon) to show unread count.
struct EmberBadge: View {

    let count: Int

    var body: some View {
        if count > 0 {
            Text(count > 99 ? "99+" : "\(count)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, count > 9 ? 5 : 4)
                .padding(.vertical, 2)
                .background(.red)
                .clipShape(Capsule())
                .fixedSize()
        }
    }
}

// MARK: - Badge Overlay Modifier

extension View {
    /// Overlays an `EmberBadge` at the top-trailing corner of the view.
    func emberBadge(count: Int) -> some View {
        overlay(alignment: .topTrailing) {
            EmberBadge(count: count)
                .offset(x: 8, y: -6)
        }
    }
}

// MARK: - Preview

#Preview("EmberBadge — Variants") {
    HStack(spacing: EmberTheme.Spacing.xl) {
        Image(systemName: "tray.fill")
            .font(.title2)
            .foregroundStyle(Color.ember.primary)
            .emberBadge(count: 3)

        Image(systemName: "tray.fill")
            .font(.title2)
            .foregroundStyle(Color.ember.primary)
            .emberBadge(count: 42)

        Image(systemName: "tray.fill")
            .font(.title2)
            .foregroundStyle(Color.ember.primary)
            .emberBadge(count: 150)

        Image(systemName: "tray.fill")
            .font(.title2)
            .foregroundStyle(Color.ember.primary)
            .emberBadge(count: 0)
    }
    .padding(EmberTheme.Spacing.xl)
    .background(Color.ember.background)
}
