# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin

export PATH
export PS1='\[\e[1;34m\]\w${text} $\[\e[m\] '

alias devlog='tail -n 30 -f fuel/app/logs/development/`date +\%Y/\%m/\%d`.php'
alias ll='ls -la --color=auto'
alias grep='grep --color'
alias df='df -h'
alias ps='ps --sort=start_time'
