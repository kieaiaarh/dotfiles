#!/bin/bash
# dotfiles セットアップスクリプト（Claude Code + Vim）
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

echo "=== tmux 設定のシンボリックリンク ==="
link "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

echo ""
echo "=== Claude グローバル設定のシンボリックリンク ==="
link "$DOTFILES_DIR/ai/claude/CLAUDE.md"        "$CLAUDE_DIR/CLAUDE.md"
link "$DOTFILES_DIR/ai/claude/settings.json"    "$CLAUDE_DIR/settings.json"
link "$DOTFILES_DIR/ai/claude/mystatus.sh"      "$CLAUDE_DIR/mystatus.sh"
link "$DOTFILES_DIR/ai/claude/commands/think.md" "$CLAUDE_DIR/commands/think.md"

echo ""
echo "=== プロジェクトリポの .git/info/exclude 設定 ==="

REPOS_FILE="$DOTFILES_DIR/repos.local"
if [ ! -f "$REPOS_FILE" ]; then
  echo "repos.local が見つかりません。repos.template をコピーして作成してください:"
  echo "  cp $DOTFILES_DIR/repos.template $DOTFILES_DIR/repos.local"
  echo "スキップします。"
  echo ""
  echo "=== 手動対応が必要なもの ==="
  echo "1. ~/.claude.json: ai/claude/claude.json.template を参考にトークンを設定"
  echo "   (claude login で再認証すれば自動生成されます)"
  echo ""
  echo "完了！"
  exit 0
fi

declare -A REPO_TEMPLATE
while IFS= read -r line; do
  [[ "$line" =~ ^#.*$ ]] && continue
  [ -z "$line" ] && continue
  repo_path=$(eval echo "$(echo "$line" | awk '{print $1}')")
  template_type=$(echo "$line" | awk '{print $2}')
  REPO_TEMPLATE["$repo_path"]="$template_type"
done < "$REPOS_FILE"

EXCLUDE_PATTERNS=("CLAUDE.md" "AGENTS.md" ".claude/rules/")

echo "--- .git/info/exclude 設定 ---"
for repo in "${!REPO_TEMPLATE[@]}"; do
  if [ ! -d "$repo/.git" ]; then
    echo "⚠️  未クローン（スキップ）: $repo"
    continue
  fi

  exclude_file="$repo/.git/info/exclude"
  updated=0
  for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    if ! grep -qF "$pattern" "$exclude_file" 2>/dev/null; then
      echo "$pattern" >> "$exclude_file"
      updated=1
    fi
  done

  if [ "$updated" -eq 1 ]; then
    echo "除外設定を追加: $repo"
  else
    echo "変更なし: $repo"
  fi
done

echo ""
echo "=== .claude/rules/ の同期 ==="
for repo in "${!REPO_TEMPLATE[@]}"; do
  template="${REPO_TEMPLATE[$repo]}"

  if [ ! -d "$repo/.git" ]; then
    echo "⚠️  未クローン（スキップ）: $repo  [テンプレート: $template]"
    echo "    → clone 後に: bash $DOTFILES_DIR/scripts/sync-rules-to-project.sh $template $repo"
    continue
  fi

  if [ -z "$template" ]; then
    echo "⚠️  テンプレート種別が未設定（スキップ）: $repo"
    echo "    → repos.local に '<パス> <テンプレート種別>' の形式で記載してください"
    continue
  fi

  env_file="$DOTFILES_DIR/buzzkuri/_templates/$template/.env.local"
  if [ ! -f "$env_file" ]; then
    echo "⚠️  env ファイルなし（スキップ）: $repo  [テンプレート: $template]"
    echo "    → cp $DOTFILES_DIR/buzzkuri/_templates/$template/.env.template $env_file"
    echo "    → 編集後に: bash $DOTFILES_DIR/scripts/sync-rules-to-project.sh $template $repo $env_file"
    continue
  fi

  echo "同期中: $repo  [テンプレート: $template]"
  bash "$DOTFILES_DIR/scripts/sync-rules-to-project.sh" "$template" "$repo" "$env_file"
done

echo ""
echo "=== Vim セットアップ ==="

link "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"

# ~/.vim は実ディレクトリとして管理（vimfiles/ へのシンボリックリンクは不可）
mkdir -p "$HOME/.vim/autoload"
if [ ! -f "$HOME/.vim/autoload/pathogen.vim" ]; then
  cp "$DOTFILES_DIR/vimfiles/autoload/pathogen.vim" "$HOME/.vim/autoload/pathogen.vim"
  echo "コピー: ~/.vim/autoload/pathogen.vim"
else
  echo "変更なし: ~/.vim/autoload/pathogen.vim"
fi

mkdir -p "$HOME/.vim/bundle"
if [ ! -d "$HOME/.vim/bundle/neobundle.vim" ]; then
  echo "NeoBundle をインストール中..."
  git clone https://github.com/Shougo/neobundle.vim "$HOME/.vim/bundle/neobundle.vim"
  echo "NeoBundle インストール完了"
else
  echo "変更なし: NeoBundle はインストール済み"
fi

echo ""
echo "=== 手動対応が必要なもの ==="
echo "1. ~/.claude.json: ai/claude/claude.json.template を参考にトークンを設定"
echo "   (claude login で再認証すれば自動生成されます)"
echo "2. Vim プラグイン: vim を起動して :NeoBundleInstall を実行"
echo ""
echo "完了！"
