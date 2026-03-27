---
globs: ["**/*.swift"]
---

# 命名規則

## 全般
- Swift API Design Guidelines に従う
- 型名は UpperCamelCase、変数・関数名は lowerCamelCase
- 略語は避ける（`btn` → `button`, `vc` → `viewController`）
- Bool 変数は `is` / `has` / `should` / `can` プレフィックスを使う

## ファイル名
- ファイル名は主要な型名と一致させる（`UserProfileView.swift`）
- Protocol は `〜Protocol` or `〜able` / `〜ing`
- Extension は `TypeName+Category.swift`（例: `String+Validation.swift`）

## SwiftUI 固有
- View: `〜View` or `〜Screen`（画面単位の場合）
- ViewModifier: `〜Modifier`

## DO NOT
- 略語を使わない（`btn`, `vc`, `lbl` 等）
- ファイル名と型名を不一致にしない
- Bool 変数にプレフィックスを付けずに命名しない
