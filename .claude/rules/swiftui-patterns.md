---
globs: ["**/*.swift"]
---

# SwiftUI パターン

## View の設計
- 1 つの View ファイルは 200 行以下を目安にする
- 大きな View は SubView に分割する
- プレビューを必ず定義する（#Preview）
- View の変更後は RenderPreview で見た目を確認する

## 状態管理
- @Observable マクロを優先する
- @State: View ローカルの状態
- @Binding: 親 View からの受け渡し
- @Environment: アプリ全体の共有データ
- @Bindable: @Observable オブジェクトのプロパティを Binding として渡す

## DO NOT
- 200 行を超える巨大な View を作らない
- @State で外部から注入すべきデータを管理しない
- プレビュー（#Preview）を省略しない
- RenderPreview での確認を省略しない
