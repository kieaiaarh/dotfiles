#!/bin/sh
# PostToolUse hook: 典型的な省略変数名を検知して警告
# CLAUDE.md「省略語禁止」ルールを機械的に検査
set -eu

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)

if [ -z "$file_path" ]; then
  exit 0
fi

case "$file_path" in
  *.rb) lang="ruby" ;;
  *.ts|*.tsx) lang="ts" ;;
  *) exit 0 ;;
esac

if [ ! -f "$file_path" ]; then
  exit 0
fi

if [ "$lang" = "ruby" ]; then
  # Ruby: ブロック引数 |e| / ローカル変数 ev =
  patterns='\|[ ]*(e|b|ev|biz|req|usr|cfg|cnt|tmp)[ ]*\||[[:space:]](ev|biz|req|usr|cfg)[ ]*='
  # rescue => e は RuboCop で必須なので除外
  hits=$(grep -nE "$patterns" "$file_path" 2>/dev/null \
    | grep -vE 'rescue.*=>[[:space:]]*e[[:space:]]*$|rescue.*=>[[:space:]]*e[[:space:]]*\|' || true)
else
  # TypeScript: アロー関数引数 (e) / ローカル変数 const ev =
  patterns='\([ ]*(e|b|ev|req|res|err|cfg|tmp|btn|ctx)[ ]*[,)]|(const|let|var)[ ]+(e|b|ev|req|res|err|cfg|tmp)[ ]*='
  hits=$(grep -nE "$patterns" "$file_path" 2>/dev/null || true)
fi

if [ -n "$hits" ]; then
  printf '\n⚠️  省略変数名の疑い: %s\n' "$file_path" >&2
  printf '%s\n' "$hits" >&2
  printf 'CLAUDE.md「省略語禁止」違反の可能性。フルネームに変更してください（例: (e) → (event)、const ev → const eventData）\n\n' >&2
fi

exit 0
