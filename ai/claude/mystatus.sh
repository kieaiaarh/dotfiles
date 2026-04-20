#!/bin/bash
input=$(cat)

# jqで各値を取得
PCT=$(echo "$input" | jq -r '(.context_window.current_usage | (.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens)) * 100 / .context_window.context_window_size | floor')
MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')

# 色の定義
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'
CYAN='\033[36m'
MAGENTA='\033[35m'
RESET='\033[0m'

# 1. パスの省略処理 (末端から2階層を取得)
SHORT_DIR=$(echo "$DIR" | awk -F'/' '{
    if (NF > 3) {
        print "../"$(NF-1)"/"$NF
    } else {
        print $0
    }
}')

# 2. Git情報の取得 (ブランチ名とファイル状態のカウント)
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    [ -z "$BRANCH" ] && BRANCH=$(git rev-parse --short HEAD 2>/dev/null) # Detached HEAD対応

    GIT_STATUS=$(git status --porcelain 2>/dev/null)

    if [ -n "$GIT_STATUS" ]; then
        # 変更あり(Untracked含む)の場合は黄色でブランチ名と状態を表示
        GIT_DETAILS=$(echo "$GIT_STATUS" | awk '
        BEGIN { mod=0; del=0; unt=0 }
        /^??/ { unt++; next }
        / D/ || /^D/ { del++; next }
        { mod++ }
        END {
            res=""
            if(mod>0) res=res "+"mod" "
            if(del>0) res=res "-"del" "
            if(unt>0) res=res "?"unt" "
            sub(/ $/, "", res)
            if(length(res)>0) print "( "res" )"
        }')

        # [git] branch ( +1 ?2 ) のように表示
        GIT_STR=" | ${YELLOW}[git] ${BRANCH} ${GIT_DETAILS}${RESET}"
    else
        # クリーンな場合は緑色でブランチ名のみ表示
        GIT_STR=" | ${GREEN}[git] ${BRANCH}${RESET}"
    fi
else
    GIT_STR=""
fi

# 3. コンテキスト使用率の色定義
if [ "$PCT" -ge 90 ]; then COLOR=$RED
elif [ "$PCT" -ge 70 ]; then COLOR=$YELLOW
else COLOR=$GREEN
fi

# 4. プログレスバーの生成 (ASCII文字のみ)
FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
# '█' '░' はターミナルによっては文字化けや幅ズレを起こすため、'=' と '-' に変更
BAR=$(printf "%${FILLED}s" | tr ' ' '=')$(printf "%${EMPTY}s" | tr ' ' '-')

# 最終出力 (絵文字を削除し、角括弧や色で区別)
echo -e "${CYAN}[dir] ${SHORT_DIR}${RESET}${GIT_STR} | ${MAGENTA}[model] ${MODEL}${RESET} | ${COLOR}[ctx] [${BAR}] ${PCT}%${RESET}"
