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

    /// 指定言語の .lproj バンドルを返す。system の場合は nil（デフォルト動作）
    var bundle: Bundle? {
        guard self != .system else { return nil }
        guard let path = Bundle.main.path(forResource: rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return nil
        }
        return bundle
    }

    /// 指定言語でローカライズされた文字列を返す
    func localizedString(_ key: String) -> String {
        guard let bundle else {
            return String(localized: String.LocalizationValue(key))
        }
        return bundle.localizedString(forKey: key, value: nil, table: "Localizable")
    }
}
