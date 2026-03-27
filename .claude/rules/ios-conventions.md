---
globs: ["**/*.swift", "**/*.xib", "**/*.storyboard", "*.xcodeproj/**", "*.xcworkspace/**"]
---

# iOS 開発の基本ルール

## Xcode プロジェクト
- `.pbxproj` ファイルを直接編集しない。ファイルの作成は Claude Code で行い、Xcode プロジェクトへの追加はユーザーが手動で行う
- `.xib` / `.storyboard` を直接編集しない。変更が必要な場合はユーザーに依頼する
- Info.plist を直接編集しない。変更が必要な場合はユーザーに確認する

## セキュリティ
- API キー・シークレット情報をソースコードにハードコードしない
- 機密情報は Keychain または環境変数で管理する
- `.env` ファイルをコミットしない

## DO NOT
- `.pbxproj` を直接編集しない
- `.xib` / `.storyboard` を直接編集しない
- Info.plist を直接編集しない
- `Pods/` 配下を手動で変更しない
- シークレット情報をソースコードにハードコードしない
