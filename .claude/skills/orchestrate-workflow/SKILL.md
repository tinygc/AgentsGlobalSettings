# V字開発ワークフロー オーケストレーション

このスキルは、ユーザー要求から実装完了までの進行管理を担当します。Sub Agent は役割に集中させ、フェーズ順序、承認判定、差し戻し制御はこのスキルで扱います。

## 基本方針

- 要件定義、設計、UI 仕様、テスト設計、実装の順序を崩さないこと
- レビュアーの総合判定が `承認` または `条件付き承認` の場合のみ次へ進むこと
- 総合判定が `差し戻し` の場合は、指摘を整理して直前の担当 Agent を再実行すること
- Agent には役割と成果物だけを渡し、詳細な進行管理はこのスキルが担うこと

## Agent ごとの役割

- `requirements-analyst`: ユーザー要求を整理し、`requirement/REQUIREMENTS.md` を作成する
- `requirements-reviewer`: 要件定義書の完全性、明確性、テスト可能性を判定する
- `architect`: 要件をもとに `architecture/ARCHITECTURE.md` を作成する
- `ui-designer`: 要件と設計をもとに `design/UI_SPEC.md` を作成する
- `architect-reviewer`: アーキテクチャ設計書の妥当性と UI 仕様書との整合性を判定する
- `ui-reviewer`: UI 仕様書の使いやすさ、明確性、実装可能性を判定する
- `test-designer`: 要件をもとに `test/TEST_SPEC.md` を作成する
- `test-reviewer`: テスト仕様書のカバレッジと品質を判定する
- `implementer`: TDD で実装とテストを更新する
- `code-reviewer`: 実装とテストが要件・設計に合致するか判定する

## 実行フロー

1. `requirements-analyst` を呼び出し、必要ならユーザーへ追加質問を行う
2. `requirements-reviewer` を呼び出す
3. `requirements-reviewer` が `差し戻し` の場合は、指摘を反映させて 1 に戻る
4. `architect` を呼び出す
5. `ui-designer` を呼び出す
6. `architect-reviewer` を呼び出す
7. `ui-reviewer` を呼び出す
8. `architect-reviewer` が `差し戻し` の場合は、指摘内容に応じて 4 または 5 に戻る
9. `ui-reviewer` が `差し戻し` の場合は、5 に戻る
10. `test-designer` を呼び出す
11. `test-reviewer` を呼び出す
12. `test-reviewer` が `差し戻し` の場合は、10 に戻る
13. `implementer` を呼び出す
14. `code-reviewer` を呼び出す
15. `code-reviewer` が `差し戻し` の場合は、13 に戻る

## 各フェーズの入力と期待成果物

### 要件定義
- 入力: ユーザーの要望、既存制約、参考資料
- 成果物: `requirement/REQUIREMENTS.md`

### 設計
- 入力: 承認済み `requirement/REQUIREMENTS.md`
- 成果物: `architecture/ARCHITECTURE.md`、`design/UI_SPEC.md`

### テスト設計
- 入力: 承認済み要件定義書
- 成果物: `test/TEST_SPEC.md`

### 実装
- 入力: 承認済み要件定義書、設計書、UI 仕様書、テスト仕様書
- 成果物: `src/` および `test/` 配下の実装コードとテストコード、または feature / module 単位で整理された同等の構成、テスト実行結果

## 最終チェック

- `requirement/REQUIREMENTS.md` が存在する
- `architecture/ARCHITECTURE.md` が存在する
- `design/UI_SPEC.md` が存在する
- `test/TEST_SPEC.md` が存在する
- 対象プラットフォームに応じた実装コードとテストコードが存在する
- 全テストが PASS している

## セッション振り返り（改善反映）

実装やレビューが完了したら、次回以降の品質改善のために必ず振り返りを実施してください。

1. セッション内で「進行が止まった点」「やり直しが発生した点」「ユーザーからの指摘」を抽出する
2. 事実ベースで原因を分類する（指示不足、出力形式不一致、手順不足、制約未考慮など）
3. 改善対象を以下から選ぶ
	- Sub Agent 定義（`.claude/agents/*.agent.md`）
	- Skill（`.claude/skills/*/SKILL.md`）
	- Rule（`.claude/rules/*.instructions.md`）
	- グローバル運用方針（`AGENTS.md`）
4. 改善案を「最小変更」で文書化またはファイル更新する
5. 改善案と実施結果をセッションログに残す

必要に応じて `session-retrospective` Skill を呼び出し、振り返り結果を標準形式で作成してください.
