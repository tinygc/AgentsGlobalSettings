#!/usr/bin/env python3
"""Sub Agent 承認ゲートの検査フック。

`AGENTS.md` は V字開発と TDD を前提とし、フェーズ順序と承認ゲートを
`.claude/skills/orchestrate-workflow/SKILL.md`、各 Sub Agent の役割を
`.claude/agents/*.agent.md` を正本として定める。しかしこれらは指示文にとどまるため、
ハーネス側の既定方針（「明示的に依頼されない限り Agent ツールを使わない」）と衝突した場合に
Sub Agent を経由しないまま実装が進む余地が残る。本フックはその余地を機械的に塞ぐ。

## 動作

3つのサブコマンドを1ファイルに束ね、`settings.json` の3イベントから呼び出す。

- `record-subagent`: `SubagentStart` で呼び、当該セッションで Sub Agent が起動した事実を記録する
- `record-edit`: `PostToolUse`（`Write|Edit|MultiEdit`）で呼び、実装コードまたはテストコードの
  編集を記録する
- `check-stop`: `Stop` で呼び、「コードを編集したが Sub Agent を一度も起動していない」場合に
  `decision: block` を返してターンを継続させ、フェーズ運用の適用判断を促す

## 設計判断

**ブロックはセッションごとに1回のみ**とする。恒久的にブロックすると、typo 修正のような
フェーズ運用の対象外（`AGENTS.md`「調査や Q&A は対象外」）の作業でターンが終了できなくなる。
1回だけ差し込むことで、判断を省略できない状態にしつつデッドロックを避ける。
ブロック後は同一セッションで再度ブロックしない。

**判定はファイル拡張子のみで行う**。「既存の要件・設計・テスト仕様に変更が及ぶか」は
フックでは判定できないため、その線引きは `orchestrate-workflow` の記述に委ね、
本フックは「ソースコードが書かれたか」だけを見る。

**状態はセッション単位の一時ファイルに持つ**。`install.sh` は `~/.claude` を作り直すため、
インストール中に状態が失われる位置を避ける。

入力・出力の契約は Claude Code のフック仕様に従う（stdin に JSON、stdout に JSON）。
フック自身の障害でユーザーの作業を止めないため、例外は握りつぶして exit 0 する。
"""

from __future__ import annotations

import json
import pathlib
import re
import sys
import tempfile

#: 実装コードまたはテストコードと見なす拡張子。
#: ドキュメント（.md）・設定（.json / .yml）・リソース（.xml）は含めない。
#: これらの変更のみで完結する作業はフェーズ運用の対象外だからである。
SOURCE_SUFFIXES = frozenset(
    {
        ".kt", ".kts", ".java", ".scala", ".groovy",
        ".swift", ".m", ".mm",
        ".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".vue", ".svelte",
        ".py", ".rb", ".go", ".rs", ".dart", ".php", ".cs",
        ".c", ".cc", ".cpp", ".cxx", ".h", ".hh", ".hpp",
        ".sql",
    }
)

#: 判定から除外するパス片。エージェント設定自身の編集や依存物の取り込みは対象外。
EXCLUDED_PATH_PARTS = (
    "/.claude/",
    "/node_modules/",
    "/build/",
    "/.gradle/",
    "/vendor/",
    "/.git/",
)

BLOCK_REASON = (
    "このセッションで実装コードまたはテストコードを編集しましたが、Sub Agent を一度も"
    "起動していません。\n"
    "\n"
    "AGENTS.md は V字開発と TDD を前提とし、フェーズ順序と承認ゲートを "
    "orchestrate-workflow Skill、各 Sub Agent の役割を .claude/agents/*.agent.md を"
    "正本と定めています。ハーネス側の既定方針よりこの規約が優先されます。\n"
    "\n"
    "次のいずれかを行ってください。\n"
    "\n"
    "1. 該当フェーズの Sub Agent を起動する（実装なら implementer → code-reviewer。"
    "要件・設計・テスト仕様に変更が及ぶ場合は該当フェーズの担当とレビュアーも経由する）\n"
    "2. フェーズ運用の対象外である場合は、その理由をユーザーへ明示して終了する"
    "（AGENTS.md はドキュメントの作成と改訂、アイデア出し、調査や Q&A を対象外と"
    "定めています。既存の要件・設計・テスト仕様に変更が及ばない修正も同様です）\n"
    "\n"
    "この通知はセッションごとに1回だけです。2を選ぶ場合は理由の説明を省略しないでください。"
)


def state_path(session_id: str) -> pathlib.Path:
    """セッション単位の状態ファイルのパス。"""
    safe = re.sub(r"[^A-Za-z0-9_.-]", "_", session_id or "unknown")[:128]
    directory = pathlib.Path(tempfile.gettempdir()) / "claude-subagent-gate"
    directory.mkdir(parents=True, exist_ok=True)
    return directory / f"{safe}.json"


def load_state(session_id: str) -> dict:
    path = state_path(session_id)
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}


def save_state(session_id: str, state: dict) -> None:
    try:
        state_path(session_id).write_text(
            json.dumps(state, ensure_ascii=False), encoding="utf-8"
        )
    except OSError:
        pass


def is_source_file(file_path: str) -> bool:
    """実装コードまたはテストコードと見なすか。"""
    if not file_path:
        return False
    normalized = file_path.replace("\\", "/")
    if any(part in normalized for part in EXCLUDED_PATH_PARTS):
        return False
    return pathlib.PurePosixPath(normalized).suffix.lower() in SOURCE_SUFFIXES


def read_payload() -> dict:
    try:
        raw = sys.stdin.read()
    except OSError:
        return {}
    if not raw.strip():
        return {}
    try:
        payload = json.loads(raw)
    except ValueError:
        return {}
    return payload if isinstance(payload, dict) else {}


def main(argv: list[str]) -> int:
    command = argv[1] if len(argv) > 1 else ""
    payload = read_payload()
    session_id = str(payload.get("session_id") or "")

    if command == "record-subagent":
        state = load_state(session_id)
        state["subagent_started"] = True
        save_state(session_id, state)
        return 0

    if command == "record-edit":
        tool_input = payload.get("tool_input")
        tool_input = tool_input if isinstance(tool_input, dict) else {}
        tool_response = payload.get("tool_response")
        tool_response = tool_response if isinstance(tool_response, dict) else {}
        file_path = str(
            tool_response.get("filePath") or tool_input.get("file_path") or ""
        )
        if is_source_file(file_path):
            state = load_state(session_id)
            state["source_edited"] = True
            save_state(session_id, state)
        return 0

    if command == "check-stop":
        state = load_state(session_id)
        if (
            state.get("source_edited")
            and not state.get("subagent_started")
            and not state.get("blocked_once")
        ):
            state["blocked_once"] = True
            save_state(session_id, state)
            json.dump(
                {"decision": "block", "reason": BLOCK_REASON},
                sys.stdout,
                ensure_ascii=False,
            )
        return 0

    return 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv))
    except Exception:  # フック自身の障害でユーザーの作業を止めない
        sys.exit(0)
