#!/bin/sh
# UserPromptSubmit hook: ユーザー発話毎に現在状態と重要ルールを context へ注入
# 圧縮で CLAUDE.md が context から消えても、毎ターン重要点を再供給する保険
set -eu

# CLAUDE.md を含むプロジェクトルートを探索（最も近いものを採用）
search_dir="$PWD"
project_root=""
while [ "$search_dir" != "/" ]; do
  if [ -f "$search_dir/CLAUDE.md" ]; then
    project_root="$search_dir"
    break
  fi
  search_dir=$(dirname "$search_dir")
done

if [ -z "$project_root" ]; then
  exit 0
fi

# 現在ブランチ
branch=$(git -C "$project_root" branch --show-current 2>/dev/null || echo "")

# 重要ルール抽出（CLAUDE.md の絶対ルール／Make早見表セクションを切り出し）
critical_rules=$(awk '
  /^## (絶対ルール|Make早見表|完了前確認)/ { capture=1; print; next }
  /^## / && capture { capture=0 }
  capture { print }
' "$project_root/CLAUDE.md" 2>/dev/null || true)

# additionalContext を組み立て
context="## 現在の作業コンテキスト
- プロジェクト: $project_root
- ブランチ: ${branch:-（git管理外）}"

if [ "$branch" = "master" ] || [ "$branch" = "main" ]; then
  context="$context

🔴 **${branch} ブランチで作業中。コード変更の前に \`git checkout -b feature/<topic>\` を実行してください。**"
fi

if [ -n "$critical_rules" ]; then
  context="$context

## CLAUDE.md より重要ルール再掲
$critical_rules"
fi

# JSON 出力（jq でエスケープ）
printf '%s' "$context" | jq -Rs '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: .
  }
}'

exit 0
