#!/bin/sh
# PreToolUse hook: db/migrate/ への書き込みをブロック
# CLAUDE.md「AR マイグレーション禁止。Ridgepole を使用」を機械的に強制
# exit 2: ブロック
set -eu

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)

if [ -z "$file_path" ]; then
  exit 0
fi

case "$file_path" in
  */db/migrate/*.rb)
    echo "❌ AR マイグレーションは禁止されています" >&2
    echo "   CLAUDE.md「DB変更は必ず Ridgepole」ルール" >&2
    echo "   → make ridgepole_apply 経由でスキーマを変更してください" >&2
    echo "   → ユーザーに必ず確認を取ってください" >&2
    exit 2
    ;;
esac

exit 0
