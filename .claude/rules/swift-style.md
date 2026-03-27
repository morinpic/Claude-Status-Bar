---
globs: ["**/*.swift"]
---

# Swift コーディングスタイル

## 全般
- guard-let / if-let を使ったアーリーリターンで可読性を保つ
- アクセスコントロールを明示する（`private`, `internal`, `public`）
- マジックナンバー・マジックストリングは定数化する
- `self.` は必要な場合のみ記述する（クロージャ内のキャプチャ等）
- 1 ファイル 1 型を基本とする。小さな関連型（enum, protocol）は同一ファイルも可
- 値型（struct）を優先する。参照型（class）は明確な理由がある場合のみ

## MARK コメント
- セクション分けに `// MARK: -` を使う
- ライフサイクル、public メソッド、private メソッド、extension の順で整理する

## Optional
- Force Unwrap（`!`）は原則使わない
- `guard let` / `if let` で安全にアンラップする
- nil 合体演算子（`??`）でデフォルト値を提供する

## DO NOT
- Force Unwrap（`!`）を正当な理由なく使わない
- `as!` を使わない（`as?` + guard/if-let を使う）
- 1 ファイルに複数の大きな型を定義しない
- `self.` を不要な場所で書かない
- 非推奨 API を使わない（DocumentationSearch で代替を確認する）
