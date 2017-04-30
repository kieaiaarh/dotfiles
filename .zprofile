autoload -U compinit
compinit

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin:/usr/local/bin

ZSH_THEME="af-magic"
alias ll='ls -lhaR'

export PATH
# export PS1='\[\e[0;32m\]\u@ \[\e[1;34m\]\w${text} $\[\e[m\] '
# prompt
# PROMPT='%F{green}%~%f $ '
# PROMPT='%m:%F{green}%c%f %n%# '

# 重複を記録しない
setopt hist_ignore_dups
# historyを共有
setopt share_history
# 余分な空白は詰めて記録
setopt hist_reduce_blanks
# 補完時にヒストリを自動的に展開
setopt hist_expand
# 履歴をインクリメンタルに追加
setopt inc_append_history

export AWS_REGION=ap-northeast-1
alias devlog='tail -n 30 -f fuel/app/logs/development/`date +\%Y/\%m/\%d`.php'
alias ll='ls -lha -G'
alias grep='grep --color'
alias df='df -h'
alias ps='ps --sort=start_time'
alias v='vim'

alias pt='lsof -i -P | grep "LISTEN"'
# git
alias gb='git branch'
alias gs='git status'
alias gd='git diff '
alias gdall="git branch --merged | grep -v '*' | xargs -I % git branch -d %"
alias gc='git checkout'
alias gl='git log --oneline --abbrev-commit'
alias mylog='git log --graph --name-status --pretty=format:"%C(red)%h %C(green)%an %Creset%s %C(yellow)%d%Creset"'
alias rl='rails'
alias bt='rails runner'
alias ga='git rm `git ls-files --deleted`'
alias rls='rails s -b 0.0.0.0'
# alias rls='rails s -b 192.168.179.3'
alias rc='rails console'
alias rct='rails console --sandbox'
alias rk='rake'
alias heroku_bash='heroku run bash '
alias e2h="rake haml:erb2haml"
# ipython
alias jn='jupyter notebook --ip=0.0.0.0'
# alias in='ipython notebook --ip=xxxxxx'
alias zprofile='v ~/.zprofile'
alias reload='source ~/.bash_profile'
alias mg='rake db:migrate'

# alias c='casperjs'
# alias debug='--verbose --log-level=debug'
# alias info='--verbose --log-level=info'
# alias ct='c test --includes=config/init.js'

alias bash='v ~/.bash_profile'
alias reload='source ~/.bash_profile'

alias ns='sudo nginx'
alias rn='sudo nginx -s reload'
alias rs='sudo nginx -s stop'
alias h='history | grep '
alias mydb="psql -U kieaiaarh -d nikkei"
export PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/kieaiaarh/bin:/home/kieaiaarh/.rbenv/bin:/home/kieaiaarh/.rbenv/shims
PATH="/usr/local/heroku/bin:$PATH"

export JAVA_HOME=/usr/local/src/jdk1.8.0_72
export PATH=$PATH:$JAVA_HOME/bin
export CLASSPATH=.:$JAVA_HOME/jre/lib:$JAVA_HOME/lib:$JAVA_HOME/lib/tools.jar


export PATH=/usr/local/bin:$PATH
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"


# Postgresql
export PGDATA=/usr/local/var/postgres
# alias pgstart='pg_ctl -D /usr/local/var/postgres -l logfile start'
# alias pgstop='pg_ctl -D /usr/local/var/postgres -l logfile stop'
alias pgstart='launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist'
alias pgstop='launchctl unload -w ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist'
#psql -h hostname -U username -d databasename

# export ELASTICPATH=/usr/local/Cellar/elasticsearch/2.3.4/libexec/bin
# export KIBANAPATH=/usr/local/Cellar/elasticsearch/2.3.4/libexec/kibana-4.5.3-darwin-x64/bin
# export PATH=$PATH:$ELASTICPATH:$KIBANAPATH

# misspratinum
# wget -r ftp://lolipop.jp-7555229fea2cbdc6:hr9-gs_qpdb@ftp.7555229fea2cbdc6.lolipop.jp
# rails new misspratinum -d postgresql --skip-keeps --skip-test-unit --no-rc
alias docker_web='docker-compose up -d postgres && sleep 5 && docker-compose run web rake db:create && docker-compose up -d'
# alias docker_web='docker-compose up -d && docker-compose run web rake db:create'
alias docker_all_containers_delete="docker ps -a | awk '{print $1}' | xargs docker rm"
alias docker_all_images_delete="docker images | awk '{print $3}' | xargs docker rmi -f"
alias docker_all_delete="docker_all_containers_delete && docker_all_images_delete"

# ec2
alias aws_lolipop="ssh aws_lolipop"
alias dev_miss_platinum="ssh development_miss_platinum"
alias miss_pratinum="ssh aws_miss_platinum"
# alias aws_lolipop="ssh ec2-user@52.197.117.155"
alias conoha_root='ssh conoha_root'
alias conoha='ssh conoha'
alias sql_conoha='ssh conoha_sql'

PYENV_ROOT=/usr/local/var/pyenv
PATH="$PYENV_ROOT/bin:$PATH"
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

alias py=python
