#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CLAUDE_TARGET="$HOME/.claude"
CODEX_TARGET="$HOME/.codex"
AGENTS_SKILLS_TARGET="$HOME/.agents/skills"
CODEX_AGENTS_TARGET="$HOME/.codex/agents"
COPILOT_WORKSPACE_TARGET="$HOME/.github/copilot-instructions.md"
COPILOT_CLI_TARGET="$HOME/.copilot/copilot-instructions.md"
COPILOT_VSCODE_TARGET="$HOME/.copilot/instructions/agents-global.instructions.md"
BACKUP_ROOT="$HOME/.settings-backup"
BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"

copy_file() {
  src=$1
  dest=$2

  if [ ! -f "$src" ]; then
    printf 'missing source file: %s\n' "$src" >&2
    exit 1
  fi

  mkdir -p "$(dirname -- "$dest")"
  cp "$src" "$dest"
}

copy_dir() {
  src=$1
  dest=$2

  if [ ! -d "$src" ]; then
    printf 'missing source directory: %s\n' "$src" >&2
    exit 1
  fi

  mkdir -p "$(dirname -- "$dest")"
  cp -R "$src" "$dest"
}

write_copilot_instructions() {
  src=$1
  dest=$2
  frontmatter=${3:-false}

  if [ ! -f "$src" ]; then
    printf 'missing source file: %s\n' "$src" >&2
    exit 1
  fi

  mkdir -p "$(dirname -- "$dest")"
  {
    if [ "$frontmatter" = "true" ]; then
      printf '%s\n' '---'
      printf 'applyTo: "**"\n'
      printf '%s\n\n' '---'
    fi
    printf '# GitHub Copilot instructions\n\n'
    printf 'This file mirrors the shared global agent instructions used by Claude Code and OpenAI Codex.\n\n'
    printf '> Source of truth: `AGENTS.md`\n\n'
    cat "$src"
  } > "$dest"
}

toml_escape_basic_string() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

agent_frontmatter_value() {
  key=$1
  src=$2
  awk -v key="$key" -v q="'" '
    NR == 1 {
      line = $0
      sub(/\r$/, "", line)
      if (line == "---") {
        in_frontmatter = 1
        next
      }
      exit
    }
    in_frontmatter {
      line = $0
      sub(/\r$/, "", line)
      if (line == "---") {
        exit
      }
      pattern = "^" key ":[[:space:]]*"
      if (line ~ pattern) {
        sub(pattern, "", line)
        sub(/[[:space:]]*$/, "", line)
        if ((line ~ /^"[^"]*"$/) || (line ~ "^" q "[^" q "]*" q "$")) {
          line = substr(line, 2, length(line) - 2)
        }
        print line
        exit
      }
    }
  ' "$src"
}

write_agent_body() {
  src=$1
  awk '
    {
      line = $0
      sub(/\r$/, "", line)
    }
    NR == 1 {
      if (line == "---") {
        in_frontmatter = 1
        next
      }
      print line
      next
    }
    in_frontmatter {
      if (line == "---") {
        in_frontmatter = 0
      }
      next
    }
    { print line }
  ' "$src"
}

write_codex_agent() {
  src=$1
  dest=$2

  if [ ! -f "$src" ]; then
    printf 'missing source file: %s\n' "$src" >&2
    exit 1
  fi

  agent_file=$(basename -- "$src")
  agent_name=${agent_file%.agent.md}
  frontmatter_name=$(agent_frontmatter_value name "$src")
  if [ -n "$frontmatter_name" ]; then
    agent_name=$frontmatter_name
  fi
  description=$(agent_frontmatter_value description "$src")
  if [ -z "$description" ]; then
    description="Imported from Claude agent ${agent_file%.agent.md}."
  fi

  mkdir -p "$(dirname -- "$dest")"
  {
    printf 'name = "%s"\n' "$(toml_escape_basic_string "$agent_name")"
    printf 'description = "%s"\n' "$(toml_escape_basic_string "$description")"
    printf "developer_instructions = '''\n"
    write_agent_body "$src"
    printf "'''\n"
  } > "$dest"
}

backup_existing() {
  src=$1
  name=$2

  if [ -e "$src" ]; then
    mkdir -p "$BACKUP_DIR"
    cp -R "$src" "$BACKUP_DIR/$name"
    printf 'Backed up %s to %s/%s\n' "$src" "$BACKUP_DIR" "$name"
  fi
}

backup_existing "$CLAUDE_TARGET" "claude"

rm -rf "$CLAUDE_TARGET"
mkdir -p "$CLAUDE_TARGET"

copy_file "$ROOT_DIR/AGENTS.md" "$HOME/AGENTS.md"
backup_existing "$COPILOT_WORKSPACE_TARGET" "github-copilot-instructions.md"
write_copilot_instructions "$ROOT_DIR/AGENTS.md" "$COPILOT_WORKSPACE_TARGET"
backup_existing "$COPILOT_CLI_TARGET" "copilot-copilot-instructions.md"
write_copilot_instructions "$ROOT_DIR/AGENTS.md" "$COPILOT_CLI_TARGET"
backup_existing "$COPILOT_VSCODE_TARGET" "copilot-vscode-agents-global.instructions.md"
write_copilot_instructions "$ROOT_DIR/AGENTS.md" "$COPILOT_VSCODE_TARGET" true
copy_file "$ROOT_DIR/.claude/CLAUDE.md" "$CLAUDE_TARGET/CLAUDE.md"
copy_file "$ROOT_DIR/.claude/settings.json" "$CLAUDE_TARGET/settings.json"

# settings.local.json はリポジトリに存在しない場合があるため、存在時のみコピーする
if [ -f "$ROOT_DIR/.claude/settings.local.json" ]; then
  copy_file "$ROOT_DIR/.claude/settings.local.json" "$CLAUDE_TARGET/settings.local.json"
fi
copy_dir "$ROOT_DIR/.claude/rules" "$CLAUDE_TARGET/rules"
copy_dir "$ROOT_DIR/.claude/agents" "$CLAUDE_TARGET/agents"
copy_dir "$ROOT_DIR/.claude/hooks" "$CLAUDE_TARGET/hooks"
copy_dir "$ROOT_DIR/.claude/skills" "$CLAUDE_TARGET/skills"

printf 'Installed settings to %s\n' "$CLAUDE_TARGET"
printf 'Installed GitHub Copilot workspace instructions to %s\n' "$COPILOT_WORKSPACE_TARGET"
printf 'Installed GitHub Copilot CLI instructions to %s\n' "$COPILOT_CLI_TARGET"
printf 'Installed GitHub Copilot VS Code instructions to %s\n' "$COPILOT_VSCODE_TARGET"

# OpenAI Codex CLI はグローバル指示を ~/.codex/AGENTS.md から読む（~/AGENTS.md は参照しない）。
# 認証情報や config.toml を保持する ~/.codex/ は削除せず、AGENTS.md のみ差し替える。
backup_existing "$CODEX_TARGET/AGENTS.md" "codex-AGENTS.md"
copy_file "$ROOT_DIR/AGENTS.md" "$CODEX_TARGET/AGENTS.md"

printf 'Installed Codex instructions to %s/AGENTS.md\n' "$CODEX_TARGET"

backup_existing "$CODEX_AGENTS_TARGET" "codex-agents"
mkdir -p "$CODEX_AGENTS_TARGET"
for agent_file in "$ROOT_DIR/.claude/agents"/*.agent.md; do
  [ -f "$agent_file" ] || continue
  agent_name=$(basename -- "$agent_file")
  agent_name=${agent_name%.agent.md}
  write_codex_agent "$agent_file" "$CODEX_AGENTS_TARGET/$agent_name.toml"
done

printf 'Installed Codex agents to %s\n' "$CODEX_AGENTS_TARGET"

# Codex は Agent Skills を ~/.agents/skills から読む（.agents/skills 規約）。
# ~/.agents/skills は他ツールと共有され得るため全体は削除せず、
# このリポジトリと同名のスキルのみバックアップ後に置き換える。
backup_existing "$AGENTS_SKILLS_TARGET" "agents-skills"
mkdir -p "$AGENTS_SKILLS_TARGET"
for skill_dir in "$ROOT_DIR/.claude/skills"/*; do
  [ -d "$skill_dir" ] || continue
  skill_name=$(basename -- "$skill_dir")
  rm -rf "$AGENTS_SKILLS_TARGET/$skill_name"
  cp -R "$skill_dir" "$AGENTS_SKILLS_TARGET/$skill_name"
done

printf 'Installed skills to %s\n' "$AGENTS_SKILLS_TARGET"
