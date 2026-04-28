#!/bin/sh
# PreToolUse hook: Write / Edit ツールで .sh ファイルを書き込む際にセキュリティチェックを行う
# exit 0: 許可（警告のみ）
# exit 2: ブロック（エラーメッセージを表示して書き込みを止める）
set -eu

file_path=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null || true)
content=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.content // .new_string // empty' 2>/dev/null || true)

# .sh ファイル以外はスキップ
case "$file_path" in
  *.sh) ;;
  *) exit 0 ;;
esac

if [ -z "$content" ]; then
  exit 0
fi

errors=""

# パスワードをコマンドライン引数で渡していないかチェック（ps aux に露出する）
if echo "$content" | grep -qE -- '-p"?\$[A-Za-z_]+|--password="?\$[A-Za-z_]+'; then
  errors="${errors}🔴 パスワードがコマンドライン引数に含まれています (-p\"\$PASS\" 等)\n"
  errors="${errors}   → MYSQL_PWD=\"\$DB_PASSWORD\" コマンド ... の形式で環境変数経由で渡してください\n\n"
fi

# trap cleanup EXIT がリソース確保より後に登録されていないかチェック
# nohup / & の後に trap が出現したら警告
if echo "$content" | grep -q 'nohup\|&$\| &$' && echo "$content" | grep -q 'trap.*EXIT'; then
  trap_line=$(echo "$content" | grep -n 'trap.*EXIT' | head -1 | cut -d: -f1)
  nohup_line=$(echo "$content" | grep -n 'nohup\| &$' | head -1 | cut -d: -f1)
  if [ -n "$trap_line" ] && [ -n "$nohup_line" ] && [ "$trap_line" -gt "$nohup_line" ]; then
    errors="${errors}🟠 trap cleanup EXIT がバックグラウンド起動より後に登録されています\n"
    errors="${errors}   → trap はリソース確保（nohup / &）より前に登録してください\n\n"
  fi
fi

# sleep でプロセス/ポートの準備待ちをしていないかチェック
if echo "$content" | grep -qE 'sleep [0-9]+' && ! echo "$content" | grep -qE 'nc -z|curl .*(--retry|--connect-timeout)|wait_for'; then
  errors="${errors}🟡 sleep による固定待機が検出されました\n"
  errors="${errors}   → nc -z / curl 等でポート疎通確認のポーリングを使ってください\n\n"
fi

if [ -n "$errors" ]; then
  echo "❌ シェルスクリプトのセキュリティ・品質チェックに失敗しました: $file_path" >&2
  echo "" >&2
  printf "%b" "$errors" >&2
  echo "詳細は .claude/rules/shell.md を参照してください" >&2
  exit 2
fi

exit 0
