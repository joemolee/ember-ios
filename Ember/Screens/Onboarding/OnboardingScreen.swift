import SwiftUI
import AVFoundation
import Speech

// MARK: - OnboardingScreen

/// A three-page onboarding flow presented on first launch.
/// Page 1: Welcome with branding. Page 2: API key entry. Page 3: Permissions request.
/// Uses a TabView with page-indicator style for horizontal swiping.
struct OnboardingScreen: View {

    // MARK: - Properties

    @Bindable var settings: UserSettings
    let onComplete: () -> Void

    // MARK: - State

    @State private var currentPage: Int = 0
    @State private var apiKeyInput: String = ""
    @State private var apiKeySaved: Bool = false
    @State private var micPermissionGranted: Bool = false
    @State private var speechPermissionGranted: Bool = false
    @State private var appearAnimated: Bool = false

    // MARK: - Constants

    private let totalPages = 3

    // MARK: - Body

    var body: some View {
        ZStack {
            // Warm gradient background
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    apiKeyPage.tag(1)
                    permissionsPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .animation(.emberStandard, value: currentPage)

                // Bottom button area
                bottomButtons
                    .padding(.horizontal, EmberTheme.Spacing.lg)
                    .padding(.bottom, EmberTheme.Spacing.xl)
            }
        }
        .onAppear {
            withAnimation(.emberStandard.delay(0.2)) {
                appearAnimated = true
            }
        }
    }

    // MARK: - Background Gradient

    private var backgroundGradient: some View {
        LinearGradient(
            stops: [
                .init(color: Color.ember.background, location: 0.0),
                .init(color: Color.ember.primary.opacity(0.08), location: 0.5),
                .init(color: Color.ember.glow.opacity(0.06), location: 0.75),
                .init(color: Color.ember.background, location: 1.0),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: EmberTheme.Spacing.lg) {
            Spacer()

            // Animated ember icon
            Image(systemName: "flame.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.ember.primary, Color.ember.glow],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .emberGlow(color: Color.ember.primary, radius: 32)
                .scaleEffect(appearAnimated ? 1.0 : 0.6)
                .opacity(appearAnimated ? 1 : 0)
                .animation(.emberBouncy, value: appearAnimated)

            VStack(spacing: EmberTheme.Spacing.sm) {
                Text("Welcome to Ember")
                    .font(EmberTheme.Typography.title)
                    .foregroundStyle(Color.ember.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(appearAnimated ? 1 : 0)
                    .offset(y: appearAnimated ? 0 : 16)
                    .animation(.emberStandard.delay(0.15), value: appearAnimated)

                Text("Your personal AI assistant")
                    .font(EmberTheme.Typography.body)
                    .foregroundStyle(Color.ember.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(appearAnimated ? 1 : 0)
                    .offset(y: appearAnimated ? 0 : 12)
                    .animation(.emberStandard.delay(0.25), value: appearAnimated)
            }

            Spacer()
            Spacer()
        }
        .padding(EmberTheme.Spacing.lg)
    }

    // MARK: - Page 2: API Key

    private var apiKeyPage: some View {
        VStack(spacing: EmberTheme.Spacing.lg) {
            Spacer()

            // Header icon
            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.ember.primary)
                .padding(.bottom, EmberTheme.Spacing.sm)

            VStack(spacing: EmberTheme.Spacing.sm) {
                Text("Connect to Claude")
                    .font(EmberTheme.Typography.title)
                    .foregroundStyle(Color.ember.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Enter your Anthropic API key to chat with Claude directly. Your key is stored securely in the iOS Keychain and never leaves your device.")
                    .font(EmberTheme.Typography.body)
                    .foregroundStyle(Color.ember.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // API key input card
            VStack(spacing: EmberTheme.Spacing.md) {
                apiKeyInputCard

                // Status feedback
                if apiKeySaved {
                    HStack(spacing: EmberTheme.Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("API key saved securely")
                            .font(EmberTheme.Typography.caption)
                            .foregroundStyle(.green)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal, EmberTheme.Spacing.sm)

            Spacer()
            Spacer()
        }
        .padding(EmberTheme.Spacing.lg)
    }

    // MARK: - API Key Input Card

    private var apiKeyInputCard: some View {
        VStack(spacing: EmberTheme.Spacing.sm) {
            SecureField("sk-ant-api03-...", text: $apiKeyInput)
                .font(EmberTheme.Typography.body)
                .foregroundStyle(Color.ember.textPrimary)
                .tint(Color.ember.primary)
                .padding(.horizontal, EmberTheme.Spacing.md)
                .padding(.vertical, EmberTheme.Spacing.sm + 2)
                .background(Color.ember.surface)
                .clipShape(RoundedRectangle(cornerRadius: EmberTheme.Radii.medium, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: EmberTheme.Radii.medium, style: .continuous)
                        .stroke(Color.ember.textSecondary.opacity(0.3), lineWidth: 1)
                )
                .textContentType(.password)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            EmberButton("Save API Key", style: .primary) {
                saveAPIKey()
            }
        }
        .padding(EmberTheme.Spacing.md)
        .background(Color.ember.surface)
        .clipShape(RoundedRectangle(cornerRadius: EmberTheme.Radii.large, style: .continuous))
        .emberShadow()
    }

    // MARK: - Page 3: Permissions

    private var permissionsPage: some View {
        VStack(spacing: EmberTheme.Spacing.lg) {
            Spacer()

            // Header icon
            Image(systemName: "mic.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(Color.ember.primary)
                .padding(.bottom, EmberTheme.Spacing.sm)

            VStack(spacing: EmberTheme.Spacing.sm) {
                Text("Voice Input")
                    .font(EmberTheme.Typography.title)
                    .foregroundStyle(Color.ember.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Ember can listen and transcribe your voice for a hands-free experience. Microphone and speech recognition permissions are needed.")
                    .font(EmberTheme.Typography.body)
                    .foregroundStyle(Color.ember.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Permission rows
            VStack(spacing: EmberTheme.Spacing.md) {
                permissionRow(
                    icon: "mic.fill",
                    title: "Microphone",
                    subtitle: "Record audio for voice-to-text",
                    isGranted: micPermissionGranted
                )

                permissionRow(
                    icon: "waveform",
                    title: "Speech Recognition",
                    subtitle: "Convert your speech to text on-device",
                    isGranted: speechPermissionGranted
                )
            }
            .padding(EmberTheme.Spacing.md)
            .background(Color.ember.surface)
            .clipShape(RoundedRectangle(cornerRadius: EmberTheme.Radii.large, style: .continuous))
            .emberShadow()
            .padding(.horizontal, EmberTheme.Spacing.sm)

            // Request permissions button
            if !micPermissionGranted || !speechPermissionGranted {
                EmberButton("Grant Permissions", style: .primary) {
                    requestPermissions()
                }
                .frame(maxWidth: 260)
            }

            Spacer()
            Spacer()
        }
        .padding(EmberTheme.Spacing.lg)
    }

    // MARK: - Permission Row

    private func permissionRow(icon: String, title: String, subtitle: String, isGranted: Bool) -> some View {
        HStack(spacing: EmberTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.ember.primary)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(EmberTheme.Typography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.ember.textPrimary)

                Text(subtitle)
                    .font(EmberTheme.Typography.caption)
                    .foregroundStyle(Color.ember.textSecondary)
            }

            Spacer()

            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(isGranted ? .green : Color.ember.textSecondary.opacity(0.4))
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        HStack {
            // Skip / Back
            if currentPage > 0 {
                Button {
                    withAnimation(.emberSnappy) {
                        currentPage -= 1
                    }
                } label: {
                    Text("Back")
                        .font(EmberTheme.Typography.body)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.ember.textSecondary)
                }
            }

            Spacer()

            if currentPage < totalPages - 1 {
                // Continue or Skip
                HStack(spacing: EmberTheme.Spacing.md) {
                    if currentPage == 1 {
                        Button {
                            withAnimation(.emberSnappy) {
                                currentPage += 1
                            }
                        } label: {
                            Text("Skip")
                                .font(EmberTheme.Typography.body)
                                .foregroundStyle(Color.ember.textSecondary)
                        }
                    }

                    Button {
                        withAnimation(.emberSnappy) {
                            currentPage += 1
                        }
                    } label: {
                        HStack(spacing: EmberTheme.Spacing.xs) {
                            Text("Continue")
                                .font(EmberTheme.Typography.body)
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(Color.ember.primary)
                    }
                }
            } else {
                // Final page: Get Started or Skip
                HStack(spacing: EmberTheme.Spacing.md) {
                    if !micPermissionGranted && !speechPermissionGranted {
                        Button {
                            finishOnboarding()
                        } label: {
                            Text("Skip")
                                .font(EmberTheme.Typography.body)
                                .foregroundStyle(Color.ember.textSecondary)
                        }
                    }

                    EmberButton("Get Started") {
                        finishOnboarding()
                    }
                    .frame(maxWidth: 200)
                }
            }
        }
    }

    // MARK: - Actions

    private func saveAPIKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            try KeychainService.shared.save(key: APIKeySettingView.keychainKey, value: trimmed)
            withAnimation(.emberSubtle) {
                apiKeySaved = true
            }
            apiKeyInput = ""
        } catch {
            // Silently fail during onboarding -- user can reconfigure in Settings
        }
    }

    private func requestPermissions() {
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                withAnimation(.emberSubtle) {
                    micPermissionGranted = granted
                }
            }
        }

        // Request speech recognition permission
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                withAnimation(.emberSubtle) {
                    speechPermissionGranted = (status == .authorized)
                }
            }
        }
    }

    private func finishOnboarding() {
        settings.hasCompletedOnboarding = true
        onComplete()
    }
}

// MARK: - Preview

#Preview("OnboardingScreen") {
    @Previewable @State var settings = UserSettings()

    OnboardingScreen(settings: settings) {
        // onComplete
    }
}
