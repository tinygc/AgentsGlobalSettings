# settings

Claude Code / GitHub Copilot 向けのグローバル設定リポジトリ。

`install.sh` を実行すると `~/.claude/` にルール・エージェント・スキルなどをデプロイする。  
GitHub Copilot (VS Code) は `~/.claude/` を自動検出するため、両ツールで設定を共有できる。

## 構成

```
AGENTS.md                 # グローバル共通指示（言語・トーン・開発プロセス）
install.sh                # インストーラ（バックアップ → 削除 → コピー）
knowledge.md              # 設定体系のリファレンスメモ
.claude/
  CLAUDE.md               # @../AGENTS.md を import
  settings.json           # Claude Code 設定
  settings.local.json     # ローカル設定（Git 管理外向け）
  rules/                  # applyTo ルール（*.instructions.md）
  agents/                 # カスタムエージェント（*.agent.md）
  skills/                 # スキル定義（<name>/SKILL.md）
  hooks/                  # フック（.gitkeep）
```

## インストール

```sh
git clone https://github.com/tinygc/AgentsGlobalSettings.git
cd AgentsGlobalSettings
sh install.sh
```

既存の `~/.claude/` はタイムスタンプ付きで `~/.settings-backup/` にバックアップされる。

## 要件

- POSIX sh
- Linux / macOS
