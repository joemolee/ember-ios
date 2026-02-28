import SwiftUI

// MARK: - MemorySettingsView

/// Settings sub-view for memory preferences: enable toggle, per-category toggles, and clear all.
struct MemorySettingsView: View {

    @Bindable var settings: UserSettings

    @State private var showClearConfirmation = false

    var body: some View {
        EmberCard {
            VStack(alignment: .leading, spacing: EmberTheme.Spacing.md) {
                // Enable toggle
                Toggle(isOn: $settings.memoryEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Memory")
                            .font(EmberTheme.Typography.body)
                            .foregroundStyle(Color.ember.textPrimary)

                        Text("Let Ember remember facts and preferences across conversations")
                            .font(EmberTheme.Typography.caption)
                            .foregroundStyle(Color.ember.textSecondary)
                    }
                }
                .tint(Color.ember.primary)

                if settings.memoryEnabled {
                    Divider()
                        .background(Color.ember.textSecondary.opacity(0.2))

                    // Per-category toggles
                    VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
                        Text("CATEGORIES")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.ember.textSecondary)

                        ForEach(MemoryCategory.allCases) { category in
                            Toggle(isOn: categoryBinding(for: category)) {
                                HStack(spacing: EmberTheme.Spacing.sm) {
                                    Image(systemName: category.iconName)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.ember.primary)
                                        .frame(width: 20)

                                    Text(category.displayName)
                                        .font(EmberTheme.Typography.body)
                                        .foregroundStyle(Color.ember.textPrimary)
                                }
                            }
                            .tint(Color.ember.primary)
                        }
                    }

                    Divider()
                        .background(Color.ember.textSecondary.opacity(0.2))

                    // Clear all button
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear All Memories")
                        }
                        .font(EmberTheme.Typography.body)
                        .frame(maxWidth: .infinity)
                    }
                    .confirmationDialog(
                        "Clear All Memories?",
                        isPresented: $showClearConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Clear All", role: .destructive) {
                            // Will be wired to AppState in Phase 4
                        }
                    } message: {
                        Text("This will delete all stored memories. This action cannot be undone.")
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func categoryBinding(for category: MemoryCategory) -> Binding<Bool> {
        Binding(
            get: { settings.memoryCategories.contains(category) },
            set: { enabled in
                if enabled {
                    settings.memoryCategories.insert(category)
                } else {
                    settings.memoryCategories.remove(category)
                }
            }
        )
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        MemorySettingsView(settings: UserSettings())
            .padding()
    }
    .background(Color.ember.background)
    .preferredColorScheme(.dark)
}
