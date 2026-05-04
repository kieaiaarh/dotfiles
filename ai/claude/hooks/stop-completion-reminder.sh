#!/bin/sh
# Stop hook: レスポンス終了時、未コミット変更があれば完了前確認リマインドを注入
set -eu

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

uncommitted=$(git status --porcelain 2>/dev/null | grep -v '^??' || true)
if [ -z "$uncommitted" ]; then
  exit 0
fi

count=$(printf '%s\n' "$uncommitted" | wc -l | tr -d ' ')
msg="⚠️ 未コミットの変更が ${count} 件あります。作業完了前に \`git commit\` または \`git stash\` を確認してください。（CLAUDE.md「完了前の確認」）"

printf '%s' "$msg" | jq -Rs '{
  hookSpecificOutput: {
    hookEventName: "Stop",
    additionalContext: .
  }
}'

exit 0
