---
applyTo: src/**
---

# 実装フェーズのルール

## 前提条件

以下のドキュメントが全て存在し、対応するレビュアーの承認を得ていること：

- `requirement/REQUIREMENTS.md`（requirements-reviewer 承認済み）
- `architecture/ARCHITECTURE.md`（architect-reviewer 承認済み）
- `design/UI_SPEC.md`（ui-reviewer 承認済み）
- `test/TEST_SPEC.md`（test-reviewer 承認済み）

## TDD サイクルの遵守

実装は必ず以下の順序で行うこと：

1. **Red**：`test/TEST_SPEC.md` のテストケースをコードに落とし、失敗するテストを書く
2. **Green**：テストが通る最小限の実装を書く
3. **Refactor**：Clean Architecture に準拠するようリファクタリングする

**テストコードより先に実装コードを書くことは禁止です。**

## Clean Architecture 遵守ルール

- **Domain 層**はフレームワーク・DB・外部サービスを直接 import しないこと
- **Presentation 層**から Domain 層へのアクセスはユースケース経由のみ
- **Data 層**の実装は Domain 層で定義した Repository インターフェースを実装すること
- 依存方向：Presentation → Domain ← Data

## ディレクトリ構成の規則

以下の構成は**固定ルールではなく推奨パターン**です。Android Studio や Xcode のテンプレート、KMP / Flutter / React Native などの実プロジェクト事情に合わせて、**feature / domain 単位のディレクトリ構成を採用してよい**ものとします。

重要なのはディレクトリ名そのものではなく、各 feature または module の内部で Clean Architecture の依存方向が守られていることです。

KMP を採用する案件では、`shared / android / ios` の抽象表現よりも、`commonMain / androidMain / iosMain` などの source set 構成を優先してよいものとします。

### パターン A: 共有層 + プラットフォーム層

```
src/
  shared/         # Android / iOS で共有するコード
    domain/
      entities/     # ビジネスエンティティ
      usecases/     # ユースケース
      repositories/ # リポジトリインターフェース（抽象）
    data/
      repositories/ # リポジトリ実装（共有できる部分）
      datasources/  # ネットワーク・永続化の抽象や共有実装
  android/
    presentation/   # Activity / Fragment / Compose Screen / ViewModel / Navigation
    platform/       # Android 固有の権限・通知・DI・ローカル実装
  ios/
    presentation/   # SwiftUI / UIViewController / ViewModel / Navigation
    platform/       # iOS 固有の権限・通知・DI・ローカル実装
test/
  shared/
    unit/          # shared/domain, shared/usecase の単体テスト
    integration/   # shared/data の統合テスト
  android/
    unit/          # Android ViewModel / Adapter / Mapper の単体テスト
    ui/            # Compose / Activity / Fragment の UI テスト
  ios/
    unit/          # iOS ViewModel / Adapter / Mapper の単体テスト
    ui/            # SwiftUI / UIViewController の UI テスト
```

### パターン B: feature / domain 単位

```text
src/
  shared/
    core/
    features/
      auth/
        domain/
        data/
      profile/
        domain/
        data/
  android/
    app/
    features/
      auth/
        presentation/
        platform/
      profile/
        presentation/
        platform/
  ios/
    app/
    features/
      auth/
        presentation/
        platform/
      profile/
        presentation/
        platform/
test/
  shared/
    features/
      auth/
        unit/
        integration/
  android/
    features/
      auth/
        unit/
        ui/
  ios/
    features/
      auth/
        unit/
        ui/
```

### パターン C: KMP source set 単位

```text
shared/
  src/
    commonMain/
      kotlin/
        core/
        features/
          auth/
            domain/
            data/
          profile/
            domain/
            data/
    androidMain/
      kotlin/
        features/
          auth/
            platform/
          profile/
            platform/
    iosMain/
      kotlin/
        features/
          auth/
            platform/
          profile/
            platform/
    commonTest/
      kotlin/
        features/
          auth/
            unit/
          profile/
            unit/
    androidUnitTest/
      kotlin/
        features/
          auth/
            unit/
            integration/
    iosTest/
      kotlin/
        features/
          auth/
            unit/
            integration/
androidApp/
  src/
    main/
iosApp/
  Sources/
```

- Android Studio や既存テンプレートが feature / module 単位の構成を生成する場合は、その構成を尊重してよい
- KMP の場合、`commonMain` には共有できる Domain / Data を配置し、`androidMain` と `iosMain` にはプラットフォーム依存実装を配置すること
- Compose Multiplatform などで UI を共有する場合のみ、`commonMain` に Presentation を置いてよい
- 共有コードがない案件では `src/shared/` と `test/shared/` を省略してよい
- 片方のプラットフォームのみを対象とする案件では未使用の `android/` または `ios/` を作成しないこと
- 既存プロジェクトが feature-first で構成されている場合は、無理に layer-first へ並べ替えないこと
- どの構成を採用する場合でも、Presentation → Domain ← Data の依存方向を崩さないこと

## 完了条件

- `test/TEST_SPEC.md` の全テストケースが PASS していること
- `architecture/ARCHITECTURE.md` の要件トレーサビリティが全て実装されていること
- code-reviewer による承認が得られていること
