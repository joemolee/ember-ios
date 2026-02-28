import SwiftUI

// MARK: - InboxFilterBar

/// Horizontal scroll of filter chips: All, iMessage, Slack, Teams.
struct InboxFilterBar: View {

    @Binding var selectedPlatform: MessagePlatform?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: EmberTheme.Spacing.sm) {
                filterChip(label: "All", isSelected: selectedPlatform == nil) {
                    selectedPlatform = nil
                }

                ForEach(MessagePlatform.allCases) { platform in
                    filterChip(
                        label: platform.displayName,
                        isSelected: selectedPlatform == platform
                    ) {
                        selectedPlatform = platform
                    }
                }
            }
            .padding(.horizontal, EmberTheme.Spacing.md)
        }
    }

    // MARK: - Filter Chip

    private func filterChip(
        label: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(isSelected ? .white : Color.ember.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.ember.primary : Color.ember.surface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.emberSnappy, value: isSelected)
    }
}

// MARK: - Preview

#Preview("InboxFilterBar") {
    @Previewable @State var selected: MessagePlatform? = nil

    VStack {
        InboxFilterBar(selectedPlatform: $selected)
    }
    .padding(.vertical, EmberTheme.Spacing.md)
    .background(Color.ember.background)
}
