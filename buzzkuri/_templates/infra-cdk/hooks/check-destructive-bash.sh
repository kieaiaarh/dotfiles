#!/bin/bash
# PreToolUse(Bash) hook: 破壊的コマンドを検知して警告する

COMMAND=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.command // empty' 2>/dev/null || true)
[ -z "$COMMAND" ] && exit 0

# 本番スタックへの cdk deploy
if echo "$COMMAND" | grep -qE 'cdk\s+deploy' && echo "$COMMAND" | grep -qiE '(prod|production)'; then
  echo "⚠️  本番スタックへの cdk deploy を検知しました。" >&2
  echo "   意図的な操作であれば続行してください。ロールバック手順を確認してから実行すること。" >&2
  exit 2
fi

# AWS 破壊的操作（delete / terminate / destroy / drop）
if echo "$COMMAND" | grep -qE 'aws\s+' && echo "$COMMAND" | grep -qiE '(delete|terminate|destroy|remove)'; then
  echo "⚠️  AWS リソースの破壊的操作を検知しました: $COMMAND" >&2
  echo "   影響範囲を確認し、ユーザーの承認を得てから実行すること。" >&2
  exit 2
fi

# RDS 操作（stop / start / delete / create / modify）
if echo "$COMMAND" | grep -qE 'aws\s+rds\s+(stop|start|delete|create|modify|restore)'; then
  echo "⚠️  RDS 操作を検知しました: $COMMAND" >&2
  echo "   DB への変更はユーザーの確認が必要です。" >&2
  exit 2
fi

# IAM 広範囲変更
if echo "$COMMAND" | grep -qE 'aws\s+iam\s+(create-policy|attach|put-role-policy|delete)'; then
  echo "⚠️  IAM 権限変更を検知しました: $COMMAND" >&2
  echo "   セキュリティへの影響を確認し、ユーザーの承認を得てから実行すること。" >&2
  exit 2
fi

# CloudFormation スタック削除
if echo "$COMMAND" | grep -qE 'aws\s+cloudformation\s+delete-stack'; then
  echo "⚠️  CloudFormation スタック削除を検知しました: $COMMAND" >&2
  echo "   ユーザーの明示的な承認が必要です。" >&2
  exit 2
fi

exit 0
