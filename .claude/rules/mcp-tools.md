---
globs: ["**/*.swift", "Package.swift", "*.xcodeproj/**"]
---

# MCP ツール活用ルール

## XcodeBuildMCP（最優先）
- ビルド・テスト・シミュレータ操作は必ず XcodeBuildMCP のツールを使う
- `xcodebuild` コマンドを直接叩かない
- ビルドエラーが出たら XcodeBuildMCP の診断ツールで原因を確認する

### 主要ツール
- ビルド: `mcp__xcodebuildmcp__build_sim_name_proj`
- テスト: `mcp__xcodebuildmcp__test_sim_name_proj`
- クリーン: `mcp__xcodebuildmcp__clean`
- シミュレータ一覧: `mcp__xcodebuildmcp__list_simulators`
- シミュレータ起動: `mcp__xcodebuildmcp__boot_simulator`
- アプリインストール: `mcp__xcodebuildmcp__install_app`
- アプリ起動: `mcp__xcodebuildmcp__launch_app`
- ログ取得: `mcp__xcodebuildmcp__capture_logs`
- スクリーンショット: `mcp__xcodebuildmcp__screenshot`
- Swift Package ビルド: `mcp__xcodebuildmcp__swift_package_build`
- Swift Package テスト: `mcp__xcodebuildmcp__swift_package_test`

## ドキュメント検索（優先順位付き）
- Apple フレームワークの API を使う前に必ずドキュメントで確認する
- 「この API の使い方はこうだったはず」と推測しない
- 非推奨 API を使いそうになったらドキュメントで代替を探す

### 優先順位
1. **Xcode が起動している場合**: Apple Xcode MCP の DocumentationSearch を優先する（セマンティック検索で精度が高い）
2. **Xcode が起動していない場合**: apple-docs-mcp を使う（Xcode 不要で動作する）

### apple-docs-mcp の追加機能
- WWDC 2014〜2025 の動画・トランスクリプト検索
- フレームワーク階層のブラウズ
- API 間の関連性発見
- プラットフォーム互換性チェック（iOS / macOS / watchOS / tvOS / visionOS）

## RenderPreview（SwiftUI 限定）
- SwiftUI の View を作成・変更したら RenderPreview で見た目を確認する
- UIKit の画面では RenderPreview は使用しない
- 確認せずに「たぶん大丈夫」で進めない

## DO NOT
- `xcodebuild` コマンドを直接叩かない（XcodeBuildMCP を使う）
- API の使い方を推測しない（DocumentationSearch で確認する）
- SwiftUI の変更を目視確認せずに完了としない
