#!/bin/bash
# ~/.claude/ 管理対象パスへの直接書き込みをブロック
# Claude 制御ファイルは dotfiles リポ経由で管理する

DOTFILES_CLAUDE="$HOME/work/buzzkuri/dotfiles/ai/claude"

input=$(cat)
file_path=$(echo "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

[ -z "$file_path" ] && exit 0

# ~ を展開
file_path="${file_path/#\~/$HOME}"

HOME_CLAUDE="$HOME/.claude"

# 管理対象パス（dotfiles 経由必須）
MANAGED_PREFIXES=(
  "$HOME_CLAUDE/CLAUDE.md"
  "$HOME_CLAUDE/settings.json"
  "$HOME_CLAUDE/mystatus.sh"
  "$HOME_CLAUDE/commands/"
  "$HOME_CLAUDE/hooks/"
  "$HOME_CLAUDE/skills/"
)

is_managed=0
for prefix in "${MANAGED_PREFIXES[@]}"; do
  if [[ "$file_path" == "$prefix"* ]]; then
    is_managed=1
    break
  fi
done

[ "$is_managed" -eq 0 ] && exit 0

# dotfiles 経由（symlink）かチェック：ファイルまたは祖先ディレクトリが dotfiles を指しているか
check_path="$file_path"
while [[ "$check_path" != "/" && "$check_path" != "$HOME" ]]; do
  if [ -L "$check_path" ]; then
    real=$(readlink -f "$check_path" 2>/dev/null || echo "")
    if [[ "$real" == "$DOTFILES_CLAUDE"* ]]; then
      exit 0
    fi
  fi
  check_path=$(dirname "$check_path")
done

# 直接書き込み → ブロック
cat >&2 <<'MSG'
⛔ ~/.claude/ 管理対象ファイルへの直接書き込みはブロックされました。

Claude 制御ファイルは必ず dotfiles リポ経由で管理してください:
  1. ~/work/buzzkuri/dotfiles/ai/claude/ 以下に追加・編集
  2. bash ~/work/buzzkuri/dotfiles/install.sh を実行

管理対象: CLAUDE.md / settings.json / mystatus.sh / commands/ / hooks/ / skills/
MSG
exit 2
