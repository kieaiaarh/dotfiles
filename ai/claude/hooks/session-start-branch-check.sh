#!/bin/sh
# SessionStart hook: セッション開始時にブランチ確認・master/main 警告を注入
set -eu

branch=$(git branch --show-current 2>/dev/null || echo "")

if [ "$branch" = "master" ] || [ "$branch" = "main" ]; then
  printf '🔴 %s ブランチで作業中。コード変更の前に `git checkout -b feature/<topic>` を実行してください。\n' "$branch" >&2
fi

printf '{}'
exit 0
