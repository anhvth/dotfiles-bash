#!/bin/bash
# ============================================================================
# 🎨 Beautiful Color-Coded Bash Configuration
# ============================================================================

# Package Manager Configuration
PACKAGE_MANAGER="uv"  # Options: "conda" or "uv"

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# ============================================================================
# 🎯 History Configuration
# ============================================================================
HISTCONTROL=ignoreboth          # Don't put duplicate lines or lines starting with space
HISTSIZE=10000                  # History size in memory
HISTFILESIZE=20000              # History file size
shopt -s histappend             # Append to history, don't overwrite
shopt -s checkwinsize           # Update window size after each command

# ============================================================================
# 🌈 Color Definitions
# ============================================================================
# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

# ============================================================================
# 🚀 Beautiful Prompt with Git Support
# ============================================================================
# Function to get git branch
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# Function to get git status color
git_status_color() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        if [[ $(git status --porcelain 2>/dev/null) ]]; then
            echo -e "\033[0;31m"  # Red for dirty
        else
            echo -e "\033[0;32m"  # Green for clean
        fi
    fi
}

# Colorful prompt (conda will handle its own environment display)
PS1='\[\033[0;32m\]\u@\h\[\033[0m\]:\[\033[0;34m\]\w\[\033[0m\]\[$(git_status_color)\]$(parse_git_branch)\[\033[0m\]\$ '

# ============================================================================
# 🎨 Colorized Commands
# ============================================================================
# Enable color support for ls and add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# ============================================================================
# � Load Helper System (must be first for registration functions)
# ============================================================================
if [ -f ~/dotfiles-bash/helpers.sh ]; then
    source ~/dotfiles-bash/helpers.sh
fi

# ============================================================================
# �📝 Load Aliases
# ============================================================================
if [ -f ~/dotfiles-bash/alias.sh ]; then
    source ~/dotfiles-bash/alias.sh
fi

# ============================================================================
# 🔧 Environment Variables
# ============================================================================
export EDITOR='vim'
export PAGER='less'
export LESS='-R'
export GREP_COLOR='1;32'

# Add local bin to PATH if it exists
if [ -d "$HOME/.local/bin" ]; then
    PATH="$HOME/.local/bin:$PATH"
fi

# ============================================================================
# 🔍 Improved Command Completion
# ============================================================================
# Enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# ============================================================================
# 🔍 fzf Integration
# ============================================================================
# Load fzf if available
if [ -f ~/.fzf.bash ]; then
    source ~/.fzf.bash
    
    # Custom fzf options
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --inline-info'
    export FZF_DEFAULT_COMMAND='find . -type f -not -path "*/\.git/*" -not -path "*/node_modules/*" -not -path "*/__pycache__/*"'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='find . -type d -not -path "*/\.git/*" -not -path "*/node_modules/*" -not -path "*/__pycache__/*"'
    
    # Rebind fzf keys to avoid conflicts
    bind -x '"\C-f": fzf-file-widget'
    
    # Ctrl+B for directory change
    __fzf_cd_widget() {
        local dir
        dir=$(find . -type d -not -path "*/\.git/*" -not -path "*/node_modules/*" -not -path "*/__pycache__/*" 2>/dev/null | fzf +m)
        if [[ -n "$dir" ]]; then
            cd "$dir"
            READLINE_LINE="# Changed to: $dir"
            READLINE_POINT=0
        fi
    }
    bind -x '"\C-b": __fzf_cd_widget'
fi

# ============================================================================
# 🔧 Tool Installation Functions
# ============================================================================

# Check and install fzf if not available
fzf_install() {
    if command -v fzf &> /dev/null; then
        echo -e "${BGreen}✅ fzf is already installed!${Color_Off}"
        fzf --version
        return 0
    fi
    
    echo -e "${BYellow}🔍 fzf not found. Installing fzf...${Color_Off}"
    
    # Check if git is available
    if ! command -v git &> /dev/null; then
        echo -e "${BRed}❌ Git is required for fzf installation. Please install git first.${Color_Off}"
        return 1
    fi
    
    # Clone fzf repository
    echo -e "${BCyan}📥 Cloning fzf repository...${Color_Off}"
    if git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf; then
        echo -e "${BGreen}✅ fzf repository cloned!${Color_Off}"
        
        echo -e "${BCyan}🔧 Installing fzf...${Color_Off}"
        if ~/.fzf/install --all; then
            echo -e "${BGreen}🎉 fzf installation completed!${Color_Off}"
            echo -e "${BYellow}💡 Please restart your terminal or run 'source ~/.bashrc' to use fzf${Color_Off}"
        else
            echo -e "${BRed}❌ fzf installation failed!${Color_Off}"
            return 1
        fi
    else
        echo -e "${BRed}❌ Failed to clone fzf repository! Please check your internet connection.${Color_Off}"
        return 1
    fi
}

# Check fzf availability on startup
check_fzf() {
    if ! command -v fzf &> /dev/null; then
        echo -e "${BYellow}⚠️  fzf not found! Type 'fzf_install' to install it automatically.${Color_Off}"
        return 1
    fi
    return 0
}
register_func "fzf_install" "Install fzf fuzzy finder" "Installation"
register_func "check_fzf" "Check if fzf is available" "FZF"

# ============================================================================
# ⌨️  Custom Keybindings
# ============================================================================

# Git commit preparation - Ctrl+G
bind -x '"\C-g": "git_prepare_command"'
git_prepare_command() {
    if [ -n "$READLINE_LINE" ]; then
        READLINE_LINE="git add -A && git commit -m \"$READLINE_LINE\""
    else
        READLINE_LINE="git add -A && git commit -v"
    fi
    READLINE_POINT=${#READLINE_LINE}
}

# Edit and rerun command - Ctrl+V
bind '"\C-v": "fc\n"'

# Add sudo to current command - Ctrl+S
bind -x '"\C-s": "add_sudo_command"'
add_sudo_command() {
    READLINE_LINE="sudo $READLINE_LINE"
    READLINE_POINT=${#READLINE_LINE}
}

# Add code-debug to current command - Ctrl+O
bind -x '"\C-o": "add_code_debug_command"'
add_code_debug_command() {
    READLINE_LINE="code-debug \"$READLINE_LINE\""
    READLINE_POINT=${#READLINE_LINE}
}

# List files - Ctrl+N
bind '"\C-n": "ls\n"'

# Search history using fzf - Ctrl+R (overrides default)
if command -v fzf &> /dev/null; then
    bind -x '"\C-r": "search_history_fzf"'
    search_history_fzf() {
        if command -v tac &>/dev/null; then
            READLINE_LINE=$(history | tac | fzf | sed 's/^[ ]*[0-9]*[ ]*//')
        else
            READLINE_LINE=$(history | tail -r 2>/dev/null | fzf | sed 's/^[ ]*[0-9]*[ ]*//') || \
            READLINE_LINE=$(history | fzf | sed 's/^[ ]*[0-9]*[ ]*//')
        fi
        READLINE_POINT=${#READLINE_LINE}
    }
fi

# Show keybindings help - Ctrl+H
bind -x '"\C-h": "show-help"'

# ============================================================================
# 🎉 Final Status Check
# ============================================================================
if [[ $- == *i* ]]; then
    # Disable XON/XOFF flow control to free up Ctrl+S and Ctrl+Q
    stty -ixon 2>/dev/null
    
    # Minimal welcome message
    echo -e "${BCyan}💡 Type 'show-help' for available commands${Color_Off}"
fi

# ============================================================================
# 📦 Source Package Manager and Functions
# ============================================================================
# Source package manager utils based on PACKAGE_MANAGER
if [[ "$PACKAGE_MANAGER" == "conda" ]]; then
    if [ -f ~/dotfiles-bash/conda_utils.sh ]; then
        source ~/dotfiles-bash/conda_utils.sh
    fi
elif [[ "$PACKAGE_MANAGER" == "uv" ]]; then
    if [ -f ~/dotfiles-bash/uv_utils.sh ]; then
        source ~/dotfiles-bash/uv_utils.sh
    fi
fi

# Source utility functions
if [ -f ~/dotfiles-bash/functions.sh ]; then
    source ~/dotfiles-bash/functions.sh
fi
