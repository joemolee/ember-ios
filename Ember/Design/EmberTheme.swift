import SwiftUI

// MARK: - Ember Design Tokens

enum EmberTheme {

    // MARK: - Colors (Asset Catalog References)

    enum Colors {
        static let background = Color("Colors/EmberBackground")
        static let surface = Color("Colors/EmberSurface")
        static let primary = Color("Colors/EmberPrimary")
        static let glow = Color("Colors/EmberGlow")
        static let textPrimary = Color("Colors/EmberTextPrimary")
        static let textSecondary = Color("Colors/EmberTextSecondary")
        static let userBubble = Color("Colors/EmberUserBubble")
    }

    // MARK: - Spacing Scale

    enum Spacing {
        /// 4pt
        static let xs: CGFloat = 4
        /// 8pt
        static let sm: CGFloat = 8
        /// 16pt
        static let md: CGFloat = 16
        /// 24pt
        static let lg: CGFloat = 24
        /// 32pt
        static let xl: CGFloat = 32
        /// 48pt
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radii

    enum Radii {
        /// 8pt
        static let small: CGFloat = 8
        /// 12pt
        static let medium: CGFloat = 12
        /// 16pt
        static let large: CGFloat = 16
        /// Full capsule radius
        static let full: CGFloat = 9999
    }

    // MARK: - Typography

    enum Typography {
        /// SF Pro Rounded, 28pt, Bold — for screen titles
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        /// SF Pro Rounded, 20pt, Semibold — for section headings
        static let headline = Font.system(size: 20, weight: .semibold, design: .rounded)
        /// SF Pro Rounded, 16pt, Regular — for body text
        static let body = Font.system(size: 16, weight: .regular, design: .rounded)
        /// SF Pro Rounded, 13pt, Regular — for captions and metadata
        static let caption = Font.system(size: 13, weight: .regular, design: .rounded)
    }

    // MARK: - Shadows

    enum Shadow {
        /// Subtle shadow for cards and elevated surfaces
        static let card = EmberShadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 4
        )

        /// Stronger shadow for floating elements like FABs
        static let elevated = EmberShadow(
            color: Color.black.opacity(0.15),
            radius: 16,
            x: 0,
            y: 8
        )

        /// Glow shadow using the primary ember color
        static let glow = EmberShadow(
            color: Colors.primary.opacity(0.3),
            radius: 12,
            x: 0,
            y: 0
        )
    }
}

// MARK: - Shadow Value Type

struct EmberShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}
