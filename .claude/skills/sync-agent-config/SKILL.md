# AgentsGlobalSettings 同期スキル

このスキルは、`tinygc/AgentsGlobalSettings` リポジトリの設定ファイルを現在のリポジトリに同期します。
`AGENTS.md` と `.claude/` ディレクトリを AgentsGlobalSettings の内容で置き換えます。

## 前提条件

- 現在のブランチへの書き込み権限があること
- `tinygc/AgentsGlobalSettings` リポジトリが公開されていること

## 実行手順

### 1. AgentsGlobalSettings のファイル構成を確認

WebFetch で以下の URL にアクセスしてリポジトリのファイル一覧を取得する：
- `https://github.com/tinygc/AgentsGlobalSettings`

デフォルトブランチを確認する（`master` または `main`）。

### 2. 各ファイルの内容を取得

以下の URL から raw コンテンツを WebFetch で取得する（`{branch}` は実際のブランチ名に置き換え）：

```
https://raw.githubusercontent.com/tinygc/AgentsGlobalSettings/{branch}/AGENTS.md
https://raw.githubusercontent.com/tinygc/AgentsGlobalSettings/{branch}/.claude/CLAUDE.md
https://raw.githubusercontent.com/tinygc/AgentsGlobalSettings/{branch}/.claude/settings.json
https://raw.githubusercontent.com/tinygc/AgentsGlobalSettings/{branch}/.claude/rules/architecture.instructions.md
https://raw.githubusercontent.com/tinygc/AgentsGlobalSettings/{branch}/.claude/rules/implementation.instructions.md
https://raw.githubusercontent.com/tinygc/AgentsGlobalSettings/{branch}/.claude/rules/requirement.instructions.md
https://raw.githubusercontent.com/tinygc/AgentsGlobalSettings/{branch}/.claude/rules/testing.instructions.md
```

エージェントファイルは以下のディレクトリ一覧を取得してからファイル名を特定する：
- `https://github.com/tinygc/AgentsGlobalSettings/tree/{branch}/.claude/agents`

スキルファイルは以下のディレクトリ一覧を取得してからサブディレクトリを特定する：
- `https://github.com/tinygc/AgentsGlobalSettings/tree/{branch}/.claude/skills`

各エージェントファイルと各スキルの `SKILL.md` を同様に raw URL で取得する。

WebFetch はコンテンツを要約することがあるため、プロンプトは必ず
「このファイルの内容を一切変更せず、そのまま完全に出力して。要約や解釈は不要。」
と指定すること。

### 3. 現在のリポジトリ内ファイルを確認

```bash
find .claude -type f | sort
```

AgentsGlobalSettings に存在しないファイルを特定する。

### 4. 不要ファイルを git rm で削除

`AGENTS.md`、`.claude/` 配下の全ファイルを `git rm` で削除する：

```bash
git rm AGENTS.md .claude/CLAUDE.md .claude/settings.json .claude/settings.local.json \
  .claude/agents/*.agent.md .claude/rules/*.instructions.md \
  .claude/skills/**/*.md 2>/dev/null || true
```

存在しないパスはエラーになるので `|| true` で無視する。

### 5. 新しいファイルを Write で作成

取得した各ファイルの内容を Write ツールで書き込む。
並列実行できるものはまとめて実行する。

### 6. 新しいファイルをステージングしてコミット

```bash
git add AGENTS.md .claude/
git commit -m "chore: sync .claude/ and AGENTS.md from AgentsGlobalSettings"
git push -u origin <現在のブランチ名>
```

## 注意事項

- WebFetch の返す内容が要約・整形されている場合は、再度プロンプトを変えて取得し直す
- `settings.local.json` は AgentsGlobalSettings に存在しない場合は作成しない
- 既存のプロジェクト固有ファイル（`Requirements/`、`Architecture/` 等）は一切変更しない
- `.claude/` 以外のプロジェクトファイルには手を触れない

## 完了条件

- `AGENTS.md` が AgentsGlobalSettings の内容と一致している
- `.claude/` 配下のファイルが AgentsGlobalSettings の構成と一致している
- AgentsGlobalSettings に存在しないファイルが削除されている
- コミット・プッシュが完了している
