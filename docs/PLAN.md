# Claude Status Bar — Project Plan

> Never miss a Claude outage.

macOS のメニューバーに常駐し、Claude のサービスステータスを監視してインシデント発生時にリアルタイムで通知する軽量アプリ。

## 1. プロジェクト概要

| 項目 | 内容 |
|------|------|
| アプリ名 | Claude Status Bar |
| リポジトリ名 | claude-status-bar |
| プラットフォーム | macOS 14.0+ (Sonoma) |
| 技術スタック | Swift + SwiftUI |
| データソース | Statuspage REST API（認証不要） |
| 配布方法 | Homebrew Cask（自前 Tap → 将来的に公式 Cask へ PR） |
| 開発体制 | Claude Code（Agent Teams）、サブエージェントは Opus モデルを使用 |
| ライセンス | MIT |

## 2. MVP 機能

### 2.1 メニューバーアイコン表示

- `SF Symbols` を使い、ステータスに応じた色付き丸アイコンを表示
  - `none` → 🟢 緑（All Systems Operational）
  - `minor` → 🟡 黄（一部で軽微な問題）
  - `major` → 🟠 オレンジ（主要な障害）
  - `critical` → 🔴 赤（重大障害）

### 2.2 障害時のデスクトップ通知

- ステータスが `none` → それ以外に変化したとき：「⚠ Claude で障害が発生しました: {インシデント名}」
- ステータスが `none` に戻ったとき：「✅ Claude は復旧しました」
- `UNUserNotificationCenter` を使用

### 2.3 コンポーネント別ステータス表示

ポップオーバーに以下のコンポーネントの個別ステータスを表示：

- claude.ai
- Claude API (api.anthropic.com)
- Claude Code
- platform.claude.com
- Claude for Government

各コンポーネントのステータス値：`operational` / `degraded_performance` / `partial_outage` / `major_outage`

### 2.4 インシデント詳細表示

進行中のインシデントがある場合、ポップオーバー内にカード形式で表示：

- インシデント名
- 影響度（minor / major / critical）
- 現在のステータス（investigating / identified / monitoring / resolved）
- 最終更新日時
- 最新の更新メッセージ

## 3. API 設計

### 3.1 使用エンドポイント

```
GET https://status.claude.com/api/v2/summary.json
```

認証不要。1エンドポイントで全情報を取得。

### 3.2 レスポンス構造（主要フィールド）

```json
{
  "page": {
    "id": "string",
    "name": "Claude",
    "url": "https://status.claude.com",
    "updated_at": "ISO8601"
  },
  "status": {
    "indicator": "none | minor | major | critical",
    "description": "All Systems Operational"
  },
  "components": [
    {
      "id": "string",
      "name": "claude.ai",
      "status": "operational | degraded_performance | partial_outage | major_outage",
      "group": false,
      "group_id": "string | null"
    }
  ],
  "incidents": [
    {
      "id": "string",
      "name": "Elevated errors on Claude API",
      "status": "investigating | identified | monitoring | resolved",
      "impact": "none | minor | major | critical",
      "created_at": "ISO8601",
      "updated_at": "ISO8601",
      "incident_updates": [
        {
          "id": "string",
          "status": "string",
          "body": "We have applied a fix...",
          "created_at": "ISO8601",
          "affected_components": [
            {
              "code": "string",
              "name": "Claude API",
              "old_status": "major_outage",
              "new_status": "operational"
            }
          ]
        }
      ]
    }
  ],
  "scheduled_maintenances": []
}
```

### 3.3 ポーリング設計

| 項目 | 値 |
|------|-----|
| ポーリング間隔 | 60 秒（デフォルト） |
| リトライ | 失敗時に指数バックオフ（60s → 120s → 240s、最大 300s） |
| タイムアウト | 10 秒 |

## 4. アーキテクチャ

### 4.1 プロジェクト構成

```
ClaudeStatusBar/
├── ClaudeStatusBarApp.swift          # @main, MenuBarExtra
├── Models/
│   └── StatusModels.swift            # Codable structs
├── Services/
│   ├── StatusService.swift           # API ポーリング + パース
│   └── NotificationService.swift     # macOS 通知の発火
├── Views/
│   ├── StatusMenuView.swift          # ポップオーバーの SwiftUI ビュー
│   ├── ComponentRow.swift            # コンポーネント1行分
│   └── IncidentCard.swift            # インシデント詳細カード
├── ViewModels/
│   └── StatusViewModel.swift         # @Observable, 状態管理
└── Resources/
    └── Assets.xcassets               # メニューバーアイコン
```

### 4.2 データフロー

```
Statuspage API
      │
      ▼
StatusService（60秒ごとにポーリング）
      │
      ▼
StatusViewModel（@Observable）
      │
      ├──▶ StatusMenuView（ポップオーバー UI 更新）
      │
      └──▶ NotificationService（ステータス変化時に通知発火）
```

### 4.3 状態管理

`StatusViewModel` が `@Observable` として以下を保持：

- `overallStatus: StatusIndicator` — 全体ステータス
- `components: [Component]` — コンポーネント一覧
- `activeIncidents: [Incident]` — 進行中インシデント
- `lastUpdated: Date` — 最終確認日時
- `isLoading: Bool` — ローディング状態
- `error: Error?` — エラー状態

## 5. UI モックアップ

### 5.1 メニューバー

```
──────────────────────────────────────────────
  Wi-Fi  🔋  ● ←（緑 or 赤の丸アイコン）  時刻
──────────────────────────────────────────────
```

### 5.2 ポップオーバー（正常時）

```
┌───────────────────────────────────┐
│  Claude Status          ● 正常   │
├───────────────────────────────────┤
│  claude.ai              ● 正常   │
│  Claude API             ● 正常   │
│  Claude Code            ● 正常   │
│  platform.claude.com    ● 正常   │
│  Claude for Government  ● 正常   │
├───────────────────────────────────┤
│  インシデントなし                  │
├───────────────────────────────────┤
│  最終確認: 10:30                  │
│  ─────────────────────────────── │
│  Open Status Page          Quit  │
└───────────────────────────────────┘
```

### 5.3 ポップオーバー（障害時）

```
┌───────────────────────────────────┐
│  Claude Status        ⚠ 障害発生  │
├───────────────────────────────────┤
│  claude.ai              ● 正常   │
│  Claude API             ● 障害   │
│  Claude Code            ● 障害   │
│  platform.claude.com    ● 正常   │
│  Claude for Government  ● 正常   │
├───────────────────────────────────┤
│  ⚠ 進行中のインシデント            │
│  ┌─────────────────────────────┐ │
│  │ Elevated errors on Claude   │ │
│  │ 影響: major  状態: monitoring│ │
│  │ 最終更新: 3/4 10:29         │ │
│  │ fix を適用し監視中...        │ │
│  └─────────────────────────────┘ │
├───────────────────────────────────┤
│  最終確認: 10:30                  │
│  ─────────────────────────────── │
│  Open Status Page          Quit  │
└───────────────────────────────────┘
```

## 6. 通知設計

| トリガー | 条件 | メッセージ例 |
|---------|------|-------------|
| 障害発生 | `indicator` が `none` → `minor/major/critical` | ⚠ Claude で障害が発生しました: Elevated errors on Claude API |
| 障害復旧 | `indicator` が `minor/major/critical` → `none` | ✅ Claude は復旧しました |

通知は macOS の通知センター経由（`UNUserNotificationCenter`）。初回起動時に通知許可をリクエスト。

## 7. 開発フェーズ

### Phase 1: プロジェクトセットアップ

- [x] Xcode プロジェクト作成（SwiftUI App, macOS）
- [x] ディレクトリ構成の作成
- [x] .gitignore の追加
- [x] CLAUDE.md の作成（プロジェクトのコンテキスト）

### Phase 2: API 通信 + データモデル

- [x] `StatusModels.swift` — Codable 構造体の定義
- [x] `StatusService.swift` — API ポーリング実装
- [x] ユニットテスト — モデルのデコード、サービスのモック

### Phase 3: メニューバー + UI

- [x] `ClaudeStatusBarApp.swift` — MenuBarExtra の設定
- [x] `StatusViewModel.swift` — 状態管理
- [x] `StatusMenuView.swift` — ポップオーバー全体
- [x] `ComponentRow.swift` — コンポーネント行
- [x] `IncidentCard.swift` — インシデント詳細

### Phase 4: 通知

- [x] `NotificationService.swift` — 通知の発火ロジック
- [x] 通知許可リクエスト
- [x] ステータス変化検知と通知トリガー

### Phase 5: 仕上げ

- [x] エラーハンドリング（ネットワーク断、API 障害）
- [x] ログイン時の自動起動設定（Launch at Login）
- [x] アプリアイコン作成
- [x] README.md 作成
- [x] LICENSE (MIT) 追加

### Phase 6: 配布

- [ ] Xcode Archive → .zip エクスポート
- [ ] GitHub Releases にアップロード
- [ ] homebrew-tap リポジトリ作成
- [ ] Cask 定義ファイル作成
- [ ] （将来）コード署名 + Notarization
- [ ] （将来）homebrew-cask 本体へ PR

> **Note:** Release ビルド（`xcodebuild -configuration Release`）および全15テストの通過を確認済み（2026-03-04）。Archive 以降は手動操作が必要。

## 8. コーディング規約

- Swift の標準的な命名規則に従う（lowerCamelCase）
- `@Observable` マクロを使用（Observation framework）
- async/await を使用した非同期処理
- git コミットメッセージは英語で記述する
- git コミットメッセージに `Co-Authored-By: Claude` の行を含めない
- 実装完了後は以下のドキュメントを更新すること：
  - `README.md` — 機能説明・インストール手順・使い方
  - `CLAUDE.md` — プロジェクト構成・ビルド手順・コーディング規約
  - `PLAN.md` — 完了したタスクのチェックボックスを更新

## 9. 将来的な拡張案（MVP 後）

- インシデント更新時の通知（オプション、デフォルト OFF）
- 予定メンテナンスの表示
- ポーリング間隔のカスタマイズ（設定画面）
- インシデント履歴の表示
- 複数サービスの監視対応（AWS, GitHub など）
- Webhook / Slack 連携
