# settings

Claude Code / GitHub Copilot / OpenAI Codex CLI 向けのグローバル設定リポジトリ。

`install.sh` を実行すると `~/.claude/` にルール・エージェント・スキルなどを配置し、あわせて `~/AGENTS.md` も更新する。  
GitHub Copilot (VS Code) は `~/.claude/` を自動検出するため、両ツールで設定を共有できる。  
OpenAI Codex CLI はグローバル指示を `~/.codex/AGENTS.md` から読む（`~/AGENTS.md` は参照しない）ため、`install.sh` は `AGENTS.md` を `~/.codex/AGENTS.md` にも配置する。

## 構成

```
AGENTS.md                 # グローバル共通指示（言語・トーン・開発プロセス）
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
- `AGENTS.md` は Codex 用に `~/.codex/AGENTS.md` にもコピーされる（既存があればバックアップ。`~/.codex/` 内の `config.toml` や `auth.json` は削除・変更しない）

インストール後の主な配置先は以下のとおり。

```text
~/AGENTS.md
~/.codex/AGENTS.md
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
