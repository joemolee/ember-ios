import SwiftUI

// MARK: - MemoryCard

/// A card displaying a single memory with its category icon, content, and timestamp.
struct MemoryCard: View {

    let memory: Memory

    var body: some View {
        HStack(alignment: .top, spacing: EmberTheme.Spacing.sm) {
            // Category icon
            Image(systemName: memory.category.iconName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(categoryColor)
                .frame(width: 32, height: 32)
                .background(categoryColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: EmberTheme.Radii.small))

            VStack(alignment: .leading, spacing: EmberTheme.Spacing.xs) {
                // Category label
                Text(memory.category.displayName.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(categoryColor)

                // Content
                Text(memory.content)
                    .font(EmberTheme.Typography.body)
                    .foregroundStyle(Color.ember.textPrimary)
                    .lineLimit(3)

                // Timestamp
                Text(memory.updatedAt, style: .relative)
                    .font(EmberTheme.Typography.caption)
                    .foregroundStyle(Color.ember.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(EmberTheme.Spacing.sm)
        .background(Color.ember.surface)
        .clipShape(RoundedRectangle(cornerRadius: EmberTheme.Radii.medium))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }

    // MARK: - Helpers

    private var categoryColor: Color {
        switch memory.category {
        case .preference: return .pink
        case .fact: return .blue
        case .correction: return .orange
        case .context: return .purple
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        MemoryCard(memory: Memory(
            id: "1",
            category: .preference,
            content: "Prefers concise, bullet-point summaries over long paragraphs"
        ))
        MemoryCard(memory: Memory(
            id: "2",
            category: .fact,
            content: "Works at Incendo AI as a product manager"
        ))
        MemoryCard(memory: Memory(
            id: "3",
            category: .correction,
            content: "Name is spelled 'Lindsay' not 'Lindsey'"
        ))
        MemoryCard(memory: Memory(
            id: "4",
            category: .context,
            content: "Currently working on the Ember iOS app, building push notifications and memory features"
        ))
    }
    .padding()
    .background(Color.ember.background)
    .preferredColorScheme(.dark)
}
