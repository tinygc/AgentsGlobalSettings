---
applyTo: architecture/**
---

# アーキテクチャ設計フェーズのルール

## 前提条件

- `requirement/REQUIREMENTS.md` が存在し、requirements-reviewer の承認を得ていること

## Clean Architecture の遵守

以下の3層構造を**必ず**採用してください：

| 層 | 責務 | 依存先 |
|---|---|---|
| Presentation | UI・API エンドポイント | Domain のみ |
| Domain | ビジネスロジック・エンティティ・ユースケース | なし（最内層） |
| Data | リポジトリ実装・外部サービス連携 | Domain のインターフェース |

### 禁止事項

- Domain 層にフレームワーク・DB・外部ライブラリを直接 import すること
- Presentation 層から Data 層を直接参照すること
- レイヤーを跨ぐ直接依存（例：ViewModel が Repository 実装を直接使用）

## 必須ドキュメント構成

`architecture/ARCHITECTURE.md` は以下のセクションを全て含めること：

1. システム概要
2. アーキテクチャ概念図
3. レイヤー構成（各層の責務と構成要素）
4. データモデル（ER 図またはクラス図）
5. API 設計（エンドポイント一覧）
6. 画面-データ対応表
7. 技術スタック
8. 要件トレーサビリティ（FR-xxx → 実現方法）

## トレーサビリティ

- 要件トレーサビリティセクションで全 FR の実現方法を記載すること
- FR が追加・変更された場合は対応表を更新すること

## フェーズ進行の条件

architect-reviewer による以下のチェックが完了するまで実装フェーズへ進まないこと：

- [ ] 全 FR が設計上で実現方法と対応付けられている
- [ ] Clean Architecture 3層が明確に分離されている
- [ ] Domain 層に外部依存がない
- [ ] データモデルが要件を満たしている
