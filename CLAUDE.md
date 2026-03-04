# Claude Status Bar

> Never miss a Claude outage.

macOS メニューバー常駐アプリ。Claude のサービスステータスを監視し、障害発生時にリアルタイム通知する。

## 技術スタック

- Swift + SwiftUI
- macOS 14.0+ (Sonoma)
- データソース: Statuspage REST API (`https://status.claude.com/api/v2/summary.json`)

## 開発体制

- Claude Code（Agent Teams）で開発を行う
- サブエージェントは Opus モデルを使用する
- 計画書: `docs/PLAN.md` を参照

## プロジェクト構成

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
- フェーズごとにブランチを作成し、その中で作業すること
- 適切な粒度でコミットすること

## ドキュメント更新ルール

実装完了後は以下のドキュメントを必ず更新すること：

- `README.md` — 機能説明・インストール手順・使い方
- `CLAUDE.md` — プロジェクト構成・ビルド手順・コーディング規約
- `docs/PLAN.md` — 完了したタスクのチェックボックスを更新
