import SwiftUI

// MARK: - Color.ember Namespace

extension Color {
    /// Ember design system color namespace.
    /// Usage: `Color.ember.background`, `Color.ember.primary`, etc.
    enum ember {
        /// Warm cream (light) / Deep charcoal-brown (dark) — full-screen backgrounds
        static let background = Color("Colors/EmberBackground")

        /// Lighter cream (light) / Warm dark brown (dark) — cards, sheets, elevated surfaces
        static let surface = Color("Colors/EmberSurface")

        /// Ember orange #FF6B35 — primary brand color, CTAs, active states
        static let primary = Color("Colors/EmberPrimary")

        /// Golden amber (light) / Warm orange (dark) — accent highlights, glowing elements
        static let glow = Color("Colors/EmberGlow")

        /// Near-black (light) / Off-white cream (dark) — primary text color
        static let textPrimary = Color("Colors/EmberTextPrimary")

        /// Warm gray-brown — secondary/muted text, timestamps, metadata
        static let textSecondary = Color("Colors/EmberTextSecondary")

        /// Ember orange #FF6B35 — user message bubble fill
        static let userBubble = Color("Colors/EmberUserBubble")
    }
}
