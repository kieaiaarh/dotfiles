#!/bin/bash
# テンプレートの .claude/rules/ をプロジェクトリポに同期するスクリプト
#
# 使い方:
#   bash scripts/sync-rules-to-project.sh <テンプレート種別> <プロジェクトパス>
#
# 例:
#   bash scripts/sync-rules-to-project.sh rails ~/work/buzzkuri/backend
#   bash scripts/sync-rules-to-project.sh infra-cdk ~/work/buzzkuri/infra

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE_TYPE="${1:-}"
PROJECT_PATH="${2:-}"

# 引数チェック
if [ -z "$TEMPLATE_TYPE" ] || [ -z "$PROJECT_PATH" ]; then
  echo "使い方: bash scripts/sync-rules-to-project.sh <テンプレート種別> <プロジェクトパス>"
  echo ""
  echo "テンプレート種別:"
  ls "$DOTFILES_DIR/buzzkuri/_templates/"
  exit 1
fi

TEMPLATE_DIR="$DOTFILES_DIR/buzzkuri/_templates/$TEMPLATE_TYPE"
RULES_TEMPLATE_DIR="$TEMPLATE_DIR/rules"
PROJECT_RULES_DIR="$PROJECT_PATH/.claude/rules"

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "エラー: テンプレート '$TEMPLATE_TYPE' が見つかりません"
  exit 1
fi

if [ ! -d "$RULES_TEMPLATE_DIR" ]; then
  echo "テンプレートにrulesディレクトリがありません: $RULES_TEMPLATE_DIR"
  exit 1
fi

echo "=== .claude/rules/ の同期: $TEMPLATE_TYPE → $PROJECT_PATH ==="
echo ""

mkdir -p "$PROJECT_RULES_DIR"

# 差分の確認と同期
UPDATED=0
for template_file in "$RULES_TEMPLATE_DIR"/*.md.template; do
  filename=$(basename "$template_file" .template)
  project_file="$PROJECT_RULES_DIR/$filename"

  if [ ! -f "$project_file" ]; then
    cp "$template_file" "$project_file"
    echo "新規追加: .claude/rules/$filename"
    UPDATED=$((UPDATED + 1))
  else
    if ! diff -q "$template_file" "$project_file" > /dev/null 2>&1; then
      echo "差分あり: .claude/rules/$filename"
      echo "--- テンプレート vs プロジェクト ---"
      diff "$template_file" "$project_file" || true
      echo ""
      printf "上書きしますか？ [y/N]: "
      read -r answer
      if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        cp "$template_file" "$project_file"
        echo "更新しました: .claude/rules/$filename"
        UPDATED=$((UPDATED + 1))
      else
        echo "スキップ: .claude/rules/$filename"
      fi
    else
      echo "変更なし: .claude/rules/$filename"
    fi
  fi
done

echo ""
echo "=== CLAUDE.md の確認 ==="
CLAUDE_TEMPLATE="$TEMPLATE_DIR/CLAUDE.md.template"
PROJECT_CLAUDE="$PROJECT_PATH/CLAUDE.md"

if [ -f "$CLAUDE_TEMPLATE" ] && [ -f "$PROJECT_CLAUDE" ]; then
  echo "CLAUDE.md はプレースホルダーが含まれるため自動更新しません。"
  echo "以下のdiffを参考に手動でマージしてください:"
  echo ""
  diff "$CLAUDE_TEMPLATE" "$PROJECT_CLAUDE" || true
else
  echo "CLAUDE.md が見つかりません（スキップ）"
fi

echo ""
if [ "$UPDATED" -gt 0 ]; then
  echo "完了: $UPDATED ファイルを更新しました。"
  echo "変更後は git diff で確認し、コミットしてください。"
else
  echo "完了: 更新対象はありませんでした。"
fi
