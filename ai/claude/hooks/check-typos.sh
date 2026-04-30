#!/bin/sh
# PostToolUse hook: Edit/Write 後にタイポチェックを実行
# exit 0: 常に許可（警告のみ、ブロックしない）
set -eu

file_path=$(printf '%s\n' "$CLAUDE_TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null || true)

if [ -z "$file_path" ]; then
  exit 0
fi

# codespell が入っていない場合はスキップ
if ! command -v codespell >/dev/null 2>&1; then
  exit 0
fi

# テキスト系ファイルのみ対象
case "$file_path" in
  *.rb|*.md|*.txt|*.yml|*.yaml|*.json|*.js|*.ts|*.erb) ;;
  *) exit 0 ;;
esac

result=$(codespell "$file_path" 2>&1 || true)
if [ -n "$result" ]; then
  printf '\n⚠️  タイポ候補を検出しました: %s\n' "$file_path" >&2
  printf '%s\n' "$result" >&2
  printf 'codespell -w %s で自動修正できます\n\n' "$file_path" >&2
fi

exit 0
