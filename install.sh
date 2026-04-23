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
REPOS_TEMPLATE="$DOTFILES_DIR/repos.template"
if [ ! -f "$REPOS_FILE" ]; then
  echo "repos.local が見つかりません。repos.template からコピーして作成します。"
  cp "$REPOS_TEMPLATE" "$REPOS_FILE"
  echo "作成しました: repos.local"
elif ! diff -q "$REPOS_TEMPLATE" "$REPOS_FILE" > /dev/null 2>&1; then
  echo "repos.local と repos.template に差分があります:"
  echo "  (- が repos.template 側、+ が repos.local 側)"
  echo ""
  diff -u "$REPOS_TEMPLATE" "$REPOS_FILE" || true
  echo ""
  printf "repos.template で上書きしますか？ [y/N]: "
  read -r answer
  if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    cp "$REPOS_TEMPLATE" "$REPOS_FILE"
    echo "上書きしました: repos.local"
  else
    echo "そのまま続行します。"
  fi
fi

REPO_PATHS=()
REPO_TEMPLATES=()
while IFS= read -r line; do
  [[ "$line" =~ ^#.*$ ]] && continue
  [ -z "$line" ] && continue
  repo_path=$(eval echo "$(echo "$line" | awk '{print $1}')")
  template_type=$(echo "$line" | awk '{print $2}')
  REPO_PATHS+=("$repo_path")
  REPO_TEMPLATES+=("$template_type")
done < "$REPOS_FILE"

EXCLUDE_PATTERNS=("CLAUDE.md" "AGENTS.md" ".claude/rules/")

echo "--- .git/info/exclude 設定 ---"
for i in "${!REPO_PATHS[@]}"; do
  repo="${REPO_PATHS[$i]}"
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
for i in "${!REPO_PATHS[@]}"; do
  repo="${REPO_PATHS[$i]}"
  template="${REPO_TEMPLATES[$i]}"

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

  env_template="$DOTFILES_DIR/buzzkuri/_templates/$template/.env.template"
  env_file="$DOTFILES_DIR/buzzkuri/_templates/$template/.env.local"
  if [ -f "$env_template" ] && [ ! -f "$env_file" ]; then
    echo "⚠️  env ファイルなし（スキップ）: $repo  [テンプレート: $template]"
    echo "    → cp $env_template $env_file"
    echo "    → 編集後に: bash $DOTFILES_DIR/scripts/sync-rules-to-project.sh $template $repo $env_file"
    continue
  fi

  echo "同期中: $repo  [テンプレート: $template]"
  if [ -f "$env_file" ]; then
    bash "$DOTFILES_DIR/scripts/sync-rules-to-project.sh" "$template" "$repo" "$env_file"
  else
    bash "$DOTFILES_DIR/scripts/sync-rules-to-project.sh" "$template" "$repo"
  fi
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
echo "2. Vim プラグイン: 以下を実行してプラグインをインストール"
echo "   vim +NeoBundleInstall +qall"
echo ""
echo "完了！"
