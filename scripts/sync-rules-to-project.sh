#!/bin/bash
# テンプレートの .claude/ 配下をプロジェクトリポに同期するスクリプト
#
# 使い方:
#   bash scripts/sync-rules-to-project.sh <テンプレート種別> <プロジェクトパス> [envファイル]
#
# 例:
#   bash scripts/sync-rules-to-project.sh rails ~/work/buzzkuri/backend
#   bash scripts/sync-rules-to-project.sh rails ~/work/buzzkuri/backend buzzkuri/_templates/rails/.env.local

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE_TYPE="${1:-}"
PROJECT_PATH="${2:-}"
ENV_FILE="${3:-}"

if [ -z "$TEMPLATE_TYPE" ] || [ -z "$PROJECT_PATH" ]; then
  echo "使い方: bash scripts/sync-rules-to-project.sh <テンプレート種別> <プロジェクトパス> [envファイル]"
  echo ""
  echo "テンプレート種別:"
  ls "$DOTFILES_DIR/buzzkuri/_templates/"
  exit 1
fi

TEMPLATE_DIR="$DOTFILES_DIR/buzzkuri/_templates/$TEMPLATE_TYPE"
RULES_TEMPLATE_DIR="$TEMPLATE_DIR/rules"
PROJECT_RULES_DIR="$PROJECT_PATH/.claude/rules"
PROJECT_CLAUDE_DIR="$PROJECT_PATH/.claude"

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "エラー: テンプレート '$TEMPLATE_TYPE' が見つかりません"
  exit 1
fi

if [ -n "$ENV_FILE" ] && [ ! -f "$ENV_FILE" ]; then
  echo "エラー: envファイルが見つかりません: $ENV_FILE"
  exit 1
fi

# プレースホルダーを置換する関数（bash 3.x対応）
apply_env() {
  local file="$1"
  [ -z "$ENV_FILE" ] && return
  [ ! -f "$ENV_FILE" ] && return
  while IFS='=' read -r key value; do
    [[ "$key" =~ ^#.*$ ]] && continue
    [ -z "$key" ] && continue
    sed -i.bak "s|{{${key}}}|${value}|g" "$file" && rm -f "${file}.bak"
  done < "$ENV_FILE"
}

[ -n "$ENV_FILE" ] && echo "envファイルを読み込みます: $ENV_FILE"
echo "=== .claude/ の同期: $TEMPLATE_TYPE → $PROJECT_PATH ==="
echo ""

mkdir -p "$PROJECT_RULES_DIR"
UPDATED=0

# ── 1. rules/*.md.template ──────────────────────────────────────────────────
if [ ! -d "$RULES_TEMPLATE_DIR" ]; then
  echo "[rules] テンプレートに rules/ ディレクトリがありません（スキップ）"
else
  echo "--- .claude/rules/ ---"
  for template_file in "$RULES_TEMPLATE_DIR"/*.md.template; do
    [ -e "$template_file" ] || continue
    filename=$(basename "$template_file" .template)
    project_file="$PROJECT_RULES_DIR/$filename"

    if [ ! -f "$project_file" ]; then
      cp "$template_file" "$project_file"
      apply_env "$project_file"
      echo "新規追加: .claude/rules/$filename"
      UPDATED=$((UPDATED + 1))
    else
      tmp_file=$(mktemp)
      cp "$template_file" "$tmp_file"
      apply_env "$tmp_file"
      if ! diff -q "$tmp_file" "$project_file" > /dev/null 2>&1; then
        echo "差分あり: .claude/rules/$filename"
        diff "$tmp_file" "$project_file" || true
        echo ""
        printf "上書きしますか？ [y/N]: "
        read -r answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
          cp "$tmp_file" "$project_file"
          echo "更新しました: .claude/rules/$filename"
          UPDATED=$((UPDATED + 1))
        else
          echo "スキップ: .claude/rules/$filename"
        fi
      else
        echo "変更なし: .claude/rules/$filename"
      fi
      rm -f "$tmp_file"
    fi
  done
fi

# ── 2. CLAUDE.md.template ───────────────────────────────────────────────────
echo ""
echo "--- CLAUDE.md ---"
CLAUDE_TEMPLATE="$TEMPLATE_DIR/CLAUDE.md.template"
PROJECT_CLAUDE="$PROJECT_PATH/CLAUDE.md"

if [ ! -f "$CLAUDE_TEMPLATE" ]; then
  echo "テンプレートに CLAUDE.md.template がありません（スキップ）"
elif [ ! -f "$PROJECT_CLAUDE" ]; then
  cp "$CLAUDE_TEMPLATE" "$PROJECT_CLAUDE"
  apply_env "$PROJECT_CLAUDE"
  echo "作成しました: CLAUDE.md"
  remaining=$(grep -o '{{[^}]*}}' "$PROJECT_CLAUDE" 2>/dev/null | sort -u || true)
  if [ -n "$remaining" ]; then
    echo "未置換のプレースホルダーが残っています。手動で置き換えてください:"
    echo "$remaining" | while read -r p; do echo "  $p"; done
  fi
  UPDATED=$((UPDATED + 1))
else
  tmp_file=$(mktemp)
  cp "$CLAUDE_TEMPLATE" "$tmp_file"
  apply_env "$tmp_file"
  echo "CLAUDE.md が既存のため差分を表示します:"
  echo "  (- がテンプレート側、+ が既存ファイル側)"
  echo ""
  diff -u "$tmp_file" "$PROJECT_CLAUDE" || true
  echo ""
  printf "テンプレートで上書きしますか？ [y/N]: "
  read -r answer
  if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    cp "$tmp_file" "$PROJECT_CLAUDE"
    echo "上書きしました: CLAUDE.md"
    UPDATED=$((UPDATED + 1))
  else
    echo "スキップ: CLAUDE.md（手動でマージしてください）"
  fi
  rm -f "$tmp_file"
fi

# ── 3. claude-settings.json.template → .claude/settings.json ───────────────
echo ""
echo "--- .claude/settings.json ---"
SETTINGS_TEMPLATE="$TEMPLATE_DIR/claude-settings.json.template"
PROJECT_SETTINGS="$PROJECT_CLAUDE_DIR/settings.json"

if [ ! -f "$SETTINGS_TEMPLATE" ]; then
  echo "テンプレートに claude-settings.json.template がありません（スキップ）"
elif [ ! -f "$PROJECT_SETTINGS" ]; then
  cp "$SETTINGS_TEMPLATE" "$PROJECT_SETTINGS"
  apply_env "$PROJECT_SETTINGS"
  echo "作成しました: .claude/settings.json"
  UPDATED=$((UPDATED + 1))
else
  tmp_file=$(mktemp)
  cp "$SETTINGS_TEMPLATE" "$tmp_file"
  apply_env "$tmp_file"
  if ! diff -q "$tmp_file" "$PROJECT_SETTINGS" > /dev/null 2>&1; then
    echo "差分あり: .claude/settings.json"
    diff "$tmp_file" "$PROJECT_SETTINGS" || true
    echo ""
    printf "上書きしますか？ [y/N]: "
    read -r answer
    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
      cp "$tmp_file" "$PROJECT_SETTINGS"
      echo "更新しました: .claude/settings.json"
      UPDATED=$((UPDATED + 1))
    else
      echo "スキップ: .claude/settings.json"
    fi
  else
    echo "変更なし: .claude/settings.json"
  fi
  rm -f "$tmp_file"
fi

# ── 4. hooks/ ───────────────────────────────────────────────────────────────
HOOKS_TEMPLATE_DIR="$TEMPLATE_DIR/hooks"
PROJECT_HOOKS_DIR="$PROJECT_CLAUDE_DIR/hooks"

if [ -d "$HOOKS_TEMPLATE_DIR" ]; then
  echo ""
  echo "--- .claude/hooks/ ---"
  mkdir -p "$PROJECT_HOOKS_DIR"
  for hook_file in "$HOOKS_TEMPLATE_DIR"/*.sh; do
    [ -e "$hook_file" ] || continue
    filename=$(basename "$hook_file")
    project_hook="$PROJECT_HOOKS_DIR/$filename"

    if [ ! -f "$project_hook" ]; then
      cp "$hook_file" "$project_hook"
      chmod +x "$project_hook"
      echo "新規追加: .claude/hooks/$filename"
      UPDATED=$((UPDATED + 1))
    else
      if ! diff -q "$hook_file" "$project_hook" > /dev/null 2>&1; then
        echo "差分あり: .claude/hooks/$filename"
        diff "$hook_file" "$project_hook" || true
        echo ""
        printf "上書きしますか？ [y/N]: "
        read -r answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
          cp "$hook_file" "$project_hook"
          chmod +x "$project_hook"
          echo "更新しました: .claude/hooks/$filename"
          UPDATED=$((UPDATED + 1))
        else
          echo "スキップ: .claude/hooks/$filename"
        fi
      else
        echo "変更なし: .claude/hooks/$filename"
      fi
    fi
  done
fi

echo ""
if [ "$UPDATED" -gt 0 ]; then
  echo "完了: $UPDATED ファイルを更新しました。"
  echo "変更後は git diff で確認し、コミットしてください。"
else
  echo "完了: 更新対象はありませんでした。"
fi
