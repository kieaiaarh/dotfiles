#!/bin/sh
# PreToolUse hook: Write / Edit ツールで .sh ファイルを書き込む際にセキュリティチェックを行う
# exit 0: 許可
# exit 2: ブロック（エラーメッセージを表示して書き込みを止める）
set -eu

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
content=$(printf '%s' "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null || true)

# .sh ファイル以外はスキップ
case "$file_path" in
  *.sh) ;;
  *) exit 0 ;;
esac

# jq失敗等でcontentが取れなければスキップ（false negativeを許容しブロックしない）
if [ -z "$content" ]; then
  exit 0
fi

errors=""
warnings=""

# パスワードをコマンドライン引数で渡していないかチェック（ps aux に露出する）
if echo "$content" | grep -qE -- '-p"?\$[A-Za-z_]+|--password="?\$[A-Za-z_]+'; then
  errors="${errors}🔴 パスワードがコマンドライン引数に含まれています (-p\"\$PASS\" 等)\n"
  errors="${errors}   → MYSQL_PWD=\"\$DB_PASSWORD\" コマンド ... の形式で環境変数経由で渡してください\n\n"
fi

# rm -rf で変数が引用されていない（誤展開で意図しないパスを削除する恐れ）
if echo "$content" | grep -qE 'rm[[:space:]]+-[rRf]+[[:space:]]+[^"'\'']*\$[A-Za-z_]'; then
  errors="${errors}🔴 rm -rf で変数が引用されていません（誤展開で意図しないパスを削除する恐れ）\n"
  errors="${errors}   → rm -rf \"\$VAR\" のように必ずダブルクォートで囲んでください\n\n"
fi

# git push --force を含むスクリプトは block（手動操作のみ許可）
if echo "$content" | grep -qE 'git[[:space:]]+push[[:space:]]+(--force(-with-lease)?|-f)\b'; then
  errors="${errors}🔴 git push --force を含むスクリプトです\n"
  errors="${errors}   → スクリプトに force-push を埋め込まないでください（手動操作にとどめる）\n\n"
fi

# aws delete-stack / cdk destroy は警告のみ（block しない、cdk-deploy-preflight への誘導）
if echo "$content" | grep -qE 'aws[[:space:]].*\bdelete-stack\b|\bcdk[[:space:]]+destroy\b'; then
  warnings="${warnings}🟡 aws delete-stack / cdk destroy を含むスクリプトです\n"
  warnings="${warnings}   → 実行前に cdk-deploy-preflight skill で stack 状態を確認してください\n\n"
fi

# バックグラウンドプロセスを使っている場合の追加チェック
if echo "$content" | grep -qE 'nohup |&$| &$'; then

  # trap cleanup EXIT がリソース確保より後に登録されていないかチェック
  if echo "$content" | grep -qE 'trap .+ EXIT'; then
    trap_line=$(echo "$content" | grep -nE 'trap .+ EXIT' | head -1 | cut -d: -f1)
    nohup_line=$(echo "$content" | grep -nE 'nohup | &$' | head -1 | cut -d: -f1)
    if [ -n "$trap_line" ] && [ -n "$nohup_line" ] && [ "$trap_line" -gt "$nohup_line" ]; then
      errors="${errors}🟠 trap cleanup EXIT がバックグラウンド起動より後に登録されています\n"
      errors="${errors}   → trap はリソース確保（nohup / &）より前に登録してください\n\n"
    fi
  fi

  # sleep で固定待機していないかチェック（nc/curl等のポーリングがなければ警告）
  if echo "$content" | grep -qE 'sleep [0-9]+' && ! echo "$content" | grep -qE 'nc -z|curl .*(--retry|--connect-timeout)|wait_for'; then
    errors="${errors}🟡 sleep による固定待機が検出されました\n"
    errors="${errors}   → nc -z / curl 等でポート疎通確認のポーリングを使ってください\n\n"
  fi

fi

if [ -n "$errors" ]; then
  echo "❌ シェルスクリプトのセキュリティ・品質チェックに失敗しました: $file_path" >&2
  echo "" >&2
  printf "%b" "$errors" >&2
  if [ -n "$warnings" ]; then
    printf "%b" "$warnings" >&2
  fi
  echo "詳細は .claude/rules/shell.md を参照してください" >&2
  exit 2
fi

# エラーは無いが警告がある場合は stderr に出力して許可（exit 0）
if [ -n "$warnings" ]; then
  echo "⚠️  シェルスクリプトの注意事項: $file_path" >&2
  echo "" >&2
  printf "%b" "$warnings" >&2
fi

exit 0
