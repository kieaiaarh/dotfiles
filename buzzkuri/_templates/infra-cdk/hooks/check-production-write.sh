#!/bin/bash
# PreToolUse(Write/Edit) hook: 本番設定ファイルへの書き込みを警告する

FILE_PATH=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null || true)
[ -z "$FILE_PATH" ] && exit 0

# 本番系設定ファイルのパターン
PROD_PATTERNS=(
  'prod'
  'production'
  'cdk.context.json'
)

for pattern in "${PROD_PATTERNS[@]}"; do
  if echo "$FILE_PATH" | grep -qi "$pattern"; then
    echo "⚠️  本番関連ファイルへの書き込みを検知しました: $FILE_PATH" >&2
    echo "   意図的な変更か確認し、staging 検証済みであることを確認してから続行すること。" >&2
    exit 2
  fi
done

# .env 系ファイル（deny だけでは Edit が漏れる場合の二重チェック）
if echo "$FILE_PATH" | grep -qE '\.env($|\.)'; then
  echo "⚠️  .env ファイルへの書き込みを検知しました: $FILE_PATH" >&2
  echo "   秘密情報を含む可能性があります。ユーザーの確認を得てから続行すること。" >&2
  exit 2
fi

exit 0
