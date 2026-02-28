import SwiftUI

// MARK: - SettingsScreen

/// The main settings screen with sections for AI provider selection,
/// API configuration, notifications, memory, briefing, appearance, and app information.
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
                    notificationsSection
                    memorySection
                    briefingSection
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

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
            sectionHeader("Notifications")

            EmberCard {
                VStack(alignment: .leading, spacing: EmberTheme.Spacing.md) {
                    Toggle(isOn: $settings.notificationsEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Push Notifications")
                                .font(EmberTheme.Typography.body)
                                .foregroundStyle(Color.ember.textPrimary)

                            Text("Get notified of urgent messages and morning briefings")
                                .font(EmberTheme.Typography.caption)
                                .foregroundStyle(Color.ember.textSecondary)
                        }
                    }
                    .tint(Color.ember.primary)

                    if settings.notificationsEnabled {
                        Button {
                            Task {
                                let granted = await NotificationService().requestPermission()
                                if granted {
                                    await UIApplication.shared.registerForRemoteNotifications()
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "bell.badge.fill")
                                Text("Request Permission")
                            }
                            .font(EmberTheme.Typography.body)
                            .foregroundStyle(Color.ember.primary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Memory Section

    private var memorySection: some View {
        VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
            sectionHeader("Memory")

            MemorySettingsView(settings: settings)
        }
    }

    // MARK: - Briefing Section

    private var briefingSection: some View {
        VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
            sectionHeader("Morning Briefing")

            EmberCard {
                VStack(alignment: .leading, spacing: EmberTheme.Spacing.md) {
                    Toggle(isOn: $settings.briefingEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable Morning Briefing")
                                .font(EmberTheme.Typography.body)
                                .foregroundStyle(Color.ember.textPrimary)

                            Text("Receive a daily summary of your messages and action items")
                                .font(EmberTheme.Typography.caption)
                                .foregroundStyle(Color.ember.textSecondary)
                        }
                    }
                    .tint(Color.ember.primary)

                    if settings.briefingEnabled {
                        Divider()
                            .background(Color.ember.textSecondary.opacity(0.2))

                        // Time picker
                        briefingTimePicker

                        Divider()
                            .background(Color.ember.textSecondary.opacity(0.2))

                        // Source toggles
                        VStack(alignment: .leading, spacing: EmberTheme.Spacing.sm) {
                            Text("SOURCES")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.ember.textSecondary)

                            ForEach(MessagePlatform.allCases) { platform in
                                Toggle(isOn: briefingSourceBinding(for: platform)) {
                                    Text(platform.displayName)
                                        .font(EmberTheme.Typography.body)
                                        .foregroundStyle(Color.ember.textPrimary)
                                }
                                .tint(Color.ember.primary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Briefing Time Picker

    private var briefingTimePicker: some View {
        HStack {
            Text("Delivery Time")
                .font(EmberTheme.Typography.body)
                .foregroundStyle(Color.ember.textPrimary)

            Spacer()

            DatePicker(
                "",
                selection: briefingTimeBinding,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .tint(Color.ember.primary)
        }
    }

    /// Converts between the `"HH:mm"` string in settings and a `Date` for the DatePicker.
    private var briefingTimeBinding: Binding<Date> {
        Binding(
            get: {
                let components = settings.briefingTime.split(separator: ":").compactMap { Int($0) }
                guard components.count == 2 else {
                    return Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
                }
                return Calendar.current.date(from: DateComponents(hour: components[0], minute: components[1])) ?? Date()
            },
            set: { newDate in
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: newDate)
                let minute = calendar.component(.minute, from: newDate)
                settings.briefingTime = String(format: "%02d:%02d", hour, minute)
                settings.briefingTimezone = TimeZone.current.identifier
            }
        )
    }

    private func briefingSourceBinding(for platform: MessagePlatform) -> Binding<Bool> {
        Binding(
            get: { settings.briefingSources.contains(platform) },
            set: { enabled in
                if enabled {
                    settings.briefingSources.insert(platform)
                } else {
                    settings.briefingSources.remove(platform)
                }
            }
        )
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
