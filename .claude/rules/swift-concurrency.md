---
globs: ["**/*.swift"]
---

# Swift Concurrency

## 基本方針（必須）
- UI 更新は `@MainActor` を使う。`DispatchQueue.main.async` は使わない
- 非同期処理は async/await を使う。completionHandler パターンは使わない
- 既存の completionHandler API は `withCheckedContinuation` / `withCheckedThrowingContinuation` でラップする
- Actor 境界を越えるデータ型は Sendable に準拠させる

## Actor
- 共有の可変状態は Actor で保護する
- `nonisolated` は必要な場合のみ明示する

## Task
- `Task { }` のキャンセル処理を考慮する
- `Task.detached` は本当に必要な場合のみ使う
- 長時間の処理では `Task.checkCancellation()` を挟む

## DO NOT
- `DispatchQueue.main.async` を使わない（`@MainActor` を使う）
- `DispatchQueue.global()` を使わない（Task / Actor を使う）
- `completionHandler` で新規コードを書かない
- `@Sendable` クロージャ内で非 Sendable な型を渡さない
- `Task.detached` を安易に使わない
