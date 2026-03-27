# Issue #16 — Add per-component notification settings (F-13)

## ブランチ

`feature/16-per-component-notification`（`main` から切る）

## 背景

現在の通知は全体ステータスの変化（正常→障害、障害→復旧）のみ。ユーザーが「Claude API だけ通知してほしい」「Claude for Government は関係ないから通知いらない」といった設定ができるようにする。

## 設計方針

- **全体ステータス通知はそのまま残す**（既存動作を壊さない）
- コンポーネント単位の通知を**追加**する
- デフォルトは全コンポーネント ON
- 設定は `UserDefaults` に永続化

## 実装手順

### 1. `NotificationSettingsService.swift` を新規作成（`ClaudeStatusBar/Services/`）

通知設定の永続化を担当するサービス。

```swift
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
            return nil // 未設定 = 全 ON
        }
        return Set(array)
    }

    /// コンポーネントの通知が有効かどうか
    func isNotificationEnabled(for componentID: String) -> Bool {
        guard let enabled = enabledComponentIDs() else {
            return true // 未設定 = 全 ON
        }
        return enabled.contains(componentID)
    }

    /// コンポーネントの通知設定を更新
    func setNotificationEnabled(_ enabled: Bool, for componentID: String) {
        var currentSet: Set<String>
        if let existing = enabledComponentIDs() {
            currentSet = existing
        } else {
            // 初回: 現在の全コンポーネント ID は呼び出し側から渡してもらう必要がある
            // → toggleNotification で allComponentIDs を渡す設計にする
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
```

### 2. `StatusViewModel.swift` を修正

#### 2a. プロパティ追加

```swift
// 既存のプロパティの近くに追加
private let notificationSettings = NotificationSettingsService.shared
private var previousComponentStatuses: [String: ComponentStatus] = [:]
```

#### 2b. `apply()` メソッドにコンポーネント単位の通知ロジックを追加

`apply()` 内で、コンポーネント一覧をセットした後に以下のロジックを追加:

```swift
// コンポーネント一覧が確定した後
// 通知設定を初期化（初回のみ）
let filteredComponents = summary.components
    .filter { !$0.group }
    .sorted { $0.position < $1.position }
notificationSettings.initializeIfNeeded(allComponentIDs: filteredComponents.map { $0.id })

// コンポーネント単位のステータス変化を検知して通知
checkComponentTransitions(newComponents: filteredComponents)

// previousComponentStatuses を更新
previousComponentStatuses = Dictionary(
    uniqueKeysWithValues: filteredComponents.map { ($0.id, $0.status) }
)

components = filteredComponents
```

#### 2c. コンポーネント単位の通知判定メソッドを追加

```swift
private func checkComponentTransitions(newComponents: [Component]) {
    guard !previousComponentStatuses.isEmpty else { return } // 初回は通知しない

    for component in newComponents {
        guard notificationSettings.isNotificationEnabled(for: component.id) else { continue }

        let previousStatus = previousComponentStatuses[component.id]

        // operational → non-operational: 障害通知
        if previousStatus == .operational && component.status != .operational {
            notificationService.sendComponentIncidentNotification(
                componentName: component.name,
                status: component.status
            )
        }
        // non-operational → operational: 復旧通知
        else if previousStatus != nil && previousStatus != .operational && component.status == .operational {
            notificationService.sendComponentRecoveryNotification(componentName: component.name)
        }
    }
}
```

#### 2d. 通知設定の UI 用プロパティ

```swift
/// コンポーネントの通知が有効かどうかを取得
func isComponentNotificationEnabled(_ componentID: String) -> Bool {
    notificationSettings.isNotificationEnabled(for: componentID)
}

/// コンポーネントの通知設定を切り替え
func toggleComponentNotification(_ componentID: String, enabled: Bool) {
    notificationSettings.setNotificationEnabled(enabled, for: componentID)
}
```

### 3. `NotificationService.swift` にコンポーネント単位の通知メソッドを追加

```swift
func sendComponentIncidentNotification(componentName: String, status: ComponentStatus) {
    let statusText: String
    switch status {
    case .operational: return // 通知不要
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

func sendComponentRecoveryNotification(componentName: String) {
    let content = UNMutableNotificationContent()
    content.title = "Claude Status"
    content.body = "✅ \(componentName) is back to operational"
    content.sound = .default

    let request = UNNotificationRequest(
        identifier: "component-recovery-\(UUID().uuidString)",
        content: content,
        trigger: nil
    )
    center.add(request)
}
```

### 4. `NotificationSettingsView.swift` を新規作成（`ClaudeStatusBar/Views/`）

```swift
import SwiftUI

struct NotificationSettingsView: View {
    @Bindable var viewModel: StatusViewModel
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Notification Settings")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            if isExpanded {
                VStack(spacing: 4) {
                    ForEach(viewModel.components) { component in
                        ComponentNotificationToggle(
                            componentName: component.name,
                            isEnabled: viewModel.isComponentNotificationEnabled(component.id),
                            onToggle: { enabled in
                                viewModel.toggleComponentNotification(component.id, enabled: enabled)
                            }
                        )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }
        }
    }
}

struct ComponentNotificationToggle: View {
    let componentName: String
    let isEnabled: Bool
    let onToggle: (Bool) -> Void

    @State private var toggleState: Bool

    init(componentName: String, isEnabled: Bool, onToggle: @escaping (Bool) -> Void) {
        self.componentName = componentName
        self.isEnabled = isEnabled
        self.onToggle = onToggle
        self._toggleState = State(initialValue: isEnabled)
    }

    var body: some View {
        Toggle(componentName, isOn: $toggleState)
            .toggleStyle(.switch)
            .controlSize(.mini)
            .font(.caption)
            .onChange(of: toggleState) { _, newValue in
                onToggle(newValue)
            }
    }
}
```

### 5. `StatusMenuView.swift` に通知設定セクションを組み込む

Icon Design セクションの後（Debug メニューの前）に追加:

```swift
// iconDesignSection の後に追加:
Divider()
NotificationSettingsView(viewModel: viewModel)
```

### 6. プロジェクトファイルに新規ファイルを登録

- `ClaudeStatusBar/Services/NotificationSettingsService.swift`
- `ClaudeStatusBar/Views/NotificationSettingsView.swift`

を Xcode プロジェクトに追加する。`ClaudeStatusBar` ターゲットに含めること。

### 7. テストを追加

`NotificationSettingsServiceTests.swift` を新規作成:

- 初期状態（未設定）で `isNotificationEnabled` が `true` を返すこと
- `initializeIfNeeded` で全コンポーネント ID がセットされること
- `setNotificationEnabled(false)` で特定コンポーネントが無効になること
- `setNotificationEnabled(true)` で再度有効になること
- 2回目の `initializeIfNeeded` が既存設定を上書きしないこと

`StatusViewModelTests.swift` に追加（または新ファイル）:

- コンポーネントが operational → degraded になったとき、通知対象なら通知が発火すること
- コンポーネントが operational → degraded になったとき、通知対象外なら通知が発火しないこと
- コンポーネントが degraded → operational に復旧したとき、復旧通知が発火すること
- 初回取得時はコンポーネント単位の通知が発火しないこと

**注意:** `NotificationService` をモック化してテストする。テスト用のプロトコル `NotificationServiceProtocol` を導入するか、通知の発火回数をカウントできるスパイクラスを使う。

### 8. デバッグメニューにコンポーネント通知テストを追加

`DebugMenuView.swift` の Notification Test セクションに、コンポーネント単位の通知テストボタンを追加:

```swift
// 既存の Simulate Transition セクションの後に追加:

Text("Component Notification")
    .font(.caption2)
    .foregroundStyle(.secondary)

Button("Claude API: operational → partial_outage") {
    viewModel.debugSimulateComponentTransition(
        componentName: "Claude API",
        from: .operational,
        to: .partialOutage
    )
}
.buttonStyle(.link)
.font(.caption)

Button("Claude API: partial_outage → operational") {
    viewModel.debugSimulateComponentTransition(
        componentName: "Claude API",
        from: .partialOutage,
        to: .operational
    )
}
.buttonStyle(.link)
.font(.caption)
```

`StatusViewModel.swift` の `#if DEBUG` ブロックに追加:

```swift
func debugSimulateComponentTransition(
    componentName: String,
    from oldStatus: ComponentStatus,
    to newStatus: ComponentStatus
) {
    // 対象コンポーネントを見つけて状態を変更
    guard let index = components.firstIndex(where: { $0.name == componentName }) else { return }
    let component = components[index]

    // previousComponentStatuses を強制セット
    previousComponentStatuses[component.id] = oldStatus

    // 新しいステータスのコンポーネントを作成
    let updatedComponent = Component(
        id: component.id,
        name: component.name,
        status: newStatus,
        createdAt: component.createdAt,
        updatedAt: Date(),
        position: component.position,
        description: component.description,
        showcase: component.showcase,
        startDate: component.startDate,
        groupId: component.groupId,
        pageId: component.pageId,
        group: component.group,
        onlyShowIfDegraded: component.onlyShowIfDegraded
    )

    // 通知判定を実行
    checkComponentTransitions(newComponents: [updatedComponent])

    // UI を更新
    components[index] = updatedComponent
    lastUpdated = Date()
}
```

`checkComponentTransitions` のアクセスレベルは `private` のままで OK（同じクラス内の `#if DEBUG` ブロックからアクセス可能）。

### 9. ドキュメント更新

#### `docs/CHANGELOG.md`

`[Unreleased]` セクションに追記:

```
### Added
- Per-component notification settings — choose which components trigger notifications
- Component-level status change notifications (individual component outage/recovery)
```

#### `docs/BACKLOG.md`

F-13 の行に取り消し線を付け、Issue 列に `#16` を記載。

#### `CLAUDE.md`

プロジェクト構成の Services セクションに追記:

```
│   ├── NotificationSettingsService.swift # コンポーネント通知設定の永続化
```

Views セクションに追記:

```
│   ├── NotificationSettingsView.swift    # 通知設定 UI
```

## ビルド確認

- `xcodebuild -scheme ClaudeStatusBar -configuration Debug build` でビルドが通ること
- `xcodebuild -scheme ClaudeStatusBar -configuration Debug test` で全テストパスすること

## 手動テストチェックリスト（デバッグメニュー使用）

### 通知設定 UI
- [ ] ポップオーバーに「Notification Settings」セクションが表示される
- [ ] 折りたたみ/展開が動作する
- [ ] 全コンポーネントのトグルが表示される
- [ ] デフォルトで全トグルが ON
- [ ] トグルを OFF にして、アプリを再起動しても設定が保持される

### コンポーネント通知
- [ ] デバッグメニュー「Claude API: operational → partial_outage」→ 「⚠ Claude API: partial outage」通知が飛ぶ
- [ ] デバッグメニュー「Claude API: partial_outage → operational」→ 「✅ Claude API is back to operational」通知が飛ぶ
- [ ] Claude API の通知を OFF → 同じ遷移を実行 → 通知が飛ばないこと
- [ ] Claude API の通知を再度 ON → 遷移実行 → 通知が飛ぶこと

### 全体ステータス通知との共存
- [ ] 全体ステータスの遷移通知（none → minor 等）が引き続き動作すること
- [ ] コンポーネント通知と全体通知が同時に飛んでも問題ないこと
