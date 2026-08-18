# settings

Claude Code / GitHub Copilot / OpenAI Codex CLI 向けのグローバル設定リポジトリ。

`install.sh` を実行すると、Claude Code / GitHub Copilot / OpenAI Codex CLI が同じ方針を読める場所へ設定を配置する。
共通指示の正本は `AGENTS.md` とし、Claude Code は `~/.claude/CLAUDE.md` から import、GitHub Copilot は `~/.github/copilot-instructions.md`、GitHub Copilot CLI は `AGENTS.md` から生成した `~/.copilot/copilot-instructions.md`、GitHub Copilot for VS Code は `~/.copilot/instructions/agents-global.instructions.md`、OpenAI Codex CLI は `~/.codex/AGENTS.md` として同じ内容を参照する。
スキルは Claude Code 向けに `~/.claude/skills/`、Codex 向けに `~/.agents/skills/` へ配置する。Sub Agent は Claude Code 向けに `~/.claude/agents/` へコピーし、Codex 向けには `.claude/agents/*.agent.md` から `~/.codex/agents/*.toml` を生成する。

## 構成

```
AGENTS.md                 # グローバル共通指示（言語・トーン・開発プロセス）
.github/
  copilot-instructions.md # GitHub Copilot 用の共通指示ミラー
install.sh                # Linux / macOS / Git Bash 向けインストーラ
install.cmd               # Windows 向け起動ラッパー（ExecutionPolicy Bypass）
install.ps1               # Windows PowerShell 向けインストーラ本体
knowledge.md              # 設定体系のリファレンスメモ
.claude/
  CLAUDE.md               # @../AGENTS.md を import
  settings.json           # Claude Code 設定
  settings.local.json     # ローカル設定
  rules/                  # applyTo ルール（*.instructions.md）
  agents/                 # カスタムエージェント（*.agent.md）
  skills/                 # スキル定義（<name>/SKILL.md）
    orchestrate-workflow/ # V字開発フローの進行管理
    session-retrospective/ # セッション振り返りと改善反映
  hooks/                  # フック（.gitkeep）
```

## インストール

```sh
git clone https://github.com/tinygc/AgentsGlobalSettings.git
cd AgentsGlobalSettings
sh install.sh
```

Windows では以下を実行する。

```bat
.\install.cmd
```

PowerShell から `install.ps1` を直接実行して署名エラーが出る環境では、次のどちらかを使う。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

```powershell
Unblock-File .\install.ps1
.\install.ps1
```

### Windows 対応

- `install.sh` は POSIX sh 向けのため、Windows では Git Bash または WSL から実行する
- PowerShell の実行ポリシーで未署名スクリプトがブロックされる場合があるため、Windows ではまず `install.cmd` を使う
- PowerShell のみで実行したい場合は `powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1` を使う
- `install.sh` / `install.cmd` / `install.ps1` は同じ配置先へ同じ設定をコピーする

### インストール時の挙動

- 既存の `~/.claude/` はタイムスタンプ付きで `~/.settings-backup/` にバックアップされる
- バックアップ後、`~/.claude/` は再作成され、このリポジトリ内の `.claude/` 配下がコピーされる
- `AGENTS.md` は `~/AGENTS.md` にコピーされる
- GitHub Copilot 用の `~/.github/copilot-instructions.md` は `AGENTS.md` から生成される（既存があればバックアップ）
- GitHub Copilot CLI 用の `~/.copilot/copilot-instructions.md` は `AGENTS.md` から生成される（既存があればバックアップ）
- GitHub Copilot for VS Code 用の `~/.copilot/instructions/agents-global.instructions.md` は `AGENTS.md` から生成される（既存があればバックアップ）
- `AGENTS.md` は Codex 用に `~/.codex/AGENTS.md` にもコピーされる（既存があればバックアップ。`~/.codex/` 内の `config.toml` や `auth.json` は削除・変更しない）
- `.claude/agents/*.agent.md` は Codex custom agents 用の TOML に変換され、`~/.codex/agents/*.toml` に生成される（既存があればバックアップ）
- `.claude/skills/` 配下の各スキルは Codex 用に `~/.agents/skills/` にもコピーされる（`~/.agents/skills/` 全体はバックアップされるが削除はされず、このリポジトリと同名のスキルのみ置き換える）

インストール後の主な配置先は以下のとおり。

```text
~/AGENTS.md
~/.github/copilot-instructions.md
~/.copilot/copilot-instructions.md
~/.copilot/instructions/agents-global.instructions.md
~/.codex/AGENTS.md
~/.codex/agents/
~/.agents/skills/
~/.claude/CLAUDE.md
~/.claude/settings.json
~/.claude/settings.local.json
~/.claude/rules/
~/.claude/agents/
~/.claude/hooks/
~/.claude/skills/
```

## Sub Agent のモデルと effort

`.claude/agents/*.agent.md` の frontmatter で、Sub Agent ごとに使用モデル（`model`）と推論の深さ（`effort`）を指定する。
V字開発フローでは上流工程の判断ミスが下流全体へ波及するため、要件・設計・テスト設計とコードレビューに厚く配分し、照合作業が中心のレビューは軽くする方針を採る。

| Agent | model | effort | 配分の理由 |
|---|---|---|---|
| requirements-analyst | opus | xhigh | 曖昧表現の検出と抜け漏れの洗い出しが全下流の起点になる |
| requirements-reviewer | opus | xhigh | 最初の承認ゲート。ここでの見逃しが最も高くつく |
| architect | opus | xhigh | レイヤー分離の判断と FR トレーサビリティの設計 |
| architect-reviewer | opus | xhigh | 設計と UI 仕様の整合という複合判定 |
| ui-designer | sonnet | （未指定） | 仕様の記述作業が中心。セッションの effort を継承する |
| ui-reviewer | sonnet | high | 必須項目の照合が中心 |
| test-designer | opus | xhigh | 境界値・異常系の網羅設計。抜けが致命的になる |
| test-reviewer | sonnet | medium | トレーサビリティマトリクスの照合は機械的作業 |
| implementer | sonnet | high | TDD の反復。Sonnet の適性に合う |
| code-reviewer | opus | xhigh | 実装コードに向き合う唯一のレビュアー |

### 注意点

- **`model` に使えるのはエイリアスかフルモデルID**。エイリアスは `default` / `best` / `fable` / `sonnet` / `opus` / `haiku` / `sonnet[1m]` / `opus[1m]` / `opusplan`、および `inherit`。`fable-5` のような存在しない値を書くと `[claude-code:unrecognized_model]` 警告となり、意図したモデルで動かない
- **`model` を省略すると `inherit`**（メインセッションと同じモデル）になる
- **`fable` はグローバル設定に固定しない**。プランによっては usage credits 課金となり、ZDR 環境では選択できないため、配布先の環境によって動作が変わる
- **`effort` に使えるのは `low` / `medium` / `high` / `xhigh` / `max`**。省略時はセッションの effort を継承する。モデルが未対応のレベルを指定した場合はエラーにならず、直下の対応レベルへフォールバックする（Opus 4.6 では `xhigh` → `high`）
- **`max` は広く採用しない**。demanding なタスクで効果が出る場合はあるが、収穫逓減があり overthinking しやすいため、採用前に検証する
- **環境変数は frontmatter より優先される**。`CLAUDE_CODE_SUBAGENT_MODEL` は全 Sub Agent の `model` を、`CLAUDE_CODE_EFFORT_LEVEL` は `effort` を上書きする。これらが設定された環境では上表の指定は効かない。逆に、コストを抑えたいセッションでは一時的な上書き手段として使える
- **`model` と `effort` は Claude Code 専用**。`install.sh` が生成する Codex 用 TOML（`~/.codex/agents/*.toml`）は `name` / `description` / 本文のみを取り込むため、Codex 側の挙動には影響しない

参考: [Subagents](https://code.claude.com/docs/en/sub-agents) / [Model configuration](https://code.claude.com/docs/en/model-config)

## 要件

- POSIX sh（`install.sh` を使う場合）
- Windows PowerShell 5.1+ / PowerShell 7+（`install.ps1` を使う場合）
- Linux / macOS / Windows

## セッション改善運用

Agent での作業後に、進行不良やユーザー指摘を次回運用へ反映する場合は、`.claude/skills/session-retrospective/SKILL.md` の形式で振り返りを実施する。

- 反映先の例:
  - Sub Agent 定義: `.claude/agents/*.agent.md`
  - Skill 手順: `.claude/skills/*/SKILL.md`
  - ルール: `.claude/rules/*.instructions.md`
  - グローバル方針: `AGENTS.md`
