#!/bin/sh
# PreToolUse hook: Bash ツールで「Makefile / Ridgepole 経由必須」規約を機械的にガードする
# exit 0: 許可（警告は stderr に出力する場合あり）
# exit 2: ブロック
set -eu

cmd=$(printf '%s\n' "$CLAUDE_TOOL_INPUT" | jq -r '.command // empty' 2>/dev/null || true)

if [ -z "$cmd" ]; then
  exit 0
fi

# 推奨ルート（make / git）はそのまま許可
case "$cmd" in
  make\ *|git\ *) exit 0 ;;
esac

# ── block: Ridgepole 経由でない DDL ──
# mysql / mysqldump / mysqlsh で ALTER/DROP/CREATE/TRUNCATE TABLE を含むコマンドは止める
if echo "$cmd" | grep -qE '\bmysql(dump|sh)?\b' && \
   echo "$cmd" | grep -qiE '\b(ALTER|DROP|CREATE|TRUNCATE)[[:space:]]+TABLE\b'; then
  echo "❌ Ridgepole 経由でない DDL を検知しました" >&2
  echo "" >&2
  echo "🔴 mysql 系コマンドで TABLE の DDL を実行しようとしています" >&2
  echo "   → DB スキーマ変更は make ridgepole_apply 経由で行ってください" >&2
  echo "   → 詳細は CLAUDE.md「DB変更は AI 単独判断禁止」を参照" >&2
  exit 2
fi

# ── 警告（block しない、stderr に出力）──
warnings=""

# docker compose 直叩き（read-only サブコマンドは除外）
if echo "$cmd" | grep -qE '^[[:space:]]*docker[[:space:]]+compose[[:space:]]'; then
  case "$cmd" in
    *"docker compose ps"*|*"docker compose logs"*|*"docker compose top"*|*"docker compose config"*|*"docker compose images"*|*"docker compose port"*|*"docker compose version"*) ;;
    *) warnings="${warnings}🟡 docker compose を直接実行しています\n   → make ターゲット（make db_up_d 等）を優先してください\n\n" ;;
  esac
fi

# bundle exec の直叩き
if echo "$cmd" | grep -qE '^[[:space:]]*bundle[[:space:]]+exec[[:space:]]'; then
  warnings="${warnings}🟡 bundle exec を直接実行しています\n   → make 経由（make rspec_exec / make rubocop_exec 等）を優先してください\n\n"
fi

# bin/rspec / bin/rails の直叩き
if echo "$cmd" | grep -qE '^[[:space:]]*bin/(rspec|rails)([[:space:]]|$)'; then
  warnings="${warnings}🟡 bin/rspec / bin/rails を直接実行しています\n   → make ターゲット（make rspec_exec / make rails_c 等）を優先してください\n\n"
fi

if [ -n "$warnings" ]; then
  echo "⚠️  Bash 実行に関する注意事項" >&2
  echo "" >&2
  printf "%b" "$warnings" >&2
fi

exit 0
