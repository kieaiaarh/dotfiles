# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=/Users/kieaiaarh/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
# ZSH_THEME="awesomepanda"
ZSH_THEME="af-magic"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# plugins=(git)
plugins=(git ruby osx bundler brew rails emoji-clock)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# ===== Claude Code =====
export PATH="$HOME/.local/bin:$PATH"

export CLAUDE_BEDROCK_PROFILE="buzzkuri_ai_development"
export CLAUDE_BEDROCK_REGION="us-east-1"

claude_login_dev() {
  aws sso login --profile $CLAUDE_BEDROCK_PROFILE
}

# セッション再開を問い合わせてから claude を起動する共通ヘルパー
_claude_launch() {
  local has_session_flag=0
  for arg in "$@"; do
    case "$arg" in
      --resume|-r|--continue|-c) has_session_flag=1; break ;;
    esac
  done

  if [[ $has_session_flag -eq 0 ]]; then
    echo -n "前回のセッションを再開しますか？ [y/N]: "
    read -r REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
      command claude --resume "$@"
      return
    fi
  fi

  command claude "$@"
}

claude() {
  _claude_launch "$@"
}

claude_subscription() {
  unset CLAUDE_CODE_USE_BEDROCK AWS_PROFILE AWS_REGION ANTHROPIC_API_KEY \
        ANTHROPIC_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL \
        ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL
  _claude_launch "$@"
}

claude_bedrock_sonnet() {
  unset ANTHROPIC_API_KEY
  export CLAUDE_CODE_USE_BEDROCK=1
  export AWS_PROFILE="buzzkuri_ai_development"
  export AWS_REGION="us-east-1"
  export ANTHROPIC_MODEL="us.anthropic.claude-sonnet-4-6"
  export ANTHROPIC_DEFAULT_SONNET_MODEL="us.anthropic.claude-sonnet-4-6"
  export ANTHROPIC_DEFAULT_OPUS_MODEL="us.anthropic.claude-opus-4-6-v1"
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="us.anthropic.claude-haiku-4-5-20251001-v1:0"
  echo "[Bedrock] CLAUDE_CODE_USE_BEDROCK=$CLAUDE_CODE_USE_BEDROCK / MODEL=$ANTHROPIC_MODEL"
  _claude_launch "$@"
}

claude_bedrock_opus() {
  unset ANTHROPIC_API_KEY
  export CLAUDE_CODE_USE_BEDROCK=1
  export AWS_PROFILE="buzzkuri_ai_development"
  export AWS_REGION="us-east-1"
  export ANTHROPIC_MODEL="us.anthropic.claude-opus-4-6-v1"
  export ANTHROPIC_DEFAULT_SONNET_MODEL="us.anthropic.claude-sonnet-4-6"
  export ANTHROPIC_DEFAULT_OPUS_MODEL="us.anthropic.claude-opus-4-6-v1"
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="us.anthropic.claude-haiku-4-5-20251001-v1:0"
  echo "[Bedrock] CLAUDE_CODE_USE_BEDROCK=$CLAUDE_CODE_USE_BEDROCK / MODEL=$ANTHROPIC_MODEL"
  _claude_launch "$@"
}
