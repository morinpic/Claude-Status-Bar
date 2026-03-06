import Foundation
import UserNotifications

protocol NotificationServiceProtocol: AnyObject {
    func requestAuthorization()
    func sendIncidentNotification(incidentName: String, impact: StatusIndicator, affectedCount: Int)
    func sendRecoveryNotification()
}

final class NotificationService: NSObject, UNUserNotificationCenterDelegate, NotificationServiceProtocol {
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

    func sendIncidentNotification(incidentName: String, impact: StatusIndicator, affectedCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Claude Status — 障害を検知"
        content.subtitle = switch impact {
        case .critical: "重大"
        case .major:    "重要"
        default:        "軽微"
        }
        content.body = "\(incidentName)。影響: \(affectedCount) コンポーネント"
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
