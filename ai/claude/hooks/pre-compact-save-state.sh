#!/bin/sh
# PreCompact hook: 圧縮前にブランチ・未コミット差分サマリーを context へ保存
# inject-current-state.sh（UserPromptSubmit）と2段構えで context loss を防ぐ
set -eu

branch=$(git branch --show-current 2>/dev/null || echo "")
project_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")

context="## [PreCompact] 圧縮直前の作業状態
- プロジェクト: $project_root
- ブランチ: ${branch:-（git管理外）}"

if [ "$branch" = "master" ] || [ "$branch" = "main" ]; then
  context="$context
🔴 ${branch} ブランチで作業中 — コード変更前に feature ブランチを切ること"
fi

status=$(git status --porcelain 2>/dev/null | head -10 || true)
if [ -n "$status" ]; then
  context="$context

未コミット変更（上位10件）:
$(printf '%s' "$status")"
fi

printf '%s' "$context" | jq -Rs '{
  hookSpecificOutput: {
    hookEventName: "PreCompact",
    additionalContext: .
  }
}'

exit 0
