import Foundation

enum NotificationLevel: String, CaseIterable, Identifiable {
    case simple = "simple"
    case detailed = "detailed"

    var id: String { rawValue }

    var localizedDisplayName: LocalizedStringResource {
        switch self {
        case .simple: return "Simple"
        case .detailed: return "Detailed"
        }
    }
}
