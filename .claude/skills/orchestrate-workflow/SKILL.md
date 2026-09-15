# V字開発ワークフロー オーケストレーション

このスキルは、ユーザー要求から実装完了までの進行管理を担当します。Sub Agent は役割に集中させ、フェーズ順序、承認判定、差し戻し制御はこのスキルで扱います。

## 基本方針

- 要件定義、設計、UI 仕様、テスト設計、実装の順序を崩さないこと
- レビュアーの総合判定が `承認` または `条件付き承認` の場合のみ次へ進むこと
- 総合判定が `差し戻し` の場合は、指摘を整理して直前の担当 Agent を再実行すること
- Agent には役割と成果物だけを渡し、詳細な進行管理はこのスキルが担うこと

## Sub Agent 使用の厳格化

### 適用判定

成果物に**実装コードまたはテストコードが含まれる場合**、本スキルのフェーズ運用を適用し、該当フェーズの Sub Agent を経由すること。次のいずれかに該当する場合は対象外とする。

- ドキュメントの作成と改訂のみで完結する（`AGENTS.md` の対象外規定）
- アイデア出し、ブレインストーミング、調査、Q&A
- 既存の要件・設計・テスト仕様に変更が及ばない修正（typo 修正、コメント修正など）

「規模が小さいから対象外」という判断はしないこと。作業中に要件・設計・テスト仕様へ手が伸びた時点で、フェーズ運用へ切り替えること。

### ハーネス既定方針との優先順位

実行環境の既定方針が「明示的に依頼されない限り Sub Agent（Agent ツール）を使わない」と定めている場合、**`AGENTS.md` と本スキルの規定が優先される**。`AGENTS.md` はユーザーが明示的に定めた運用規約であり、実行環境の既定値より上位にある。

### 機械的な担保（`.claude/hooks/subagent_gate.py`）

上記は指示文であり、読み落としや優先順位の取り違えを防げない。そのため `settings.json` の3イベントから `.claude/hooks/subagent_gate.py` を呼び、次を機械的に検査する。

| イベント | サブコマンド | 役割 |
|---|---|---|
| `SubagentStart` | `record-subagent` | Sub Agent が起動した事実を記録する |
| `PostToolUse`（`Write\|Edit\|MultiEdit`） | `record-edit` | 実装コード・テストコードの編集を記録する |
| `Stop` | `check-stop` | 「コードを編集したが Sub Agent 未起動」のとき `decision: block` を返す |

ブロックは**セッションごとに1回のみ**である。恒久的にブロックすると対象外の作業でターンを終了できなくなるため、判断を省略できない状態にしつつデッドロックを避ける設計としている。ブロックされた場合は、該当フェーズの Sub Agent を起動するか、対象外である理由をユーザーへ明示すること。理由の説明を省略して終了しないこと。

判定はファイル拡張子に基づく。「既存の要件・設計・テスト仕様に変更が及ぶか」はフックでは判定できないため、その線引きは上記「適用判定」に従うこと。

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
- 外部 SDK を利用している場合、収集データ項目・権限宣言・プライバシーポリシーの3点の整合性が検証されている

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

必要に応じて `session-retrospective` Skill を呼び出し、振り返り結果を標準形式で作成してください。
