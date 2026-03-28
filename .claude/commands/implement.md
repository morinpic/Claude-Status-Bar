バックログ項目 $ARGUMENTS を実装してください。

## 手順

### 1. バックログの読み取り

`docs/BACKLOG.md` を読み、$ARGUMENTS に該当する項目の内容を確認する。
該当する項目が見つからない場合はエラーを出して終了。
既に取り消し線（完了済み）の項目の場合もエラーを出して終了。

### 2. GitHub Issue 作成

- タイトル: `$ARGUMENTS: {バックログの内容を英訳}`
- 本文: 実装要件を英語で記述（Summary, Requirements のセクションを含む）
- `gh issue create` で作成し、Issue 番号を控える

### 3. ブランチ作成

```
git checkout main
git pull origin main
git checkout -b feature/{$ARGUMENTSを小文字にしたもの}-{内容を短い英語ケバブケースで}
```

例: $ARGUMENTS が F-12 で内容が「ステータス履歴グラフ」の場合
→ `feature/f12-status-history-graph`

### 4. 実装

バックログの内容と Issue の要件に基づいて実装する。
実装方針に迷う場合はユーザーに確認すること。

既存コードのパターンに従う:
- `@Observable` マクロ + Observation framework
- async/await による非同期処理
- Swift 標準の命名規則（lowerCamelCase）

### 5. ビルド確認

```
xcodebuild -scheme ClaudeStatusBar -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

ビルドが失敗した場合は修正してリトライ。

### 6. コミット

適切な粒度でコミットする。コミットメッセージは英語。
`Co-Authored-By: Claude` の行は含めない。

最後のコミット（ドキュメント更新コミット）のメッセージに `Closes #{Issue番号}` を含めること。
これにより main マージ時に Issue が自動で close される。

### 7. ドキュメント更新

以下のドキュメントを更新してコミット:

- `docs/BACKLOG.md` — 該当項目の Issue 列に Issue 番号を記載、取り消し線で完了マーク
- `docs/CHANGELOG.md` — `## [Unreleased]` セクションに変更内容を追記（なければセクションを作成）
- `CLAUDE.md` — プロジェクト構成に新規ファイルがあれば追記
- `README.md` — ユーザー向けの機能説明に変更があれば追記
- `docs/PLAN.md` — 仕様に変更があれば更新

コミットメッセージ例: `Update docs for $ARGUMENTS. Closes #XX`

### 8. 完了メッセージ

以下を表示:
- `✅ $ARGUMENTS の実装が完了しました`
- 変更したファイルの一覧
- `main にマージすると Issue #XX が自動で close されます`
- `動作確認後、main にマージしてください`
