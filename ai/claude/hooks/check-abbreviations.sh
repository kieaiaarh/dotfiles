#!/bin/sh
# PostToolUse hook: 典型的な省略変数名を検知して警告
# CLAUDE.md「省略語禁止」ルールを機械的に検査
set -eu

file_path=$(printf '%s\n' "$CLAUDE_TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null || true)

if [ -z "$file_path" ]; then
  exit 0
fi

# Ruby/spec のみ対象
case "$file_path" in
  *.rb) ;;
  *) exit 0 ;;
esac

if [ ! -f "$file_path" ]; then
  exit 0
fi

# 典型的な省略パターン検知
# - 単独の |e| |b| |ev| |biz| |req| |usr| |cfg| ブロック引数
# - = ev | = biz | = req | = usr のローカル変数代入
patterns='\|[ ]*(e|b|ev|biz|req|usr|cfg|cnt|tmp)[ ]*\||[[:space:]](ev|biz|req|usr|cfg)[ ]*='

# rescue => e は RuboCop で必須なので除外
hits=$(grep -nE "$patterns" "$file_path" 2>/dev/null | grep -vE 'rescue.*=>[[:space:]]*e[[:space:]]*$|rescue.*=>[[:space:]]*e[[:space:]]*\|' || true)

if [ -n "$hits" ]; then
  printf '\n⚠️  省略変数名の疑い: %s\n' "$file_path" >&2
  printf '%s\n' "$hits" >&2
  printf 'CLAUDE.md「省略語禁止」違反の可能性。フルネームに変更してください（例: |e| → |event|）\n\n' >&2
fi

exit 0
