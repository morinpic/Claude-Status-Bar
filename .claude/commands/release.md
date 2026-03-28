バージョン $ARGUMENTS でリリースを実行してください。

## 手順

### 1. バージョン番号の検証

引数がセマンティックバージョニング形式（例: 1.1.0, 2.0.0）であることを確認。
不正な場合はエラーメッセージを出して終了。

### 2. リリース確認（重要！）

以下の情報を収集して、大きな ASCII アートの確認画面を表示する。
ユーザーが「OK」「yes」等で明示的に承認するまで絶対に先に進まないこと。

収集する情報:
- 現在のバージョン: project.pbxproj の MARKETING_VERSION を読み取る
- リリースバージョン: $ARGUMENTS
- CHANGELOG.md の Unreleased セクションの内容

以下のフォーマットで表示:

```
╔══════════════════════════════════════════════════╗
║                                                  ║
║     🚀  R E L E A S E   C O N F I R M  🚀      ║
║                                                  ║
╠══════════════════════════════════════════════════╣
║                                                  ║
║   Current:  v{現在のバージョン}                    ║
║   Release:  v$ARGUMENTS                          ║
║                                                  ║
╠══════════════════════════════════════════════════╣
║                                                  ║
║   Changes:                                       ║
║   - {CHANGELOGの各項目}                           ║
║   - {CHANGELOGの各項目}                           ║
║   ...                                            ║
║                                                  ║
╠══════════════════════════════════════════════════╣
║                                                  ║
║   Actions:                                       ║
║   1. Update CHANGELOG.md                         ║
║   2. Bump MARKETING_VERSION                      ║
║   3. Build & verify                              ║
║   4. Commit & push to main                       ║
║   5. Create tag v$ARGUMENTS & push               ║
║   6. GitHub Actions → Release + Cask update      ║
║                                                  ║
╚══════════════════════════════════════════════════╝

⚠️  Proceed with release v$ARGUMENTS? (yes/no)
```

ユーザーが承認しなかった場合はリリースを中止する。

### 3. リリースサマリーの生成

CHANGELOG.md の Unreleased セクションの変更内容を読み、
リリース全体を一行で要約する英語のサマリー文を生成する。

ルール:
- 1文で、このリリースの主要な変更を簡潔に表現する
- ユーザー目線で書く（技術的な内部変更よりもユーザーに見える変化を優先）
- 例: "Customize your menu bar icon and access GitHub directly from the popover."
- 例: "Real-time status history graphs and per-component notification settings."

### 4. CHANGELOG.md の更新

- `## [Unreleased]` セクションを `## [$ARGUMENTS] - YYYY-MM-DD`（今日の日付）に変更
- バージョンヘッダの直後（### Added 等の前）に、手順3で生成したサマリー文を1行追加する
- Unreleased セクションが空の場合はエラーを出して終了
- ファイル末尾にリンク定義を追加:
  `[$ARGUMENTS]: https://github.com/morinpic/Claude-Status-Bar/compare/v{前バージョン}...v$ARGUMENTS`

### 5. MARKETING_VERSION の更新

`ClaudeStatusBar.xcodeproj/project.pbxproj` 内の ClaudeStatusBar ターゲット（Debug / Release）の `MARKETING_VERSION` を `$ARGUMENTS` に更新。
Tests ターゲットは変更しない。

### 6. ビルド確認

```
xcodebuild -scheme ClaudeStatusBar -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

ビルドが失敗した場合は修正してリトライ。

### 7. コミット & プッシュ

```
git add -A
git commit -m "Bump version to $ARGUMENTS"
git push origin main
```

### 8. タグ作成 & プッシュ

```
git tag v$ARGUMENTS
git push origin v$ARGUMENTS
```

### 9. 完了メッセージ

以下を表示:
- `✅ v$ARGUMENTS のリリースを開始しました`
- `GitHub Actions が自動で Release + Homebrew Cask 更新を実行します`
- `確認: https://github.com/morinpic/Claude-Status-Bar/actions`
