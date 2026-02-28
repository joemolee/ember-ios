import Foundation
import UserNotifications

// MARK: - NotificationService

/// Wraps `UNUserNotificationCenter` for permission requests, local notification posting,
/// category registration, and device token storage.
@MainActor
final class NotificationService {

    // MARK: - Properties

    /// Whether the user has granted notification permission.
    private(set) var isAuthorized: Bool = false

    /// The APNs device token hex string, set by AppDelegate.
    private(set) var deviceToken: String?

    private let center = UNUserNotificationCenter.current()

    // MARK: - Init

    init() {
        registerCategories()
    }

    // MARK: - Permission

    /// Requests notification permission. Returns `true` if granted.
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            return granted
        } catch {
            isAuthorized = false
            return false
        }
    }

    /// Checks current authorization status without prompting.
    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Device Token

    /// Stores the APNs device token hex string.
    func setDeviceToken(_ token: String) {
        deviceToken = token
    }

    // MARK: - Local Notifications

    /// Posts a local notification for an urgent inbox message.
    func postUrgentMessageNotification(sender: String, preview: String, messageID: String) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Urgent: \(sender)"
        content.body = preview
        content.sound = .default
        content.categoryIdentifier = "INBOX_MESSAGE"
        content.userInfo = ["messageID": messageID, "destination": "inbox"]

        let request = UNNotificationRequest(
            identifier: "inbox-\(messageID)",
            content: content,
            trigger: nil // Deliver immediately
        )

        try? await center.add(request)
    }

    /// Posts a local notification for a morning briefing.
    func postBriefingNotification(title: String, summary: String, briefingID: String) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = String(summary.prefix(200))
        content.sound = .default
        content.categoryIdentifier = "BRIEFING"
        content.userInfo = ["briefingID": briefingID, "destination": "briefing"]

        let request = UNNotificationRequest(
            identifier: "briefing-\(briefingID)",
            content: content,
            trigger: nil
        )

        try? await center.add(request)
    }

    // MARK: - Categories

    /// Registers notification action categories for tap handling.
    private func registerCategories() {
        let inboxCategory = UNNotificationCategory(
            identifier: "INBOX_MESSAGE",
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        let briefingCategory = UNNotificationCategory(
            identifier: "BRIEFING",
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        center.setNotificationCategories([inboxCategory, briefingCategory])
    }
}
