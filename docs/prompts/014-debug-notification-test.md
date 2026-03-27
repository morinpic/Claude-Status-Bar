# Issue #14 — Add notification test controls to debug menu

## ブランチ

`feature/14-debug-notification-test`（`main` から切る）

## 背景

F-13（コンポーネント単位の通知カスタマイズ）の手動テスト基盤として、デバッグメニューに通知テスト機能を追加する。現在のデバッグメニューは UI 状態のシミュレーションはできるが、通知の発火テストができない。

## 実装手順

### 1. `StatusViewModel.swift` にデバッグ用の通知テストメソッドを追加

`#if DEBUG` ブロック内に以下を追加する。

```swift
// 直接通知を送信（ロジックをバイパス）
func debugSendIncidentNotification() {
    notificationService.sendIncidentNotification(incidentName: "[Debug] Test incident on Claude API")
}

func debugSendRecoveryNotification() {
    notificationService.sendRecoveryNotification()
}

// ステータス遷移をシミュレーション（通知判定ロジックを通す）
func debugSimulateTransition(from: StatusIndicator, to: StatusIndicator) {
    // previousStatus を強制的にセットして、遷移をシミュレーション
    previousStatus = from

    // 遷移先に合わせたモック incidents を生成
    let incidents: [Incident]
    if to != .none {
        incidents = [DebugDataFactory.makeIncident(
            name: "[Debug] Simulated \(to.rawValue) incident",
            impact: to,
            status: .investigating
        )]
    } else {
        incidents = []
    }

    // 通知判定ロジックを通す
    checkStatusTransition(from: from, to: to, incidents: incidents)

    // UI も更新
    overallStatus = to
    activeIncidents = incidents
    lastUpdated = Date()
}
```

`checkStatusTransition` と `previousStatus` のアクセスレベルが `private` の場合は、`#if DEBUG` ブロック内からアクセスできるよう `fileprivate` または `internal` に変更する（DEBUG 時のみ外部から操作できれば良いので、最小限の変更にする）。

**注意:** `checkStatusTransition` は同じクラス内の `#if DEBUG` ブロックからの呼び出しなので、`private` のままでもアクセスできるはず。確認の上、変更が必要な場合のみアクセスレベルを調整すること。

### 2. `DebugMenuView.swift` に通知テストセクションを追加

既存の State Simulation セクションの下（Apply / Reset ボタンの後）に、通知テストセクションを追加する。

```swift
// Apply / Reset ボタンの HStack の後に追加:

Divider()
    .padding(.vertical, 4)

Text("Notification Test")
    .font(.caption)
    .fontWeight(.semibold)
    .foregroundStyle(.secondary)

// 直接送信ボタン
HStack {
    Button("📢 Incident") {
        viewModel.debugSendIncidentNotification()
    }
    .buttonStyle(.bordered)
    .controlSize(.small)

    Button("✅ Recovery") {
        viewModel.debugSendRecoveryNotification()
    }
    .buttonStyle(.bordered)
    .controlSize(.small)
}

// 遷移シミュレーション
Text("Simulate Transition")
    .font(.caption2)
    .foregroundStyle(.secondary)

VStack(alignment: .leading, spacing: 4) {
    Button("none → minor") {
        viewModel.debugSimulateTransition(from: .none, to: .minor)
    }
    Button("none → major") {
        viewModel.debugSimulateTransition(from: .none, to: .major)
    }
    Button("none → critical") {
        viewModel.debugSimulateTransition(from: .none, to: .critical)
    }
    Button("minor → none (recovery)") {
        viewModel.debugSimulateTransition(from: .minor, to: .none)
    }
    Button("major → none (recovery)") {
        viewModel.debugSimulateTransition(from: .major, to: .none)
    }
}
.buttonStyle(.link)
.font(.caption)
```

### 3. ドキュメント更新

#### `docs/CHANGELOG.md`

`[Unreleased]` セクションに追記:

```
### Added
- Notification test controls in debug menu (direct send + transition simulation)
```

#### `docs/BACKLOG.md`

「開発ツール」セクションに行を追加（取り消し線付き）:

```
| ~~D-2~~ | ~~デバッグメニューに通知テスト機能を追加~~ | ~~高~~ | ~~S~~ | ~~#14~~ |
```

## ビルド確認

- `xcodebuild -scheme ClaudeStatusBar -configuration Debug build` でビルドが通ること
- `xcodebuild -scheme ClaudeStatusBar -configuration Release build` でデバッグコードが含まれないこと

## 手動テストチェックリスト

- [ ] 「📢 Incident」ボタン → macOS 通知で「⚠ Claude で障害が発生しました: [Debug] Test incident on Claude API」が表示される
- [ ] 「✅ Recovery」ボタン → macOS 通知で「✅ Claude は復旧しました」が表示される
- [ ] 「none → minor」ボタン → 通知が発火し、ヘッダーが「Minor Issues」に変わる
- [ ] 「none → critical」ボタン → 通知が発火し、ヘッダーが「Critical Outage」に変わる
- [ ] 「major → none (recovery)」ボタン → 復旧通知が発火し、ヘッダーが「All Systems Operational」に変わる
- [ ] 通知はアプリがフォアグラウンドでもバナー表示される（既存の delegate 設定による）
- [ ] Release ビルドで通知テスト UI が表示されない
