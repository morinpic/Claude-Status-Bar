import Foundation

enum PollingInterval: Int, CaseIterable, Identifiable {
    case fifteen = 15
    case thirty = 30
    case sixty = 60
    case onetwenty = 120
    case threehundred = 300

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .fifteen: return "15s"
        case .thirty: return "30s"
        case .sixty: return "60s"
        case .onetwenty: return "2min"
        case .threehundred: return "5min"
        }
    }

    var timeInterval: TimeInterval {
        TimeInterval(rawValue)
    }
}
