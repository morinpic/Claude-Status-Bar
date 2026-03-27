---
globs: ["**/*.swift"]
---

# AutoLayout

## 基本方針
- AutoLayout はコードで記述する（Storyboard / xib の AutoLayout は使わない）
- `translatesAutoresizingMaskIntoConstraints = false` を忘れない
- プロジェクトで使用しているレイアウトライブラリ（SnapKit 等）がある場合はそちらを優先する

## 制約の書き方
- NSLayoutConstraint.activate で一括でアクティベートする（個別に `isActive = true` しない）
- 制約の優先度が必要な場合は `.priority` を明示する
- Safe Area を意識する（`safeAreaLayoutGuide`）

## パフォーマンス
- 不要な制約の追加・削除を繰り返さない
- `setNeedsLayout()` / `layoutIfNeeded()` の使い分けを意識する

## DO NOT
- `translatesAutoresizingMaskIntoConstraints = false` を忘れない
- 制約を個別に `isActive = true` しない（`NSLayoutConstraint.activate` を使う）
- Safe Area を無視しない
