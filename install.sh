#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CLAUDE_TARGET="$HOME/.claude"
CODEX_TARGET="$HOME/.codex"
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
copy_file "$ROOT_DIR/.claude/CLAUDE.md" "$CLAUDE_TARGET/CLAUDE.md"
copy_file "$ROOT_DIR/.claude/settings.json" "$CLAUDE_TARGET/settings.json"
copy_file "$ROOT_DIR/.claude/settings.local.json" "$CLAUDE_TARGET/settings.local.json"
copy_dir "$ROOT_DIR/.claude/rules" "$CLAUDE_TARGET/rules"
copy_dir "$ROOT_DIR/.claude/agents" "$CLAUDE_TARGET/agents"
copy_dir "$ROOT_DIR/.claude/hooks" "$CLAUDE_TARGET/hooks"
copy_dir "$ROOT_DIR/.claude/skills" "$CLAUDE_TARGET/skills"

printf 'Installed settings to %s\n' "$CLAUDE_TARGET"

# OpenAI Codex CLI はグローバル指示を ~/.codex/AGENTS.md から読む（~/AGENTS.md は参照しない）。
# 認証情報や config.toml を保持する ~/.codex/ は削除せず、AGENTS.md のみ差し替える。
backup_existing "$CODEX_TARGET/AGENTS.md" "codex-AGENTS.md"
copy_file "$ROOT_DIR/AGENTS.md" "$CODEX_TARGET/AGENTS.md"

printf 'Installed Codex instructions to %s/AGENTS.md\n' "$CODEX_TARGET"