import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case en = "en"
    case ja = "ja"

    var id: String { rawValue }

    var localizedDisplayName: LocalizedStringResource {
        switch self {
        case .system: return "System Default"
        case .en: return "English"
        case .ja: return "日本語"
        }
    }

    var locale: Locale? {
        switch self {
        case .system: return nil
        case .en: return Locale(identifier: "en")
        case .ja: return Locale(identifier: "ja")
        }
    }
}
