import Foundation
import UserNotifications

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorization() {
        Task {
            try? await center.requestAuthorization(options: [.alert, .sound])
        }
    }

    func sendIncidentNotification(incidentName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Claude Status"
        content.body = "⚠ Claude で障害が発生しました: \(incidentName)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "incident-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    func sendRecoveryNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Claude Status"
        content.body = "✅ Claude は復旧しました"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "recovery-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    // Show notifications even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
