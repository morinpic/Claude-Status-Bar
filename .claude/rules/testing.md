---
globs: ["**/*Tests*/**/*.swift", "**/*Test*.swift"]
---

# テスト方針

## フレームワーク
- 新規テストは Swift Testing（`@Test` + `#expect`）で書く
- UI テスト・パフォーマンステストは XCTest を使う（Swift Testing 未対応のため）
- 既存の XCTest テストは無理に移行しない（共存 OK）

## Swift Testing の書き方
- `@Test` マクロでテスト関数を定義する（`test` プレフィックス不要）
- `#expect()` で検証する（`XCTAssertEqual` 等は使わない）
- `@Test(arguments:)` でパラメタライズドテストを活用する
- テストは並列実行がデフォルト。順序依存しないように書く
- `@Suite` でテストをグルーピングする

## テスト実行
- テストの実行は XcodeBuildMCP のテストツールを使う
- `xcodebuild test` を直接叩かない

## テスト対象の優先度
- ViewModel / UseCase / Repository 等のロジック層を優先的にテストする
- 新規コードにはユニットテストを書く
- View（UI）のテストは必要に応じて

## DO NOT
- 新規テストで XCTAssert 系を使わない（`#expect` を使う）
- テスト間で状態を共有しない（並列実行で壊れる）
- `xcodebuild test` を直接叩かない（XcodeBuildMCP を使う）
