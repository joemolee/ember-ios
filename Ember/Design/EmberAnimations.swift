import SwiftUI

// MARK: - Spring Animation Presets

extension Animation {

    /// Standard spring for most UI transitions (response: 0.4, damping: 0.75)
    static let emberStandard = Animation.spring(response: 0.4, dampingFraction: 0.75)

    /// Snappy spring for quick interactions like button taps (response: 0.3, damping: 0.8)
    static let emberSnappy = Animation.spring(response: 0.3, dampingFraction: 0.8)

    /// Bouncy spring for playful elements and celebrations (response: 0.5, damping: 0.6)
    static let emberBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)

    /// Subtle spring for micro-interactions and hover states (response: 0.3, damping: 0.9)
    static let emberSubtle = Animation.spring(response: 0.3, dampingFraction: 0.9)
}

// MARK: - Staggered Animation Helpers

enum EmberAnimations {

    /// Calculates a staggered delay for an item at a given index.
    /// - Parameters:
    ///   - index: The position of the item in the sequence (0-based).
    ///   - baseDelay: The delay increment per item. Defaults to 0.05 seconds.
    ///   - maxDelay: The maximum total delay to cap the stagger. Defaults to 0.5 seconds.
    /// - Returns: A `Double` representing the delay in seconds.
    static func staggerDelay(for index: Int, baseDelay: Double = 0.05, maxDelay: Double = 0.5) -> Double {
        min(Double(index) * baseDelay, maxDelay)
    }

    /// Returns a staggered spring animation for an item at the given index.
    /// Uses the standard ember spring with an incremental delay per index.
    /// - Parameters:
    ///   - index: The position of the item in the sequence (0-based).
    ///   - baseDelay: The delay increment per item. Defaults to 0.05 seconds.
    /// - Returns: An `Animation` with appropriate delay applied.
    static func staggeredAppear(for index: Int, baseDelay: Double = 0.05) -> Animation {
        Animation.emberStandard.delay(staggerDelay(for: index, baseDelay: baseDelay))
    }

    /// Returns a snappy staggered animation suited for list items.
    /// - Parameters:
    ///   - index: The position of the item in the sequence (0-based).
    ///   - baseDelay: The delay increment per item. Defaults to 0.04 seconds.
    /// - Returns: An `Animation` with appropriate delay applied.
    static func staggeredSnappy(for index: Int, baseDelay: Double = 0.04) -> Animation {
        Animation.emberSnappy.delay(staggerDelay(for: index, baseDelay: baseDelay))
    }

    /// Executes a closure with staggered timing for each index in a range.
    /// Useful for imperatively triggering state changes across multiple items.
    /// - Parameters:
    ///   - count: The number of items to stagger.
    ///   - baseDelay: The delay increment per item. Defaults to 0.05 seconds.
    ///   - animation: The base animation to use. Defaults to `.emberStandard`.
    ///   - body: A closure called for each index that should trigger state changes.
    static func staggered(
        count: Int,
        baseDelay: Double = 0.05,
        animation: Animation = .emberStandard,
        body: @escaping (Int) -> Void
    ) {
        for index in 0..<count {
            let delay = staggerDelay(for: index, baseDelay: baseDelay)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(animation) {
                    body(index)
                }
            }
        }
    }
}
