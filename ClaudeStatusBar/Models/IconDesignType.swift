import Foundation

enum IconDesignType: String, CaseIterable, Identifiable {
    case statusIcons = "statusIcons"
    case classic = "classic"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .statusIcons: return "Status Icons"
        case .classic: return "Classic"
        }
    }
}
