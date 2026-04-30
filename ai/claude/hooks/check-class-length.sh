#!/bin/sh
# PostToolUse hook: app/ 配下の .rb ファイルでクラス長・メソッド長をチェック
# CLAUDE.md「Class ≤ 100行」「Method ≲ 30行」ルールを機械的に検査
set -eu

file_path=$(printf '%s\n' "$CLAUDE_TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null || true)

if [ -z "$file_path" ]; then
  exit 0
fi

# app/**/*.rb のみ対象（lib/ も対象に含める）
case "$file_path" in
  *app/*.rb|*lib/*.rb) ;;
  *) exit 0 ;;
esac

if [ ! -f "$file_path" ]; then
  exit 0
fi

warn=""

# クラス長チェック（コメント行除外）
line_count=$(grep -cvE '^[[:space:]]*(#|$)' "$file_path" 2>/dev/null || echo 0)
if [ "$line_count" -gt 100 ]; then
  warn="${warn}⚠️  クラス長違反: $file_path が ${line_count} 実行行（上限 100 行）
"
fi

# メソッド長チェック（30 行超を警告）
method_warns=$(awk '
  /^[[:space:]]*(def |private def )/ {
    in_def=1
    def_start=NR
    name=$0
    sub(/^[[:space:]]+/, "", name)
    next
  }
  in_def && /^[[:space:]]*end[[:space:]]*$/ {
    len = NR - def_start - 1
    if (len > 30) {
      printf "  L%d: %s (%d 行)\n", def_start, name, len
    }
    in_def=0
  }
' "$file_path" 2>/dev/null || true)

if [ -n "$method_warns" ]; then
  warn="${warn}⚠️  メソッド長違反 (30 行超): $file_path
$method_warns
"
fi

if [ -n "$warn" ]; then
  printf '\n%s' "$warn" >&2
  printf 'CLAUDE.md「Class ≤ 100行 / Method ≲ 30行」ルール違反。責務分割を検討してください。\n\n' >&2
fi

exit 0
