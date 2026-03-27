# Issue #11 — Add debug menu for state simulation (DEBUG builds only)

## ブランチ

`feature/11-debug-menu`（`main` から切る）

## 背景

手動テストのたびに実際の API 障害状態を待つのは非現実的。DEBUG ビルド限定のデバッグメニューを追加して、すべての UI 状態を即座にシミュレーションできるようにする。今後の UI 開発（F-33 含む）の手動テスト基盤として使う。

## 実装手順

### 1. `DebugPreset.swift` を新規作成（`ClaudeStatusBar/Debug/`）

デバッグ用のプリセットデータを定義する。ファイル全体を `#if DEBUG` で囲む。

```swift
#if DEBUG
import Foundation

enum DebugStatusPreset: String, CaseIterable {
    case live = "Live (API)"
    case operational = "All Operational"
    case minor = "Minor Issues"
    case major = "Major Outage"
    case critical = "Critical Outage"
}

enum DebugIncidentPreset: String, CaseIterable {
    case none = "No Incidents"
    case singleMinor = "1 Incident (minor)"
    case singleMajor = "1 Incident (major)"
    case multiple = "Multiple Incidents"
}

enum DebugComponentPreset: String, CaseIterable {
    case allOperational = "All Operational"
    case someDegraded = "Some Degraded"
    case partialOutage = "Partial Outage"
    case majorOutage = "Major Outage"
    case mixed = "Mixed States"
}

enum DebugErrorPreset: String, CaseIterable {
    case none = "No Error"
    case networkError = "Network Error"
    case httpError = "HTTP Error (500)"
}

struct DebugDataFactory {

    static func makeComponents(preset: DebugComponentPreset) -> [Component] {
        let names = ["claude.ai", "Claude API", "Claude Code", "platform.claude.com", "Claude for Government"]
        let statuses: [ComponentStatus]

        switch preset {
        case .allOperational:
            statuses = Array(repeating: .operational, count: names.count)
        case .someDegraded:
            statuses = [.operational, .degradedPerformance, .operational, .degradedPerformance, .operational]
        case .partialOutage:
            statuses = [.operational, .partialOutage, .operational, .operational, .operational]
        case .majorOutage:
            statuses = [.majorOutage, .majorOutage, .operational, .operational, .operational]
        case .mixed:
            statuses = [.operational, .degradedPerformance, .partialOutage, .majorOutage, .operational]
        }

        return names.enumerated().map { index, name in
            Component(
                id: "debug-\(index)",
                name: name,
                status: statuses[index],
                createdAt: Date(),
                updatedAt: Date(),
                position: index,
                description: nil,
                showcase: true,
                startDate: nil,
                groupId: nil,
                pageId: "debug-page",
                group: false,
                onlyShowIfDegraded: false
            )
        }
    }

    static func makeIncidents(preset: DebugIncidentPreset) -> [Incident] {
        switch preset {
        case .none:
            return []
        case .singleMinor:
            return [makeIncident(name: "Elevated error rates on Claude API", impact: .minor, status: .investigating)]
        case .singleMajor:
            return [makeIncident(name: "Claude.ai is experiencing downtime", impact: .major, status: .identified)]
        case .multiple:
            return [
                makeIncident(name: "Claude.ai is experiencing downtime", impact: .major, status: .identified),
                makeIncident(name: "Elevated error rates on Claude API", impact: .minor, status: .monitoring)
            ]
        }
    }

    static func makeIncident(name: String, impact: StatusIndicator, status: IncidentStatus) -> Incident {
        let update = IncidentUpdate(
            id: UUID().uuidString,
            status: status,
            body: "We are currently investigating this issue. Updates will be provided as available.",
            createdAt: Date().addingTimeInterval(-300),
            affectedComponents: nil
        )
        return Incident(
            id: UUID().uuidString,
            name: name,
            status: status,
            impact: impact,
            createdAt: Date().addingTimeInterval(-600),
            updatedAt: Date().addingTimeInterval(-300),
            incidentUpdates: [update]
        )
    }

    static func makeError(preset: DebugErrorPreset) -> Error? {
        switch preset {
        case .none:
            return nil
        case .networkError:
            return URLError(.notConnectedToInternet)
        case .httpError:
            return StatusServiceError.httpError(statusCode: 500)
        }
    }
}
#endif
```

### 2. `StatusViewModel.swift` にデバッグ用メソッドを追加

`#if DEBUG` で囲んだデバッグ用のプロパティとメソッドを追加する。

```swift
// StatusViewModel.swift の末尾、クラス定義の閉じ括弧の直前に追加:

#if DEBUG
var isDebugMode = false

func applyDebugState(
    statusPreset: DebugStatusPreset,
    incidentPreset: DebugIncidentPreset,
    componentPreset: DebugComponentPreset,
    errorPreset: DebugErrorPreset,
    isLoadingOverride: Bool
) {
    if statusPreset == .live {
        exitDebugMode()
        return
    }

    isDebugMode = true
    stopMonitoring()

    let statusIndicator: StatusIndicator
    switch statusPreset {
    case .live: return // handled above
    case .operational: statusIndicator = .none
    case .minor: statusIndicator = .minor
    case .major: statusIndicator = .major
    case .critical: statusIndicator = .critical
    }

    overallStatus = statusIndicator
    activeIncidents = DebugDataFactory.makeIncidents(preset: incidentPreset)
    components = DebugDataFactory.makeComponents(preset: componentPreset)
    error = DebugDataFactory.makeError(preset: errorPreset)
    isLoading = isLoadingOverride
    lastUpdated = Date()
}

func exitDebugMode() {
    isDebugMode = false
    error = nil
    isLoading = false
    startMonitoring()
}
#endif
```

### 3. `DebugMenuView.swift` を新規作成（`ClaudeStatusBar/Debug/`）

ファイル全体を `#if DEBUG` で囲む。

```swift
#if DEBUG
import SwiftUI

struct DebugMenuView: View {
    @Bindable var viewModel: StatusViewModel
    @State private var isExpanded = false
    @State private var statusPreset: DebugStatusPreset = .live
    @State private var incidentPreset: DebugIncidentPreset = .none
    @State private var componentPreset: DebugComponentPreset = .allOperational
    @State private var errorPreset: DebugErrorPreset = .none
    @State private var isLoadingOverride = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ヘッダー（タップで展開/折りたたみ）
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("🐛 Debug")
                        .font(.caption)
                        .fontWeight(.semibold)
                    if viewModel.isDebugMode {
                        Text("ON")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    // Status
                    Picker("Status", selection: $statusPreset) {
                        ForEach(DebugStatusPreset.allCases, id: \.self) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)
                    .controlSize(.small)

                    // Incidents
                    Picker("Incidents", selection: $incidentPreset) {
                        ForEach(DebugIncidentPreset.allCases, id: \.self) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)
                    .controlSize(.small)

                    // Components
                    Picker("Components", selection: $componentPreset) {
                        ForEach(DebugComponentPreset.allCases, id: \.self) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)
                    .controlSize(.small)

                    // Error
                    Picker("Error", selection: $errorPreset) {
                        ForEach(DebugErrorPreset.allCases, id: \.self) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)
                    .controlSize(.small)

                    // Loading
                    Toggle("Loading", isOn: $isLoadingOverride)
                        .toggleStyle(.switch)
                        .controlSize(.small)

                    // Apply / Reset
                    HStack {
                        Button("Apply") {
                            viewModel.applyDebugState(
                                statusPreset: statusPreset,
                                incidentPreset: incidentPreset,
                                componentPreset: componentPreset,
                                errorPreset: errorPreset,
                                isLoadingOverride: isLoadingOverride
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Button("Reset to Live") {
                            statusPreset = .live
                            incidentPreset = .none
                            componentPreset = .allOperational
                            errorPreset = .none
                            isLoadingOverride = false
                            viewModel.exitDebugMode()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }
        }
    }
}
#endif
```

### 4. `StatusMenuView.swift` にデバッグメニューを組み込む

`body` の中で、footerSection の直前にデバッグメニューを追加する。

```swift
// body の VStack 内、footerSection の直前に追加:

#if DEBUG
Divider()
DebugMenuView(viewModel: viewModel)
#endif
```

### 5. プロジェクトファイルに新規ファイルを登録

- `ClaudeStatusBar/Debug/DebugPreset.swift`
- `ClaudeStatusBar/Debug/DebugMenuView.swift`

を Xcode プロジェクトに追加する。`ClaudeStatusBar` ターゲットに含めること。

### 6. ドキュメント更新

#### `docs/CHANGELOG.md`

`[Unreleased]` セクションに追記:

```
### Added
- Debug menu for state simulation in DEBUG builds (status, incidents, components, errors, loading)
```

#### `docs/BACKLOG.md`

「開発ツール」セクションを新設し、以下の行を追加（取り消し線付き）:

```
## 開発ツール

| # | 内容 | 優先度 | サイズ | Issue |
|---|------|--------|--------|-------|
| ~~D-1~~ | ~~DEBUG ビルド限定のデバッグメニュー（状態シミュレーション）~~ | ~~高~~ | ~~S~~ | ~~#11~~ |
```

※ 「CI / インフラ」セクションの直前に配置する。

#### `CLAUDE.md`

プロジェクト構成に `Debug/` ディレクトリを追記:

```
├── Debug/                            # DEBUG ビルド限定（#if DEBUG）
│   ├── DebugPreset.swift             # デバッグ用プリセットデータ
│   └── DebugMenuView.swift           # デバッグメニュー UI
```

## ビルド確認

- `xcodebuild -scheme ClaudeStatusBar -configuration Debug build` でビルドが通ること
- `xcodebuild -scheme ClaudeStatusBar -configuration Release build` でデバッグメニュー関連コードが含まれないこと

## 手動テストチェックリスト

- [ ] DEBUG ビルドでポップオーバーに「🐛 Debug」セクションが表示される
- [ ] 折りたたみ/展開が動作する
- [ ] 各 Picker で選択 → Apply でステータスが即座に反映される
- [ ] Status を各レベルに変更 → ヘッダーバッジの色とテキストが正しい
- [ ] Incidents プリセット選択 → Active Incidents セクションに反映される
- [ ] Components プリセット選択 → コンポーネント一覧に反映される
- [ ] Error プリセット選択 → エラーセクションが表示される
- [ ] Loading ON → ProgressView が表示される
- [ ] Debug ON 中は「ON」バッジが赤く表示される
- [ ] 「Reset to Live」で API ポーリングに復帰し、実際のステータスが表示される
- [ ] Release ビルドでデバッグメニューが表示されない
