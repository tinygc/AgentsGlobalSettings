# settings

Claude Code / GitHub Copilot / OpenAI Codex CLI 向けのグローバル設定リポジトリ。

`install.sh` を実行すると、Claude Code / GitHub Copilot / OpenAI Codex CLI が同じ方針を読める場所へ設定を配置する。
共通指示の正本は `AGENTS.md` とし、Claude Code は `~/.claude/CLAUDE.md` から import、GitHub Copilot は `~/.github/copilot-instructions.md`、OpenAI Codex CLI は `~/.codex/AGENTS.md` として同じ内容を参照する。
スキルは Claude Code 向けに `~/.claude/skills/`、Codex 向けに `~/.agents/skills/` へ配置する。

## 構成

```
AGENTS.md                 # グローバル共通指示（言語・トーン・開発プロセス）
.github/
  copilot-instructions.md # GitHub Copilot 用の共通指示ミラー
install.sh                # インストーラ（バックアップ → 削除 → コピー）
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

### インストール時の挙動

- 既存の `~/.claude/` はタイムスタンプ付きで `~/.settings-backup/` にバックアップされる
- バックアップ後、`~/.claude/` は再作成され、このリポジトリ内の `.claude/` 配下がコピーされる
- `AGENTS.md` は `~/AGENTS.md` にコピーされる
- `.github/copilot-instructions.md` は GitHub Copilot 用に `~/.github/copilot-instructions.md` にコピーされる
- `AGENTS.md` は Codex 用に `~/.codex/AGENTS.md` にもコピーされる（既存があればバックアップ。`~/.codex/` 内の `config.toml` や `auth.json` は削除・変更しない）
- `.claude/skills/` 配下の各スキルは Codex 用に `~/.agents/skills/` にもコピーされる（`~/.agents/skills/` 全体はバックアップされるが削除はされず、このリポジトリと同名のスキルのみ置き換える）

インストール後の主な配置先は以下のとおり。

```text
~/AGENTS.md
~/.github/copilot-instructions.md
~/.codex/AGENTS.md
~/.agents/skills/
~/.claude/CLAUDE.md
~/.claude/settings.json
~/.claude/settings.local.json
~/.claude/rules/
~/.claude/agents/
~/.claude/hooks/
~/.claude/skills/
```

## 要件

- POSIX sh
- Linux / macOS

## セッション改善運用

Agent での作業後に、進行不良やユーザー指摘を次回運用へ反映する場合は、`.claude/skills/session-retrospective/SKILL.md` の形式で振り返りを実施する。

- 反映先の例:
  - Sub Agent 定義: `.claude/agents/*.agent.md`
  - Skill 手順: `.claude/skills/*/SKILL.md`
  - ルール: `.claude/rules/*.instructions.md`
  - グローバル方針: `AGENTS.md`
