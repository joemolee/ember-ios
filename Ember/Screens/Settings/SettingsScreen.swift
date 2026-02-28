import SwiftUI

// MARK: - SettingsScreen

/// The main settings screen with sections for AI provider selection,
/// API configuration, appearance preferences, and app information.
struct SettingsScreen: View {

    // MARK: - Properties

    @Bindable var settings: UserSettings

    // MARK: - State

    @State private var gatewayURLInput: String = ""

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: EmberTheme.Spacing.lg) {
                aiProviderSection
                apiConfigurationSection
                if settings.selectedProvider == .openClaw {
                    inboxSection
                }
                appearanceSection
                aboutSection
            }
            .padding(.horizontal, EmberTheme.Spacing.md)
            .padding(.vertical, EmberTheme.Spacing.lg)
        }
        .background(Color.ember.background)
        .scrollContentBackground(.hidden)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.ember.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            gatewayURLInput = settings.gatewayURL
        }
    }

    // MARK: - AI Provider Section

    private var aiProviderSection: some View {
        VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
            sectionHeader("AI Provider")

            EmberCard {
                VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
                    Picker("Provider", selection: $settings.selectedProvider) {
                        ForEach(AIProvider.allCases) { provider in
                            Text(provider.displayName)
                                .tag(provider)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(settings.selectedProvider.description)
                        .font(EmberTheme.Typography.caption)
                        .foregroundStyle(Color.ember.textSecondary)
                }
            }
        }
    }

    // MARK: - API Configuration Section

    private var apiConfigurationSection: some View {
        VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
            sectionHeader("API Configuration")

            switch settings.selectedProvider {
            case .claude:
                APIKeySettingView()

            case .openClaw:
                gatewayURLCard
            }
        }
    }

    // MARK: - Gateway URL Card

    private var gatewayURLCard: some View {
        EmberCard(header: "Gateway URL") {
            VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
                Text("Enter the WebSocket URL for your OpenClaw gateway")
                    .font(EmberTheme.Typography.caption)
                    .foregroundStyle(Color.ember.textSecondary)

                EmberTextField(
                    text: $gatewayURLInput,
                    placeholder: "ws://localhost:3000"
                )
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .onChange(of: gatewayURLInput) { _, newValue in
                    settings.gatewayURL = newValue
                }
            }
        }
    }

    // MARK: - Inbox Section

    private var inboxSection: some View {
        VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
            sectionHeader("Unified Inbox")

            InboxSettingsView(settings: settings)
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
            sectionHeader("Appearance")

            AppearanceSettingView(settings: settings)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
            sectionHeader("About")

            EmberCard {
                VStack(spacing: EmberTheme.Spacing.md) {
                    // App icon and name
                    HStack(spacing: EmberTheme.Spacing.sm) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.ember.primary, Color.ember.glow],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ember")
                                .font(EmberTheme.Typography.headline)
                                .foregroundStyle(Color.ember.textPrimary)

                            Text("Version \(appVersion)")
                                .font(EmberTheme.Typography.caption)
                                .foregroundStyle(Color.ember.textSecondary)
                        }

                        Spacer()
                    }

                    Divider()
                        .background(Color.ember.textSecondary.opacity(0.2))

                    Text("Made with \u{1F525} by Incendo AI")
                        .font(EmberTheme.Typography.caption)
                        .foregroundStyle(Color.ember.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.ember.textSecondary)
            .padding(.leading, EmberTheme.Spacing.xs)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Preview

#Preview("SettingsScreen - Claude") {
    @Previewable @State var settings = UserSettings()

    SettingsScreen(settings: settings)
}

#Preview("SettingsScreen - OpenClaw") {
    let settings = UserSettings()
    settings.selectedProvider = .openClaw

    return SettingsScreen(settings: settings)
}
