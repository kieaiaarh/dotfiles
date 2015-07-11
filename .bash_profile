# .bash_profile

# # Get the aliases and functions
if [ -f ~/.bashrc ]; then
  > . ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin:

export PATH=$PATH:$HOME/.rbenv/bin:$HOME/.rbenv/shimsexport 
export PS1="\[\e[1;32m\]\u\[\e[m\] \[\e[1;34m\]\W\[\e[m\] $ "
export PATH
