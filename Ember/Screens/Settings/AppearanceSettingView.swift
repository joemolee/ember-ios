import SwiftUI

// MARK: - AppearanceSettingView

/// Appearance and behavior settings: haptic feedback toggle, streaming responses toggle,
/// and Claude model picker.
struct AppearanceSettingView: View {

    // MARK: - Properties

    @Bindable var settings: UserSettings

    // MARK: - Model Options

    private let modelOptions: [(id: String, label: String)] = [
        ("claude-sonnet-4-20250514", "Claude Sonnet 4"),
        ("claude-opus-4-20250514", "Claude Opus 4"),
    ]

    // MARK: - Body

    var body: some View {
        VStack(spacing: EmberTheme.Spacing.md) {
            // Haptic Feedback Toggle
            EmberCard {
                Toggle(isOn: $settings.hapticFeedbackEnabled) {
                    settingLabel(
                        icon: "hand.tap",
                        title: "Haptic Feedback",
                        subtitle: "Vibration on button taps and interactions"
                    )
                }
                .tint(Color.ember.primary)
            }

            // Streaming Responses Toggle
            EmberCard {
                Toggle(isOn: $settings.streamingEnabled) {
                    settingLabel(
                        icon: "text.word.spacing",
                        title: "Streaming Responses",
                        subtitle: "Show words as they arrive in real time"
                    )
                }
                .tint(Color.ember.primary)
            }

            // Claude Model Picker
            EmberCard(header: "Claude Model") {
                VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
                    Text("Choose which Claude model to use for conversations")
                        .font(EmberTheme.Typography.caption)
                        .foregroundStyle(Color.ember.textSecondary)

                    Picker("Model", selection: $settings.claudeModel) {
                        ForEach(modelOptions, id: \.id) { option in
                            Text(option.label)
                                .tag(option.id)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    // MARK: - Setting Label

    private func settingLabel(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: EmberTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.ember.primary)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(EmberTheme.Typography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.ember.textPrimary)

                Text(subtitle)
                    .font(EmberTheme.Typography.caption)
                    .foregroundStyle(Color.ember.textSecondary)
            }
        }
    }
}

// MARK: - Preview

#Preview("AppearanceSettingView") {
    @Previewable @State var settings = UserSettings()

    ScrollView {
        AppearanceSettingView(settings: settings)
            .padding(EmberTheme.Spacing.lg)
    }
    .background(Color.ember.background)
}
