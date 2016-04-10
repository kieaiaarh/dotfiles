# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin

export PATH
export PS1='\[\e[0;32m\]\u@\h\e[m\] \[\e[1;34m\]\w${text} $\[\e[m\] '

alias devlog='tail -n 30 -f fuel/app/logs/development/`date +\%Y/\%m/\%d`.php'
alias ll='ls -lha --color=auto'
alias grep='grep --color'
alias df='df -h'
alias ps='ps --sort=start_time'
alias v='vim'
alias gb='git branch'
alias gs='git status'
alias gd='git diff '
alias gc='git checkout'
alias gl='git log'
alias rl='rails'
alias ga='git rm `git ls-files --deleted`'
alias rls='rails s -b 192.168.33.16'
alias rc='rails console'
alias rk='rake'
alias rs='rspec'
alias heroku_bash='heroku run bash '

# ipython
alias in='ipython notebook --ip=0.0.0.0'

alias c='casperjs'
# alias debug='--verbose --log-level=debug'
# alias info='--verbose --log-level=info'
alias ct='c test --includes=config/init.js'

# hub
eval "$(hub alias -s)" # bash

alias bash='v ~/.bash_profile'
alias reload='source ~/.bash_profile'

alias rn='sudo service nginx restart'
alias rp='sudo service php-fpm restart'
#alias mydb='mysql -h localhost -p -u kieaiaarh -D nikkei'
alias h='history | grep '
alias mydb="psql -U kieaiaarh -d nikkei"
export PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/kieaiaarh/bin:/home/kieaiaarh/.rbenv/bin:/home/kieaiaarh/.rbenv/shims
PATH="/usr/local/heroku/bin:$PATH"
# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
