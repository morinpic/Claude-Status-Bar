# 設定ウィンドウの分離（F-13 ブランチ追加作業）

## ブランチ

`feature/f13-notification-settings`（既存ブランチに追加コミット）

## 背景

ポップオーバーに Icon Design、Notification Settings、Launch at Login、Debug メニューが詰め込まれて縦に長くなりすぎている。ポップオーバーはステータス確認に集中させ、設定は別ウィンドウに分離する。今後の設定追加（ポーリング間隔カスタマイズ等）の土台にもなる。

## 設計方針

- macOS の `Settings` scene を使用する（macOS 14+ の標準 Settings ウィンドウ）
- ポップオーバーからは ⚙ ボタンで設定ウィンドウを開く
- タブ構成: **General** / **Notifications**
- ポップオーバーから移動する項目: Icon Design、Notification Settings、Launch at Login
- ポップオーバーに残す項目: ステータス表示、コンポーネント一覧、インシデント、Last checked、リンク類、Quit
- Debug メニューはポップオーバーに残す（開発中のステータス確認と合わせて使うため）

## 実装手順

### 1. `SettingsView.swift` を新規作成（`ClaudeStatusBar/Views/`）

```swift
import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: StatusViewModel

    var body: some View {
        TabView {
            GeneralSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            NotificationSettingsTab(viewModel: viewModel)
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
        }
        .frame(width: 360, height: 300)
    }
}
```

### 2. `GeneralSettingsView.swift` を新規作成（`ClaudeStatusBar/Views/`）

Launch at Login と Icon Design を含む。既存の `IconSettingsView` のコンテンツを設定ウィンドウ向けにレイアウト調整する。

```swift
import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
    @Bindable var viewModel: StatusViewModel
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
            }

            Section("Icon Design") {
                // IconSettingsView のコンテンツを Form 向けに調整
                // Picker を使うか、既存の一覧スタイルを維持するかは任意
                Picker("Menu Bar Icon", selection: $viewModel.selectedIconDesignRaw) {
                    ForEach(IconDesignType.allCases, id: \.self) { design in
                        Label {
                            Text(design.displayName)
                        } icon: {
                            iconPreview(for: design)
                        }
                        .tag(design.rawValue)
                    }
                }
                .pickerStyle(.radioGroup)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    @ViewBuilder
    private func iconPreview(for design: IconDesignType) -> some View {
        if design == .default {
            Image(systemName: "circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 14))
        } else {
            Image(design.assetName(for: .normal))
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
        }
    }
}
```

### 3. `NotificationSettingsView.swift` を修正

ポップオーバー用の折りたたみ UI から、設定ウィンドウのタブ用に変更する。

ファイル名を `NotificationSettingsView.swift` のまま、中身を設定ウィンドウ向けのタブコンテンツに書き換える。

```swift
import SwiftUI

struct NotificationSettingsTab: View {
    @Bindable var viewModel: StatusViewModel

    var body: some View {
        Form {
            Section {
                Text("Choose which components trigger desktop notifications when their status changes.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Components") {
                ForEach(viewModel.components) { component in
                    Toggle(
                        component.name,
                        isOn: Binding(
                            get: { viewModel.isComponentNotificationEnabled(component.id) },
                            set: { viewModel.toggleComponentNotification(component.id, enabled: $0) }
                        )
                    )
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
```

**注意:** 旧 `NotificationSettingsView`（ポップオーバー用の折りたたみ版）は不要になるので削除する。`ComponentNotificationToggle` も不要。

### 4. `ClaudeStatusBarApp.swift` に Settings scene を追加

```swift
@main
struct ClaudeStatusBarApp: App {
    @State private var viewModel = StatusViewModel()

    var body: some Scene {
        MenuBarExtra {
            StatusMenuView(viewModel: viewModel)
        } label: {
            // 既存のラベルコードはそのまま
            if let nsImage = menuBarCustomIcon {
                Image(nsImage: nsImage)
            } else {
                Image(systemName: viewModel.menuBarIcon)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(menuBarIconColor)
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(viewModel: viewModel)
        }
    }

    // 既存の private computed properties はそのまま
}
```

### 5. `StatusMenuView.swift` を整理

ポップオーバーから設定関連を削除し、⚙ ボタンを追加する。

**削除するセクション:**
- `iconDesignSection`（Icon Design）
- `NotificationSettingsView`（Notification Settings）
- `launchAtLogin` の Toggle と `@State private var launchAtLogin`

**footer セクションの修正:**

Last checked の横に ⚙ アイコンを追加し、設定ウィンドウを開くボタンにする。

```swift
// footerSection 内の HStack（Last checked の行）を修正:
HStack {
    if let lastUpdated = viewModel.lastUpdated {
        Text("Last checked: \(lastUpdated.formatted(date: .omitted, time: .shortened))")
            .font(.caption2)
            .foregroundStyle(.tertiary)
    }
    Spacer()

    // 設定ウィンドウを開くボタン
    Button {
        openSettings()
    } label: {
        Image(systemName: "gear")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .buttonStyle(.plain)
    .help("Open Settings")

    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")")
        .font(.caption2)
        .foregroundStyle(.tertiary)
}
.padding(.horizontal, 14)
```

**設定ウィンドウを開くヘルパー:**

macOS 14+ では `SettingsLink` を使うか、`NSApp.sendAction` で設定を開く。MenuBarExtra 内では `SettingsLink` が使えない場合があるので、以下のアプローチを使う:

```swift
private func openSettings() {
    // macOS 14+
    if #available(macOS 14, *) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    } else {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
}
```

**注意:** `@State private var launchAtLogin` を削除すること。`ServiceManagement` の import も不要であれば削除。

### 6. 不要になったファイルの整理

- `IconSettingsView.swift` — 設定ウィンドウの `GeneralSettingsView` に統合されるため削除
- `NotificationSettingsView.swift` 内の旧コード（折りたたみ UI）を `NotificationSettingsTab` に置き換え

### 7. プロジェクトファイル更新

- 新規ファイルを追加: `SettingsView.swift`, `GeneralSettingsView.swift`
- 削除があれば反映（`IconSettingsView.swift` 削除の場合）
- `NotificationSettingsView.swift` のリネームまたは内容差し替え

### 8. ドキュメント更新

#### `docs/CHANGELOG.md`

`[Unreleased]` セクションに追記:

```
### Changed
- Move Icon Design, Notification Settings, and Launch at Login to dedicated Settings window
- Add gear icon button in popover footer to open Settings
```

#### `CLAUDE.md`

プロジェクト構成を更新:

```
├── Views/
│   ├── StatusMenuView.swift          # ポップオーバー（ステータス表示）
│   ├── ComponentRow.swift            # コンポーネント1行分
│   ├── IncidentCard.swift            # インシデント詳細カード
│   ├── SettingsView.swift            # 設定ウィンドウ（タブ: General / Notifications）
│   ├── GeneralSettingsView.swift     # 設定: Icon Design + Launch at Login
│   └── NotificationSettingsView.swift # 設定: コンポーネント通知設定
```

## ビルド確認

- `xcodebuild -scheme ClaudeStatusBar -configuration Debug build` でビルドが通ること
- `xcodebuild -scheme ClaudeStatusBar -configuration Debug test` で全テストパスすること

## 手動テストチェックリスト

### ポップオーバー
- [ ] Icon Design セクションが表示されない
- [ ] Notification Settings セクションが表示されない
- [ ] Launch at Login トグルが表示されない
- [ ] ⚙ ボタンが Last checked の横に表示される
- [ ] ⚙ ボタンクリックで設定ウィンドウが開く
- [ ] Debug メニューは引き続きポップオーバーに表示される（DEBUG ビルドのみ）

### 設定ウィンドウ
- [ ] General タブ: Launch at Login トグルが動作する
- [ ] General タブ: Icon Design の選択が反映される（メニューバーアイコンが変わる）
- [ ] Notifications タブ: 全コンポーネントのトグルが表示される
- [ ] Notifications タブ: トグルの ON/OFF が保持される
- [ ] 設定ウィンドウを閉じても設定が保持される
- [ ] 設定変更がポップオーバーの表示にリアルタイムで反映される
