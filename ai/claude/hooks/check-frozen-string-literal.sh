#!/bin/sh
# PostToolUse hook: # frozen_string_literal: コメントを検知
# CLAUDE.md「frozen_string_literal は書かない」ルールを機械的に検査
set -eu

file_path=$(printf '%s\n' "$CLAUDE_TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null || true)

if [ -z "$file_path" ]; then
  exit 0
fi

case "$file_path" in
  *.rb) ;;
  *) exit 0 ;;
esac

if [ ! -f "$file_path" ]; then
  exit 0
fi

if head -5 "$file_path" 2>/dev/null | grep -qE '^#[[:space:]]*frozen_string_literal:'; then
  printf '\n⚠️  frozen_string_literal コメント検出: %s\n' "$file_path" >&2
  printf 'CLAUDE.md「# frozen_string_literal: は書かない」違反。削除してください。\n\n' >&2
fi

exit 0
