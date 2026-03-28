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

    func sendIncidentNotification(incidentName: String, language: AppLanguage, iconDesign: IconDesignType) {
        let prefix: String
        switch iconDesign {
        case .statusIcons: prefix = "[ ! ]"
        case .classic: prefix = "🔴"
        case .vibe: prefix = "😰"
        }

        let content = UNMutableNotificationContent()
        content.title = "Claude Status"
        let template = language.localizedString("Incident: %@")
        content.body = "\(prefix) " + String(format: template, incidentName)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "incident-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    func sendRecoveryNotification(language: AppLanguage, iconDesign: IconDesignType) {
        let prefix: String
        switch iconDesign {
        case .statusIcons: prefix = "[✓]"
        case .classic: prefix = "🟢"
        case .vibe: prefix = "😊"
        }

        let content = UNMutableNotificationContent()
        content.title = "Claude Status"
        content.body = "\(prefix) " + language.localizedString("All systems operational")
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "recovery-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    func sendComponentIncidentNotification(componentName: String, status: ComponentStatus, language: AppLanguage, iconDesign: IconDesignType) {
        let prefix: String
        switch iconDesign {
        case .statusIcons:
            prefix = "[ ! ]"
        case .classic:
            switch status {
            case .degradedPerformance: prefix = "🟡"
            case .partialOutage: prefix = "🟠"
            case .majorOutage: prefix = "🔴"
            case .operational: return
            }
        case .vibe:
            switch status {
            case .degradedPerformance: prefix = "😟"
            case .partialOutage: prefix = "😰"
            case .majorOutage: prefix = "💀"
            case .operational: return
            }
        }

        let statusText: String
        switch status {
        case .operational: return
        case .degradedPerformance: statusText = language.localizedString("degraded performance")
        case .partialOutage: statusText = language.localizedString("partial outage")
        case .majorOutage: statusText = language.localizedString("major outage")
        }

        let content = UNMutableNotificationContent()
        content.title = "Claude Status"
        content.body = "\(prefix) \(componentName): \(statusText)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "component-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    func sendComponentRecoveryNotification(componentName: String, language: AppLanguage, iconDesign: IconDesignType) {
        let prefix: String
        switch iconDesign {
        case .statusIcons: prefix = "[✓]"
        case .classic: prefix = "🟢"
        case .vibe: prefix = "😊"
        }

        let content = UNMutableNotificationContent()
        content.title = "Claude Status"
        let template = language.localizedString("%@: Operational")
        content.body = "\(prefix) " + String(format: template, componentName)
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
