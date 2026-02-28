import SwiftUI

// MARK: - EmberApp

/// The main entry point for the Ember iOS application.
/// Conditionally shows onboarding or the primary conversation interface.
@main
struct EmberApp: App {

    // MARK: - State

    @State private var appState = AppState()
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.settings.hasCompletedOnboarding {
                    mainAppView
                } else {
                    OnboardingScreen(settings: appState.settings) {
                        appState.syncSettings()
                    }
                    .transition(.opacity)
                }
            }
            .animation(.emberStandard, value: appState.settings.hasCompletedOnboarding)
            .environment(appState)
            .preferredColorScheme(.dark)
            .onAppear {
                configureAppDelegate()
                appState.startInboxIfNeeded()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.willResignActiveNotification
                )
            ) { _ in
                appState.saveCurrentState()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: .navigateFromNotification
                )
            ) { notification in
                handleNotificationNavigation(notification)
            }
        }
    }

    // MARK: - Main App View

    /// The primary app interface: a NavigationStack rooted on the conversation list
    /// with typed navigation destinations driven by AppRouter.
    @ViewBuilder
    private var mainAppView: some View {
        NavigationStack(path: $appState.router.path) {
            ConversationListScreen(
                conversations: $appState.conversations,
                onSelect: { conversation in
                    appState.activeConversation = conversation
                    appState.router.navigate(to: .chat(conversation))
                },
                onNew: {
                    let conversation = appState.createNewConversation()
                    appState.activeConversation = conversation
                    appState.router.navigate(to: .chat(conversation))
                },
                onDelete: { conversation in
                    appState.deleteConversation(id: conversation.id)
                }
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        appState.router.navigate(to: .settings)
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.ember.primary)
                    }
                    .accessibilityLabel("Settings")
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    if appState.settings.selectedProvider == .openClaw {
                        // Memory button
                        if appState.settings.memoryEnabled {
                            Button {
                                appState.router.navigate(to: .memory)
                            } label: {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(Color.ember.primary)
                            }
                            .accessibilityLabel("Memories")
                        }

                        // Briefing button
                        if appState.settings.briefingEnabled, appState.latestBriefing != nil {
                            Button {
                                appState.router.navigate(to: .briefing)
                            } label: {
                                Image(systemName: "sun.horizon.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(Color.ember.glow)
                            }
                            .accessibilityLabel("Morning Briefing")
                        }

                        // Inbox button
                        if appState.settings.inboxEnabled {
                            Button {
                                appState.router.navigate(to: .inbox)
                            } label: {
                                Image(systemName: "tray.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(Color.ember.primary)
                                    .emberBadge(count: appState.unreadUrgentCount)
                            }
                            .accessibilityLabel("Inbox")
                        }
                    }
                }
            }
            .navigationDestination(for: AppRouter.Destination.self) { destination in
                switch destination {
                case .chat(let conversation):
                    chatDestination(for: conversation)
                case .settings:
                    SettingsScreen(settings: appState.settings)
                        .onDisappear {
                            appState.syncSettings()
                            appState.startInboxIfNeeded()
                            appState.sendBriefingConfig()
                        }
                case .newChat:
                    chatDestination(for: appState.createNewConversation())
                case .inbox:
                    InboxScreen(appState: appState)
                case .memory:
                    MemoryScreen(appState: appState)
                case .briefing:
                    BriefingScreen(appState: appState)
                }
            }
        }
        .tint(Color.ember.primary)
    }

    // MARK: - Chat Destination

    /// Builds a ChatScreen for the given conversation, wired to the shared
    /// AI service and haptic service from AppState.
    @ViewBuilder
    private func chatDestination(for conversation: Conversation) -> some View {
        ChatScreen(
            aiService: appState.aiService,
            conversation: conversation,
            hapticService: appState.hapticService
        )
        .onDisappear {
            // Persist the conversation when the user navigates away.
            // The ChatScreen's ChatViewModel owns the mutable copy, but the
            // conversation passed in is a value type snapshot. The ChatScreen
            // can post updates via the environment if needed. For now, we
            // persist whatever is in appState.
            if let active = appState.activeConversation {
                appState.updateConversation(active)
            }
        }
    }

    // MARK: - AppDelegate Configuration

    /// Wires the AppDelegate callbacks to AppState.
    private func configureAppDelegate() {
        appDelegate.onDeviceToken = { [weak appState] token in
            Task { @MainActor in
                appState?.registerDeviceToken(token)
            }
        }

        appDelegate.onNotificationTap = { [weak appState] destination in
            Task { @MainActor in
                guard let appState else { return }
                switch destination {
                case "briefing":
                    appState.router.navigate(to: .briefing)
                default:
                    appState.router.navigate(to: .inbox)
                }
            }
        }
    }

    // MARK: - Notification Navigation

    /// Handles deep-linking from notification taps.
    private func handleNotificationNavigation(_ notification: Foundation.Notification) {
        guard let destination = notification.userInfo?["destination"] as? String else { return }
        switch destination {
        case "briefing":
            appState.router.navigate(to: .briefing)
        default:
            appState.router.navigate(to: .inbox)
        }
    }
}

// MARK: - EnvironmentValues

/// Makes AppState available to any view in the hierarchy via @Environment.
private struct AppStateKey: EnvironmentKey {
    @MainActor static let defaultValue = AppState()
}

extension EnvironmentValues {
    var appState: AppState {
        get { self[AppStateKey.self] }
        set { self[AppStateKey.self] = newValue }
    }
}

// MARK: - Previews

#Preview("EmberApp - Main") {
    @Previewable @State var state = AppState()

    let _ = { state.settings.hasCompletedOnboarding = true }()

    NavigationStack {
        ConversationListScreen(
            conversations: .constant([
                Conversation(
                    title: "Swift Concurrency",
                    messages: [
                        Message(role: .user, content: "Explain async/await"),
                        Message(role: .assistant, content: "Swift concurrency makes async code safe and readable.")
                    ],
                    updatedAt: Date()
                ),
                Conversation(
                    title: "Travel Planning",
                    messages: [
                        Message(role: .user, content: "Best places to visit in Japan?")
                    ],
                    updatedAt: Date().addingTimeInterval(-3600)
                ),
            ]),
            onSelect: { _ in },
            onNew: { },
            onDelete: { _ in }
        )
    }
    .environment(state)
    .preferredColorScheme(.dark)
}

#Preview("EmberApp - Onboarding") {
    @Previewable @State var state = AppState()

    OnboardingScreen(settings: state.settings) { }
        .environment(state)
        .preferredColorScheme(.dark)
}
