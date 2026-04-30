#!/bin/bash
# ~/.claude/ 管理対象パス・各リポの .claude/rules/ への直接書き込みをブロック
# Claude 制御ファイルは dotfiles リポ経由で管理する

DOTFILES_CLAUDE="$HOME/work/buzzkuri/dotfiles/ai/claude"
DOTFILES_ROOT="$HOME/work/buzzkuri/dotfiles"

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

# dotfiles リポ内の変更は常に通過
if [[ "$file_path" == "$DOTFILES_ROOT/"* ]]; then
  exit 0
fi

HOME_CLAUDE="$HOME/.claude"

# ── ガード 1: ~/.claude/ 管理対象パス ──────────────────────────────────────
MANAGED_PREFIXES=(
  "$HOME_CLAUDE/CLAUDE.md"
  "$HOME_CLAUDE/settings.json"
  "$HOME_CLAUDE/mystatus.sh"
  "$HOME_CLAUDE/commands/"
  "$HOME_CLAUDE/hooks/"
  "$HOME_CLAUDE/skills/"
)

for prefix in "${MANAGED_PREFIXES[@]}"; do
  if [[ "$file_path" == "$prefix"* ]]; then
    # dotfiles への symlink 経由なら通過
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

    cat >&2 <<'MSG'
⛔ ~/.claude/ 管理対象ファイルへの直接書き込みはブロックされました。

Claude 制御ファイルは必ず dotfiles リポ経由で管理してください:
  1. ~/work/buzzkuri/dotfiles/ai/claude/ 以下に追加・編集
  2. bash ~/work/buzzkuri/dotfiles/install.sh を実行

管理対象: CLAUDE.md / settings.json / mystatus.sh / commands/ / hooks/ / skills/
MSG
    exit 2
  fi
done

# ── ガード 2: 各リポの .claude/rules/ ──────────────────────────────────────
if [[ "$file_path" == *"/.claude/rules/"* ]]; then
  cat >&2 <<'MSG'
⛔ .claude/rules/ への直接書き込みはブロックされました。

rules ファイルは dotfiles テンプレート経由で管理してください:
  1. ~/work/buzzkuri/dotfiles/buzzkuri/_templates/<stack>/rules/<file>.md.template を編集
  2. bash ~/work/buzzkuri/dotfiles/scripts/sync-rules-to-project.sh <stack> <リポパス> を実行

変更が全リポに確実に反映されます。
MSG
  exit 2
fi

exit 0
