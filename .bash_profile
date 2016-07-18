# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin:/usr/local/bin

export PATH
export PS1='\[\e[0;32m\]\u@ \[\e[1;34m\]\w${text} $\[\e[m\] '

alias devlog='tail -n 30 -f fuel/app/logs/development/`date +\%Y/\%m/\%d`.php'
alias ll='ls -lha -G'
alias grep='grep --color'
alias df='df -h'
alias ps='ps --sort=start_time'
alias v='vim'

alias pt='sudo lsof -i -P | grep "LISTEN"'
# git
alias gb='git branch'
alias gs='git status'
alias gd='git diff '
alias gc='git checkout'
alias gl='git log --oneline --abbrev-commit'
alias mylog='git log --graph --name-status --pretty=format:"%C(red)%h %C(green)%an %Creset%s %C(yellow)%d%Creset"'
alias rl='rails'
alias ga='git rm `git ls-files --deleted`'
alias rls='rails s -b xxxxxxx'
alias rc='rails console'
alias rct='rails console --sandbox'
alias rk='rake'
alias rs='rspec'
alias heroku_bash='heroku run bash '
alias e2h="rake haml:replace_erbs"
# ipython
# alias in='ipython notebook --ip=0.0.0.0'
alias in='ipython notebook --ip=xxxxxx'
alias bash='v ~/.bash_profile'
alias reload='source ~/.bash_profile'
alias mg='rake db:migrate'

# alias c='casperjs'
# alias debug='--verbose --log-level=debug'
# alias info='--verbose --log-level=info'
# alias ct='c test --includes=config/init.js'

alias bash='v ~/.bash_profile'
alias reload='source ~/.bash_profile'

alias rn='sudo service nginx restart'
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


# Postgre
export PGDATA=/usr/local/var/postgres
alias pgstart='pg_ctl -D /usr/local/var/postgres -l logfile start'
alias pgstop='pg_ctl -D /usr/local/var/postgres -l logfile stop'
