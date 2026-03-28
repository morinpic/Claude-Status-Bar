# Claude Status Bar

> Never miss a Claude outage.

macOS メニューバー常駐アプリ。Claude のサービスステータスを監視し、障害発生時にリアルタイム通知する。

## 技術スタック

- Swift + SwiftUI
- macOS 26.0+ (Tahoe)
- データソース: Statuspage REST API (`https://status.claude.com/api/v2/summary.json`)

## 開発体制

- Claude Code（Agent Teams）で開発を行う
- サブエージェントは Opus モデルを使用する
- 仕様書: `docs/PLAN.md` を参照
- バックログ: `docs/BACKLOG.md` を参照
- 変更履歴: `docs/CHANGELOG.md` を参照

## プロジェクト構成

```
ClaudeStatusBar/
├── ClaudeStatusBarApp.swift          # @main, MenuBarExtra
├── ClaudeStatusBar.entitlements      # App Sandbox + ネットワーク権限
├── Models/
│   ├── StatusModels.swift            # Codable structs（API レスポンス）
│   ├── IconDesignType.swift          # アイコンデザイン・状態 enum
│   └── AppLanguage.swift             # 言語設定 enum（system / en / ja）
├── Services/
│   ├── StatusService.swift           # API ポーリング + パース + 指数バックオフ
│   ├── NotificationService.swift     # UNUserNotificationCenter 通知
│   └── NotificationSettingsService.swift # コンポーネント通知設定の永続化
├── Views/
│   ├── StatusMenuView.swift          # ポップオーバー（ステータス表示）
│   ├── ComponentRow.swift            # コンポーネント1行分
│   ├── IncidentCard.swift            # インシデント詳細カード
│   └── SettingsView.swift            # 設定ウィンドウ（General + Notifications）
├── ViewModels/
│   └── StatusViewModel.swift         # @Observable, 状態管理 + 通知トリガー
├── Debug/                            # DEBUG ビルド限定（#if DEBUG）
│   ├── DebugPreset.swift             # デバッグ用プリセットデータ
│   └── DebugMenuView.swift           # デバッグメニュー UI
└── Resources/
    ├── Assets.xcassets               # アプリアイコン + カラーアセット
    └── Localizable.xcstrings         # String Catalog（英語 + 日本語）

ClaudeStatusBarTests/
├── StatusModelsTests.swift           # モデルデコードテスト
└── StatusServiceTests.swift          # サービスモックテスト
```

## ビルド・テスト

```bash
# ビルド
xcodebuild -scheme ClaudeStatusBar -configuration Debug build

# テスト
xcodebuild -scheme ClaudeStatusBar -configuration Debug test

# クリーンビルド
xcodebuild -scheme ClaudeStatusBar -configuration Debug clean build
```

## API

```
GET https://status.claude.com/api/v2/summary.json
```

- 認証不要
- ポーリング間隔: 60秒
- リトライ: 指数バックオフ（60s → 120s → 240s、最大 300s）

## コーディング規約

- Swift の標準的な命名規則に従う（lowerCamelCase）
- `@Observable` マクロを使用（Observation framework）
- async/await を使用した非同期処理
- git コミットメッセージは英語で記述する
- git コミットメッセージに `Co-Authored-By: Claude` の行を含めない
- GitHub Release のリリースノートは英語で記述する
- チームで相談してタスクを実装すること
- 適切な粒度でコミットすること

## 作業フロー

コミットメッセージ、ブランチ名、PR タイトル・本文はすべて英語で記述する。

作業は以下の順番で行うこと：

1. `main` から feature ブランチを切る（ブランチ名: `feature/{backlog-id}-{short-description}`、例: `feature/f13-notification-settings`）
2. 実装・コミット（`main` への直接コミット禁止）
3. PR を作成する（`docs/BACKLOG.md` の該当タスクへの取り消し線も PR に含める）
4. もりけんさんのレビュー・承認後にマージする
5. マージ後のブランチ削除は GitHub の自動削除設定で行う

**例外:** ドキュメントのみの修正（README.md, CLAUDE.md, docs/ 配下）はプロダクトコードを含まないため、`main` への直接プッシュ可

### GitHub Issue を作成するケース

通常タスクでは Issue を作成しない（BACKLOG.md + PR ベースで運用する）。以下の場合のみ Issue を作成する：

- 外部からのバグ報告・機能リクエスト
- 設計議論が必要な大きめのタスク
- OSS コントリビューター向けの `good first issue`

### Issue 作成時の注意

以下の内容が含まれていないか必ず確認すること：

- 脆弱性・セキュリティバグの詳細（修正前に公開すると悪用されるもの）
- 認証情報・APIキー・トークン類
- 上記に該当する場合は Issue を作成せず、もりけんさんに確認を取ること

## くーちゃんの振る舞いルール

以下のタイミングでは、くーちゃんは必ずバージョンアップが必要かどうかを判定し、もりけんさんに積極的に伝えること：

- 実装完了の報告を受けたとき
- ブランチを `main` へマージする相談を受けたとき
- CHANGELOG.md の `[Unreleased]` に追記があるとき
- Claude Code チームへの指示プロンプトを作成したとき

判定基準は「バージョン管理ルール」セクションに従う。バージョンアップが必要な場合は、PATCH / MINOR / MAJOR のどれかを明示して提案すること。

## バージョン管理ルール

現在のバージョン: `2.2.0`（MARKETING_VERSION）

Semantic Versioning（`MAJOR.MINOR.PATCH`）に従う。

| 種別 | 上げるケース | 例 |
|---|---|---|
| PATCH | バグ修正・既存機能の軽微な改善 | クラッシュ修正、表示崩れ修正 |
| MINOR | 新機能追加・UX改善（後方互換あり） | 通知機能追加、設定項目追加 |
| MAJOR | 破壊的変更・アーキテクチャ刷新 | 対応 OS の変更、データ構造の非互換変更 |

**バージョンを上げるタイミング**

- `main` へのマージ前に必ず判定する
- 1つのブランチで PATCH / MINOR が混在する場合は上位（MINOR）を優先する
- バージョン変更は `project.pbxproj` の `MARKETING_VERSION` を編集し、単独コミットにまとめる
- CHANGELOG.md に変更内容を追記してからバージョンを上げること

**やってはいけないこと**

- 複数フィーチャーブランチのマージを一括してバージョンアップしない（マージごとに判定する）
- `CURRENT_PROJECT_VERSION`（ビルド番号）は手動で変えない（CI が自動インクリメント）

## ドキュメント更新ルール

実装完了後は以下のドキュメントを必ず更新すること：

- `README.md` — 機能説明・インストール手順・使い方
- `CLAUDE.md` — プロジェクト構成・ビルド手順・コーディング規約
- `docs/PLAN.md` — 仕様に変更があれば更新
- `docs/CHANGELOG.md` — リリース時に変更履歴を追記
- `docs/BACKLOG.md` — 実装した項目の Issue 列更新・完了マーク。運用ルールは BACKLOG.md を参照。**既存の項目を削除しないこと（取り消し線のみ）**
