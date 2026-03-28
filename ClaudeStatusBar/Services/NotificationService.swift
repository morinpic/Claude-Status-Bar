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

    func sendIncidentNotification(incidentName: String, language: AppLanguage) {
        let content = UNMutableNotificationContent()
        content.title = "Claude Status"
        let template = language.localizedString("⚠ Incident detected on Claude: %@")
        content.body = String(format: template, incidentName)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "incident-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    func sendRecoveryNotification(language: AppLanguage) {
        let content = UNMutableNotificationContent()
        content.title = "Claude Status"
        content.body = language.localizedString("✅ Claude is back to operational")
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "recovery-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    func sendComponentIncidentNotification(componentName: String, status: ComponentStatus, language: AppLanguage) {
        let statusText: String
        switch status {
        case .operational: return
        case .degradedPerformance: statusText = "degraded performance"
        case .partialOutage: statusText = "partial outage"
        case .majorOutage: statusText = "major outage"
        }

        let content = UNMutableNotificationContent()
        content.title = "Claude Status"
        content.body = "⚠ \(componentName): \(statusText)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "component-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    func sendComponentRecoveryNotification(componentName: String, language: AppLanguage) {
        let content = UNMutableNotificationContent()
        content.title = "Claude Status"
        let template = language.localizedString("✅ %@ is back to operational")
        content.body = String(format: template, componentName)
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
