# Claude Status Bar — 仕様書

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
| 配布方法 | Homebrew Cask（自前 Tap） |
| 開発体制 | Claude Code（Agent Teams）、サブエージェントは Opus モデルを使用 |
| ライセンス | MIT |

## 2. 機能仕様

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

### 4.1 データフロー

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

### 4.2 状態管理

`StatusViewModel` が `@Observable` として以下を保持：

- `overallStatus: StatusIndicator` — 全体ステータス
- `components: [Component]` — コンポーネント一覧
- `activeIncidents: [Incident]` — 進行中インシデント
- `lastUpdated: Date` — 最終確認日時
- `isLoading: Bool` — ローディング状態
- `error: Error?` — エラー状態

## 5. 通知設計

| トリガー | 条件 | メッセージ例 |
|---------|------|-------------|
| 障害発生 | `indicator` が `none` → `minor/major/critical` | ⚠ Claude で障害が発生しました: Elevated errors on Claude API |
| 障害復旧 | `indicator` が `minor/major/critical` → `none` | ✅ Claude は復旧しました |

通知は macOS の通知センター経由（`UNUserNotificationCenter`）。初回起動時に通知許可をリクエスト。

## 6. UI モックアップ

### 6.1 メニューバー

```
──────────────────────────────────────────────
  Wi-Fi  🔋  ● ←（緑 or 赤の丸アイコン）  時刻
──────────────────────────────────────────────
```

### 6.2 ポップオーバー（正常時）

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

### 6.3 ポップオーバー（障害時）

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
