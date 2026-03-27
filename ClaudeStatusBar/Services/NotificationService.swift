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
        content.title = String(localized: "Claude Status")
        content.body = String(localized: "⚠ Incident detected on Claude: \(incidentName)")
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
        content.title = String(localized: "Claude Status")
        content.body = String(localized: "✅ Claude is back to operational")
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "recovery-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    func sendComponentIncidentNotification(componentName: String, status: ComponentStatus) {
        let statusText: String
        switch status {
        case .operational: return
        case .degradedPerformance: statusText = String(localized: "Degraded")
        case .partialOutage: statusText = String(localized: "Partial Outage")
        case .majorOutage: statusText = String(localized: "Major Outage")
        }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Claude Status")
        content.body = "⚠ \(componentName): \(statusText)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "component-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    func sendComponentRecoveryNotification(componentName: String) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Claude Status")
        content.body = String(localized: "✅ \(componentName) is back to operational")
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "component-recovery-\(UUID().uuidString)",
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
