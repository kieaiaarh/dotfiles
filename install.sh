#!/bin/bash
# AI制御ファイルのシンボリックリンクを貼るセットアップスクリプト
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

link() {
  local src="$1"
  local dst="$2"
  local dst_dir
  dst_dir="$(dirname "$dst")"

  mkdir -p "$dst_dir"

  if [ -L "$dst" ]; then
    echo "既存のシンボリックリンクを更新: $dst"
    rm "$dst"
  elif [ -f "$dst" ]; then
    echo "既存ファイルをバックアップ: $dst -> $dst.bak"
    mv "$dst" "$dst.bak"
  fi

  ln -s "$src" "$dst"
  echo "リンク作成: $dst -> $src"
}

echo "=== Claude グローバル設定のシンボリックリンク ==="
link "$DOTFILES_DIR/ai/claude/CLAUDE.md"        "$CLAUDE_DIR/CLAUDE.md"
link "$DOTFILES_DIR/ai/claude/settings.json"    "$CLAUDE_DIR/settings.json"
link "$DOTFILES_DIR/ai/claude/mystatus.sh"      "$CLAUDE_DIR/mystatus.sh"
link "$DOTFILES_DIR/ai/claude/commands/think.md" "$CLAUDE_DIR/commands/think.md"

echo ""
echo "=== 手動対応が必要なもの ==="
echo "1. ~/.claude.json: ai/claude/claude.json.template を参考にトークンを設定"
echo "   (claude login で再認証すれば自動生成されます)"
echo ""
echo "完了！"
