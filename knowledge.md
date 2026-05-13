# AI Agent Knowledge:

## For GitHub Copilot Agents

### 1. 全PJ共通（ホームディレクトリ）

```text
~/.copilot/
├── mcp-config.json            # ユーザー共通のMCP設定
├── instructions/
│   └── *.instructions.md      # ユーザー共通のパス別指示
├── agents/
│   └── <agent-name>.agent.md  # ユーザー共通エージェント
└── skills/
    └── <skill-name>/SKILL.md  # ユーザー共通スキル
```

- always-on 指示はユーザーレベルでは `~/.claude/CLAUDE.md` を配置する（VS Code が自動検出）。
- `~/.copilot/copilot-instructions.md` は存在しない。`copilot-instructions.md` はワークスペースレベル専用。

### 2. PJ固有（プロジェクトルート）

```text
[project]/.github/
├── copilot-instructions.md       # プロジェクト全体に適用される指示
├── instructions/
│   ├── backend.instructions.md  # パス別ルール（拡張子は .instructions.md 必須）
│   └── testing.instructions.md
├── prompts/
│   └── fix-bug.prompt.md        # 再利用可能なプロンプト（.prompt.md）
├── agents/
│   └── reviewer.agent.md        # プロジェクト専用エージェント（.md も検出される）
├── skills/
│   └── <skill-name>/SKILL.md    # プロジェクトスキル
└── hooks/
    └── <hook-name>.json          # 実行フック

[project]/.claude/                 # Claude 形式の代替配置（VS Code が自動検出）
├── agents/                        # .md ファイルを Claude 形式として検出
├── rules/                         # paths frontmatter で条件適用（applyTo の代わり）
└── skills/
```

### 3. 追加の重要ポイント（2026-05-13時点）

- always-on 指示は `copilot-instructions.md`、`AGENTS.md`、`CLAUDE.md` のいずれも利用可能。
- `AGENTS.md` はリポジトリ内の複数配置が可能で、近い階層のファイルが優先される（`chat.useNestedAgentsMdFiles` で有効化、experimental）。
- カスタムエージェントファイルの拡張子は `.agent.md`。ただし `.github/agents/` 内では素の `.md` も検出される。
- `.claude/agents/` 内の `.md` ファイルも Claude 形式として自動検出される（Claude Code との互換性）。**プロジェクトレベル（`[project]/.claude/agents/`）に加え、グローバル（`~/.claude/agents/`）も VS Code が検出する。`~/.copilot/agents/` と合わせてどちらに置いても有効。**
- `chat.agentFilesLocations` 設定で、エージェントファイルの追加検索パスを指定できる。
- Organization レベル（組織アカウント）のカスタムエージェントは `github.copilot.chat.organizationCustomAgents.enabled` で有効化。
- Organization レベルの指示は `github.copilot.chat.organizationInstructions.enabled` で有効化。
- エージェント間の handoffs（引き継ぎ）がサポートされており、frontmatter で定義可能。
- `/create-agent`、`/create-prompt`、`/create-instruction`、`/create-skill`、`/create-hook` コマンドで AI にカスタマイズファイルを生成させられる。
- Skills の `context: fork`（experimental）で、スキルを独立したサブエージェントコンテキストで実行可能。
- ユーザー指示ファイルは Settings Sync で同期可能（`Prompts and Instructions` を同期対象に選択）。
- Settings-based の code generation / test generation instructions は VS Code 1.102 で deprecated。file-based を使用すること。

## For Claude Code Agents

### 1. 全PJ共通（ホームディレクトリ）

```text
~/.claude/
├── CLAUDE.md              # ユーザー共通の指示（全プロジェクト）
├── settings.json          # ユーザースコープ設定
├── rules/
│   └── *.md               # パス別ルール
├── agents/
│   └── <agent>.md         # ユーザー共通エージェント
├── skills/
│   └── <skill>/SKILL.md   # ユーザー共通スキル
├── projects/
│   └── <project>/memory/  # Auto memory（Claude が自動蓄積する学習ノート）
└── (参照) ~/.claude.json  # ユーザー共通のMCP設定・各種状態
```

### 2. PJ固有（プロジェクトルート）

```text
[project]/
├── CLAUDE.md                    # プロジェクト共通の主要指示
├── CLAUDE.local.md              # 個人用・非共有の追記指示（gitignore推奨）
├── .mcp.json                    # MCPサーバーの project scope 設定
└── .claude/
    ├── CLAUDE.md                # （代替）プロジェクト指示配置場所
    ├── settings.json            # 共有設定（Git管理）
    ├── settings.local.json      # 個人ローカル設定（Git無視）
    ├── rules/
    │   └── *.md                 # パス別ルール（paths frontmatterで条件適用可）
    ├── agents/
    │   └── <agent>.md           # プロジェクト専用エージェント
    ├── skills/
    │   └── <skill>/SKILL.md     # プロジェクトスキル
    └── hooks/
        └── <script>.sh          # 実行フック（設定はsettings.json内のhooks）
```

### 3. 追加の重要ポイント（2026-05-13時点）

- 設定の優先度は概ね `Managed > CLI引数 > local(.claude/settings.local.json) > project(.claude/settings.json) > user(~/.claude/settings.json)`。配列設定はスコープ間でマージ（連結・重複除去）される。
- `CLAUDE.md` は `AGENTS.md` と互換ではないため、既存 `AGENTS.md` を流用したい場合は `CLAUDE.md` から `@AGENTS.md` で import する。シンボリックリンクでも可。
- path別ルールは `.claude/rules/*.md` の frontmatter `paths`（glob）で制御する。
- サブエージェントは `~/.claude/agents/`（全体）と `.claude/agents/`（PJ）で管理し、同名時は上位スコープが優先される。
- MCP は `.mcp.json`（project）または `~/.claude.json`（user/local）で管理し、`/mcp` で状態確認できる。
- Auto memory: Claude がセッション間で学習を自動蓄積する。`~/.claude/projects/<project>/memory/MEMORY.md` に保存され、先頭200行（または25KB）が毎回ロードされる。`/memory` で確認・編集可能。
- `/init` コマンドで CLAUDE.md を自動生成できる。既存ファイルがあれば改善提案を出す。
- `claudeMdExcludes` 設定でモノレポ内の不要な CLAUDE.md を除外できる。
- Plugin システム: マーケットプレイス経由で skills / agents / hooks / MCP サーバーを配布可能。`/plugin` で管理。
- 組織全体への Managed CLAUDE.md 配布が可能（MDM経由、`/Library/Application Support/ClaudeCode/CLAUDE.md` 等）。`claudeMd` 設定キーで `managed-settings.json` 内にインラインで記述も可。

## MCP

### GitHub MCP

#### 概要
- GitHubリソース（Repository / Issue / Pull Request / Release など）を、操作する
- コード検索、PR作成、Issue更新、ブランチ操作などを会話ベースで実行可能

### Serena MCP

#### 概要
- コードベースをシンボル単位で探索・編集し、プロジェクト全体の構造を把握する
- ファイル全体の読み込みを減らし、コンテキスト使用量を削減可能

## Skills

- [GitHub - google/skills: Agent Skills for Google products and technologies](https://github.com/google/skills)