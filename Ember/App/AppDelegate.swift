import UIKit
import UserNotifications

// MARK: - AppDelegate

/// UIApplicationDelegate adapter for APNs device token registration
/// and UNUserNotificationCenterDelegate for foreground display and tap handling.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    // MARK: - Callbacks

    /// Called when the APNs device token is received.
    var onDeviceToken: ((String) -> Void)?

    /// Called when the user taps a notification. Passes the destination string.
    var onNotificationTap: ((String) -> Void)?

    // MARK: - UIApplicationDelegate

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        onDeviceToken?(tokenString)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Silently fail — push is best-effort.
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Display notifications even when the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    /// Handle notification tap — post a notification for deep linking.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let destination = userInfo["destination"] as? String ?? "inbox"
        onNotificationTap?(destination)
        NotificationCenter.default.post(
            name: .navigateFromNotification,
            object: nil,
            userInfo: ["destination": destination]
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when the user taps a push/local notification. `userInfo["destination"]` contains the target.
    static let navigateFromNotification = Notification.Name("navigateFromNotification")
}
