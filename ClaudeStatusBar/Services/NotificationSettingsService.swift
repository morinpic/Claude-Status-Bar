import Foundation

final class NotificationSettingsService {
    static let shared = NotificationSettingsService()

    private let userDefaults = UserDefaults.standard
    private let enabledComponentsKey = "notificationEnabledComponents"

    private init() {}

    /// 通知が有効なコンポーネント ID のセットを取得
    /// 設定がない場合（初回起動）は nil を返す = 全コンポーネント通知
    func enabledComponentIDs() -> Set<String>? {
        guard let array = userDefaults.array(forKey: enabledComponentsKey) as? [String] else {
            return nil
        }
        return Set(array)
    }

    /// コンポーネントの通知が有効かどうか
    func isNotificationEnabled(for componentID: String) -> Bool {
        guard let enabled = enabledComponentIDs() else {
            return true
        }
        return enabled.contains(componentID)
    }

    /// コンポーネントの通知設定を更新
    func setNotificationEnabled(_ enabled: Bool, for componentID: String) {
        var currentSet: Set<String>
        if let existing = enabledComponentIDs() {
            currentSet = existing
        } else {
            currentSet = Set<String>()
        }

        if enabled {
            currentSet.insert(componentID)
        } else {
            currentSet.remove(componentID)
        }

        userDefaults.set(Array(currentSet), forKey: enabledComponentsKey)
    }

    /// 全コンポーネント ID を渡して初期化（初回のみ）
    /// 既に設定がある場合は何もしない
    func initializeIfNeeded(allComponentIDs: [String]) {
        guard userDefaults.array(forKey: enabledComponentsKey) == nil else { return }
        userDefaults.set(allComponentIDs, forKey: enabledComponentsKey)
    }
}
