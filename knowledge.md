# AI Agent Knowledge:

## AI Agent

### Overview

AI Agent とは、目標を渡すと自分で計画・実行・確認のループを回すAIのこと。
ChatGPTやGeminiなどのAIが「質問→回答で終わり」なのに対し、Agentはコード実行・ファイル操作・Web検索などのツールを使いながら複数ステップを自律的に進められる点が違い。

構成要素は LLM（頭脳）・Tools（手足）・Memory（記憶）・Instructions（行動ルール）の4つ。

**本ドキュメントに記載されていることは、2026-5-13時点の情報をもとにしており、今後のアップデートで仕様やベストプラクティスが変わる可能性が高いので、最新情報は公式ドキュメントやコミュニティを参照することを推奨します。**

### 各構成要素の概要

- **LLM（頭脳）** 自然言語を理解して次の行動を判断するモデル本体。GPT-4 や Claude など。
- **Tools（手足）** LLM が呼び出せる機能。コード実行・ファイル読み書き・Web検索・API呼び出しなど。ツールがないとAIは「考えるだけ」で何もできない。MCP、Skills、Sub Agentも広義のToolsと捉えられる（後述）
- **Memory（記憶）** 会話履歴や作業状態を保持する仕組み。短期（コンテキストウィンドウ）と長期（ファイルやDBへの保存）がある。
- **Instructions（行動ルール）** Agentに守らせるルールの文書。やること・やらないこと・優先順位を定義する。

### Session

Agentは、ユーザーからのプロンプトを受け取ると「Session」を開始する。Sessionは、Agentが目標達成のために行動を繰り返す一連のやりとりのこと。Session中、AgentはToolsを呼び出して情報を収集・操作し、その結果をもとに次の行動を決定する。Sessionは、目標が達成されるか、Agentが停止条件を満たすまで続く。

### Context

Context とは、LLM がある時点で参照できるトークン（情報）の全体で、Memoryの一部。
会話履歴・システムプロンプト・ツール定義・外部データ・ツール実行結果などすべてが含まれる、Agentにとっての「作業記憶」。短期コンテキストはSession内で共有されるが、長期記憶はSessionを跨いで保持されることが多い。

**＜重要！＞ Context Engineering** とは、この限られたコンテキストウィンドウに何を入れるかを設計・管理する技術で、「どう書くか」を扱うPrompt Engineeringの上位概念。Agentがループを回すほどデータが増えるため、どこまで1 Sessionで完結させるか、何を長期記憶に保持するかの判断が重要になる。

（参考）**Context Rot（文脈の劣化）** — トークン数が増えるほどモデルの情報想起精度が下がる現象。コンテキストは無限に詰め込めばよいわけではなく、量と精度はトレードオフ。「小さく・高密度に」保つことが品質維持のカギ。

- 参考: [Effective context engineering for AI agents – Anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

## Instructions (AGENTS.md)

Instructions とは、AI Agent に守らせたいルールや行動方針を記述する文書のこと。
命名規約、ディレクトリ方針、レビュー観点、テスト方針、禁止事項などを明文化し、Agentが毎回ゼロから判断しなくて済むようにするための「運用ルールの外部化」と捉えるとわかりやすい。`AGENTS.md`、`copilot-instructions.md`、`CLAUDE.md` などが代表例。

**＜重要！＞ Instruction Design** では、「何を書くか」だけでなく「どのスコープで効かせるか」を設計することが重要。全体ルールは always-on の指示ファイルに、特定ディレクトリや言語だけに効かせたいルールは file-based の instructions に分けると管理しやすい。Agentの挙動が不安定なときは、モデルの問題より先に Instructions の重複・競合・長文化を疑うべきことが多い。

（参考）Instructions の典型的な失敗は、ルールの重複や矛盾で優先順位が曖昧になること、長文化しすぎて重要ルールが埋もれること、実態に合わない古い指示を放置すること。短く・命令形で・1ファイル1責務を意識すると安定しやすい。

- 参考: [AGENTS.md](https://agents.md/)

## Directory Structure

### For GitHub Copilot Agent

#### 1. 全PJ共通（ホームディレクトリ）

```text
~/.copilot/
├── mcp-config.json  # ユーザー共通のMCP設定
├── instructions/
│   └── *.instructions.md  # ユーザー共通のパス別指示（applyTo frontmatterで条件適用）
├── agents/
│   └── <agent-name>.agent.md  # ユーザー共通エージェント
└── skills/
     └── <skill-name>/SKILL.md  # ユーザー共通スキル
```

- GlobalなInstructionsは、`applyTo: '**' `を指定した`~/.copilot/instructions/*.instructions.md`に記述する。ただし、Claude Codeとの両立のため、`~/.claude/CLAUDE.md` を使用することを推奨（VS Code Version 1.109より自動検出）。

#### 2. PJ固有（プロジェクトルート）

```text
[project]/.github/
├── copilot-instructions.md  # プロジェクト全体に適用される指示
├── instructions/
│   ├── backend.instructions.md  # パス別ルール（拡張子は .instructions.md 必須）
│   └── testing.instructions.md
├── prompts/
│   └── fix-bug.prompt.md  # 再利用可能なプロンプト（.prompt.md）
├── agents/
│   └── reviewer.agent.md  # プロジェクト専用エージェント（.md も検出される）
├── skills/
│   └── <skill-name>/SKILL.md  # プロジェクトスキル
└── hooks/
    └── <hook-name>.json  # 実行フック
```

#### 3. 重要ポイント（2026-05-13時点）

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

### For Claude Code Agent

#### 1. 全PJ共通（ホームディレクトリ）

```text
~/.claude/
├── CLAUDE.md  # ユーザー共通の指示（全プロジェクト）
├── settings.json  # ユーザースコープ設定
├── rules/
│   └── *.md  # パス別ルール
├── agents/
│   └── <agent>.md  # ユーザー共通エージェント
├── skills/
│   └── <skill>/SKILL.md  # ユーザー共通スキル
├── projects/
│   └── <project>/memory/  # Auto memory（Claude が自動蓄積する学習ノート）
└── (参照) ~/.claude.json  # ユーザー共通のMCP設定・各種状態
```

#### 2. PJ固有（プロジェクトルート）

```text
[project]/
├── CLAUDE.md  # プロジェクト共通の主要指示
├── CLAUDE.local.md  # 個人用・非共有の追記指示（gitignore推奨）
├── .mcp.json  # MCPサーバーの project scope 設定
└── .claude/
    ├── CLAUDE.md  # （代替）プロジェクト指示配置場所
    ├── settings.json  # 共有設定（Git管理）
    ├── settings.local.json  # 個人ローカル設定（Git無視）
    ├── rules/
    │   └── *.md  # パス別ルール（paths frontmatterで条件適用可）
    ├── agents/
    │   └── <agent>.md  # プロジェクト専用エージェント
    ├── skills/
    │   └── <skill>/SKILL.md  # プロジェクトスキル
    └── hooks/
        └── <script>.sh  # 実行フック（設定はsettings.json内のhooks）
```

#### 3. 重要ポイント（2026-05-13時点）

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

| 観点 | 内容 |
|---|---|
| **何？** | MCP（Model Context Protocol）は、AI Agentが外部ツールやデータソースに安全に接続するための共通プロトコル。LLM単体では触れない外部操作を標準化して扱える |
| **使い所** | GitHub操作、コードベース探索、社内データ参照など、会話だけでは完結しない作業を Agent に実行させたいとき |
| **メリット** | ツール連携を統一的に扱える / Agentごとの機能差分を吸収しやすい / 実運用で必要な自動化を会話に統合しやすい |
| **デメリット** | 接続先が増えると権限・監査の設計が複雑になる / サーバー停止時にワークフローが詰まる / 雑な公開設定だと情報漏えいリスクが上がる |
| **最小運用** | ①read-only用途のMCPから導入する ②権限を最小化する ③失敗時フォールバック（手動手順）を定義する |

### 実践のコツ

**設計フェーズ**
- まずは「1業務1MCP」を原則にし、用途ごとに責務を分離する（GitHub操作系、コード探索系など）
- Agentに渡すMCPは必要最小限に絞る。使わないサーバーは接続しない
- 可用性を前提にしすぎない。接続失敗時の代替手順を設計時点で決める

**権限と安全**
- 認証情報は最小権限トークンを使う（read/writeを安易に混在させない）
- 高リスク操作（PR merge、削除、書き込み）は人間承認ステップを挟む
- ログを残し、だれがどのMCP経由で何をしたか追跡可能にする

**コンテキスト最適化**
- MCPから得た生データをそのまま会話に貼らず、要点要約して返す
- 大きいレスポンスは段階取得（一覧 -> 詳細）で読む
- Context肥大が見えたら Sub Agent へ逃がして結果だけ親に戻す

**運用改善**
- エラーは「認証」「権限不足」「対象未存在」「タイムアウト」に分類して再試行ポリシーを分ける
- 定期的に不要なMCP接続を棚卸しして削減する
- ワークフローが固まってきたら Skill化して再利用する

### GitHub MCP

#### 概要
- GitHubリソース（Repository / Issue / Pull Request / Release など）を会話ベースで操作する
- コード検索、PR作成、Issue更新、ブランチ操作などを Agent から実行できる

#### 実践のコツ
- 最初は read-only（検索・参照）から開始し、書き込み系は段階的に開放する
- 直接 merge や delete を許す前に、レビュー・承認フローを先に固定する
- 組織運用では repository 単位でアクセス境界を分け、誤操作範囲を局所化する

### Serena MCP

#### 概要
- コードベースをシンボル単位で探索・編集し、構造を把握しながら変更できる
- ファイル全読みを減らし、コンテキスト消費を抑えつつ精度高く修正しやすい

#### 実践のコツ
- まず overview -> symbol pinpoint の順に読む（いきなり全文読まない）
- 変更はシンボル単位で行い、影響箇所は参照検索で追跡する
- 大規模修正は先に対象シンボルを列挙してから編集し、取りこぼしを防ぐ

## Sub Agent

| 観点 | 内容 |
|---|---|
| **何？** | 役割を分けた小さな担当AI（調査専任・レビュー専任など）。別コンテキストで動き最後に要約だけ返す |
| **使い所** | 長い出力を本筋から分離 / ツール権限を役割別に分ける / 並列調査で時短 |
| **メリット** | 文脈節約 / 品質安定 / 最小権限で安全運用 |
| **デメリット** | 設計複雑化 / 遅延・コスト増 / 引き継ぎ設計が甘いと情報抜け |
| **最小運用** | ①1つだけ作る（例: read-only の Explore 担当） ②入出力を固定する ③停止条件を決める（最大ターン数・タイムアウト・フォールバック） |

### 実践のコツ

**設計フェーズ**
- 最初は read-only の調査専用Agentを1つ作るだけにする。書き込み・削除権限は慣れてから追加する
- 1 Sub Agent = 1責務。役割が「〜か〜のどちらか」になったら分割サイン
- 並列実行するAgentが同じファイルを書き変えないよう、作業領域（ファイル・ブランチ等）を事前に分割する

**引き継ぎ（Handoff）の設計**
- 親Agentから渡すコンテキストは「目的・制約・出力形式」の3点だけに絞る。詳細を全部渡すと Sub Agentの文脈節約メリットが消える
- Sub Agentが返す内容は**要約のみ**（目安: 1,000〜2,000トークン）。生のツール実行結果をそのまま返さない
- 引き継ぎ失敗のフォールバック（「取得できなかった場合は○○」）を親側で必ず定義する

**停止条件**
- 最大ターン数・タイムアウト・失敗時の挙動を必ず指定する（指定がないと無限ループリスク）
- Sub Agent が異常終了した場合、親Agentが検知してリトライするか諦めるかを決めておく

**デバッグ・観測**
- 入出力をログに残しておくと、どのAgentで情報が欠落したか追跡しやすい
- 最初は逐次実行（直列）で動作を確認してから、並列化に移行する

## Skills

| 観点 | 内容 |
|---|---|
| **何？** | Skills は `SKILL.md` を中心にした再利用可能な能力パッケージ（手順・スクリプト・参照資料）。Agent Skills 標準に沿って複数エージェント間で移植しやすい |
| **使い所** | 毎回同じ手順を繰り返す作業（テスト実行、デバッグ、デプロイ手順、レビュー観点）を定型化したいとき |
| **メリット** | 指示の再利用・品質の平準化・オンデマンド読み込みでコンテキスト節約（必要なときだけ本体/追加ファイルをロード） |
| **デメリット** | `name`/ディレクトリ名不一致や frontmatter 不備で「静かに読み込まれない」ことがある。Skill自体が悪いと誤誘導を再利用してしまう |
| **最小運用** | ①1 Skill = 1ワークフローにする ②`name` とフォルダ名を一致させる ③`description` に「何をするか + いつ使うか」を明記する |

### 実践のコツ

**設計フェーズ**
- まずは「繰り返し頻度が高い作業」から1つだけ Skill 化する
- `SKILL.md` 本文は短く保ち、詳細手順は `references/` や `scripts/` に分割する
- 命名は検索しやすい具体語にする（例: `github-actions-debugging`）

**メタデータ（frontmatter）**
- `name` は小文字・数字・ハイフンのみで、親ディレクトリ名と一致させる
- `description` は「何をするか」だけでなく「いつ使うか」まで書く（自動選択精度に効く）
- 必要なら `user-invocable` / `disable-model-invocation` で「手動専用」か「自動読込可」かを制御する

**読み込みとコンテキスト最適化**
- Skills は段階的ロードされる前提で設計する（metadata -> `SKILL.md` 本文 -> 参照ファイル）
- 巨大な本文を避け、参照ファイルをリンクで明示して必要時のみ読ませる
- 調査系や長い処理は `context: fork`（experimental）でサブエージェント実行に寄せるとメイン文脈を汚しにくい

**安全運用**
- Skill は「権限を持つ指示 + 実行資産」としてレビューする（未検証の外部Skillをそのまま使わない）
- 高リスク操作（書き込み・削除・外部送信）は承認ステップを必ず挟む
- エンドユーザーに任意 Skill を自由選択させる設計は避け、用途ごとに許可済み Skill を束ねる

**Sub Agent と組み合わせるとき**
- Sub Agent 側 `skills` で事前ロードするか、実行中に Skill ツールで都度呼ぶかを使い分ける
- 長文出力を返す Skill は Sub Agent 経由にして、親には要約だけ返す設計にする
- 「Skillで手順を標準化」「Sub Agentで文脈を分離」の二段構えが安定しやすい

- 参考: [Use Agent Skills in VS Code](https://code.visualstudio.com/docs/copilot/customization/agent-skills)
- 参考: [Agent Skills Specification](https://agentskills.io/specification)
- 参考: [OpenAI Skills Guide](https://developers.openai.com/api/docs/guides/tools-skills)
- 参考: [Claude Code - Create custom subagents](https://code.claude.com/docs/en/sub-agents)
- 参考: [GitHub - google/skills: Agent Skills for Google products and technologies](https://github.com/google/skills)

## Hooks

| 観点 | 内容 |
|---|---|
| **何？** | Hooks は、セッションやツール実行の特定イベントで自動実行される処理。コマンド・HTTP・MCPツール・Prompt評価・Agent評価を差し込める |
| **使い所** | 危険コマンドのブロック、編集後の自動検査、ログ収集、サブエージェント開始/終了時の監査、環境変数の自動セットアップ |
| **メリット** | ルールを実行可能な形で強制できる / 人手チェック漏れを減らせる / 運用ポリシーを一元化しやすい |
| **デメリット** | 設定が複雑化しやすい / 遅いフックで体験が悪化する / 誤設定すると必要な操作まで止める |
| **最小運用** | ①`PreToolUse` で危険操作だけ防ぐ ②`PostToolUse` で軽い検査を追加する ③同期で安定化してから `async` 化する |

### 実践のコツ

**設計フェーズ**
- まずは「壊れると困る操作」のガードから始める（例: `rm -rf`、本番向けの書き込み）
- フックごとに目的を1つに絞る（ブロック用、監査用、通知用を分離）
- イベントを増やしすぎない。最初は `PreToolUse` / `PostToolUse` / `SessionStart` の3つ程度で十分

**ブロック制御の要点**
- コマンドフックでブロックしたい場合、基本は `exit 2` を使う（通常の `exit 1` は多くのイベントで非ブロッキング）
- `PreToolUse` は専用フィールド（`permissionDecision: allow/deny/ask/defer`）で制御する
- JSON出力で制御する場合は `exit 0` とセット運用に統一する（`exit 2` 時はJSONが無視される）

**パフォーマンス**
- 重い処理（テスト、外部API照会）は `PostToolUse` + `async: true` に寄せる
- 同期フックは「短い・決定的」なものだけに限定する
- matcher/if で対象を狭め、不要なフック起動を減らす

**安全運用**
- フックはユーザー権限で任意コマンドを実行できる前提でレビューする
- パス・入力値は必ずバリデーションする（パストラバーサル、危険引数を遮断）
- 組織運用では managed 設定で強制し、ローカル設定との差分を監査する

**Sub Agent / Skill と組み合わせるとき**
- Sub Agent開始時は `SubagentStart`、完了時は `SubagentStop` で監査ログを残す
- Skill前提のコマンド実行は `UserPromptExpansion` / `PreToolUse` でガードして、直接実行ルートも塞ぐ
- ルールを「文章（Instructions）」だけでなく「実行（Hooks）」で二重化すると運用品質が安定する

- 参考: [Claude Code - Hooks reference](https://code.claude.com/docs/en/hooks)
- 参考: [Automate workflows with hooks](https://code.claude.com/docs/en/hooks-guide)

## Prompts

| 観点 | 内容 |
|---|---|
| **何？** | Prompts は再利用可能なスラッシュコマンド化プロンプト（`.prompt.md`）。毎回の指示文をテンプレ化して呼び出せる |
| **使い所** | 定型タスク（レビュー依頼、PR本文生成、テストケース作成、説明文生成）を短いコマンドで再現したいとき |
| **メリット** | 手順の再現性が高い / 入力揺れを減らせる / `agent`・`tools`・`model` をタスク単位で切り替えられる |
| **デメリット** | 汎用化しすぎると曖昧になる / 古い前提のまま放置すると誤誘導する / 似たPromptが増えると管理コストが上がる |
| **最小運用** | ①利用頻度トップ3の定型タスクを `.prompt.md` 化する ②入出力例を明記する ③月1で棚卸しして統合・削除する |

### 実践のコツ

**設計フェーズ**
- Promptは「1タスク1成果物」に絞る（複数目的を混ぜない）
- 冒頭で期待アウトプット形式を固定する（箇条書き、表、パッチ方針など）
- 可変部分は `${input:...}` や引数で受ける設計にして、本文を短く保つ

**frontmatter活用**
- `name` と `description` は検索される前提で具体語を入れる
- 必要なら `agent` を指定して実行モードを固定する（ask/agent/plan/カスタムagent）
- `tools` を明示して最小権限化する。Prompt側ツール指定は高い優先度で適用される

**品質を上げる書き方**
- 「目的」「入力」「出力」「制約」を4ブロックで書くと崩れにくい
- 入出力のサンプルを1つ入れると再現性が上がる
- 共通ルールはInstructionsへ、タスク固有手順だけPromptへ書く（重複を避ける）

**運用と保守**
- `/` 実行時に引数が不足しやすいPromptには `argument-hint` を必ず付ける
- テストはエディタの実行ボタンで短いケースから回し、失敗例をそのまま改善材料にする
- 使われていないPromptは削除・統合して、候補一覧を軽く保つ

**Skill / Sub Agent との使い分け**
- 軽量で単発: Prompt
- 手順 + スクリプト + 参照資料まで含む再利用: Skill
- 長時間処理や大量出力の隔離: Sub Agent

- 参考: [Use prompt files in VS Code](https://code.visualstudio.com/docs/copilot/customization/prompt-files)
- 参考: [Use Agent Skills in VS Code](https://code.visualstudio.com/docs/copilot/customization/agent-skills)
