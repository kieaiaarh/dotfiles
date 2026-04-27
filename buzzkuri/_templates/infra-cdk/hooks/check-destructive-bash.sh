#!/bin/bash
# PreToolUse(Bash) hook: 破壊的コマンドを検知して警告する

COMMAND=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.command // empty' 2>/dev/null || true)
[ -z "$COMMAND" ] && exit 0

# === CDK deploy/destroy の事前チェック ===
if echo "$COMMAND" | grep -qE '(npx\s+)?cdk\s+(deploy|destroy)'; then

  # 本番スタックへの deploy はブロック
  if echo "$COMMAND" | grep -qiE '(prod|production)'; then
    echo "⚠️  本番スタックへの cdk deploy を検知しました。" >&2
    echo "   意図的な操作であれば続行してください。ロールバック手順を確認してから実行すること。" >&2
    exit 2
  fi

  # スタック名を抽出（大文字始まりの *Stack パターン）
  STACK_NAMES=$(echo "$COMMAND" | grep -oE '[A-Z][A-Za-z0-9]*Stack' | head -5 || true)

  # AWS プロファイルを抽出
  PROFILE_OPT=""
  if echo "$COMMAND" | grep -q -- '--profile'; then
    PROFILE=$(echo "$COMMAND" | sed -n 's/.*--profile[= ]\([^ ]*\).*/\1/p' | head -1)
    [ -n "$PROFILE" ] && PROFILE_OPT="--profile $PROFILE"
  fi

  # 既存スタックの CF 状態チェック（認証失敗は警告のみ）
  for STACK in $STACK_NAMES; do
    STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK" $PROFILE_OPT \
      --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo "UNKNOWN")

    case "$STATUS" in
      ROLLBACK_COMPLETE|CREATE_FAILED|UPDATE_FAILED|UPDATE_ROLLBACK_FAILED|IMPORT_ROLLBACK_FAILED|DELETE_FAILED)
        echo "🚨 [BLOCK] スタック '$STACK' が '$STATUS' 状態です。" >&2
        echo "   このまま cdk deploy を実行すると既存リソースが削除される危険があります。" >&2
        echo "" >&2
        echo "   確認コマンド:" >&2
        echo "     aws cloudformation list-stack-resources --stack-name $STACK $PROFILE_OPT" >&2
        echo "     aws cloudformation describe-stack-events --stack-name $STACK $PROFILE_OPT" >&2
        echo "" >&2
        echo "   対処方針（cdk import / 手動削除）をユーザーに報告し、承認を得てから実行すること。" >&2
        exit 2
        ;;
      UPDATE_ROLLBACK_COMPLETE)
        echo "⚠️  [BLOCK] スタック '$STACK' が UPDATE_ROLLBACK_COMPLETE 状態です。" >&2
        echo "   直前のデプロイがロールバックされています。差分と原因を確認してから実行してください。" >&2
        echo "   確認コマンド: aws cloudformation describe-stack-events --stack-name $STACK $PROFILE_OPT" >&2
        exit 2
        ;;
      UNKNOWN)
        # 認証エラーまたはスタック未存在 → 警告のみ（初回デプロイは通過）
        ;;
    esac
  done
fi

# === AWS 破壊的操作（delete / terminate / destroy / drop）===
if echo "$COMMAND" | grep -qE 'aws\s+' && echo "$COMMAND" | grep -qiE '(delete|terminate|destroy|remove)'; then
  echo "⚠️  AWS リソースの破壊的操作を検知しました: $COMMAND" >&2
  echo "   影響範囲を確認し、ユーザーの承認を得てから実行すること。" >&2
  exit 2
fi

# === RDS 操作（stop / start / delete / create / modify）===
if echo "$COMMAND" | grep -qE 'aws\s+rds\s+(stop|start|delete|create|modify|restore)'; then
  echo "⚠️  RDS 操作を検知しました: $COMMAND" >&2
  echo "   DB への変更はユーザーの確認が必要です。" >&2
  exit 2
fi

# === IAM 広範囲変更 ===
if echo "$COMMAND" | grep -qE 'aws\s+iam\s+(create-policy|attach|put-role-policy|delete)'; then
  echo "⚠️  IAM 権限変更を検知しました: $COMMAND" >&2
  echo "   セキュリティへの影響を確認し、ユーザーの承認を得てから実行すること。" >&2
  exit 2
fi

# === CloudFormation スタック削除 ===
if echo "$COMMAND" | grep -qE 'aws\s+cloudformation\s+delete-stack'; then
  echo "⚠️  CloudFormation スタック削除を検知しました: $COMMAND" >&2
  echo "   ユーザーの明示的な承認が必要です。" >&2
  exit 2
fi

exit 0
