#!/bin/bash
# ============================================================================
# 📝 Bash Aliases - All command shortcuts
# ============================================================================

# Check for code-insiders and use it if available
if command -v code-insiders &> /dev/null; then
    alias code='code-insiders'
fi

# ============================================================================
# 📁 Directory Navigation Aliases
# ============================================================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'

register_alias ".." "Go up one directory" "Navigation"
register_alias "..." "Go up two directories" "Navigation"
register_alias "...." "Go up three directories" "Navigation"
register_alias "....." "Go up four directories" "Navigation"
register_alias "~" "Go to home directory" "Navigation"
register_alias "-" "Go to previous directory" "Navigation"

# ============================================================================
# 📋 List Directory Contents Aliases
# ============================================================================
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'
alias lll='ls -alF | less'
alias ls='ls --color=auto'
alias lsa='ls -lah'
alias lsl='ls -lhFA | less'

register_alias "l" "List directory contents in columns" "Listing"
register_alias "la" "List all files except . and .." "Listing"
register_alias "ll" "List all files in long format" "Listing"
register_alias "lll" "List all files in long format with less" "Listing"
register_alias "ls" "List with colors" "Listing"
register_alias "lsa" "List all with human-readable sizes" "Listing"
register_alias "lsl" "List long format with less" "Listing"


# ============================================================================
# ⚡ Quick Shortcuts
# ============================================================================
alias c='clear'
alias h='history'
alias j='jobs -l'
alias which='type -a'
alias df='df -H'
alias du='du -ch'
alias free='free -h'

register_alias "c" "Clear terminal screen" "Shortcuts"
register_alias "h" "Show command history" "Shortcuts"
register_alias "j" "List jobs with details" "Shortcuts"
register_alias "which" "Show all locations of command" "Shortcuts"
register_alias "df" "Disk space usage (human readable)" "Shortcuts"
register_alias "du" "Directory size (human readable)" "Shortcuts"
register_alias "free" "Memory usage (human readable)" "Shortcuts"

# ============================================================================
# 🌐 Network Aliases
# ============================================================================
alias ping='ping -c 5'
alias ports='netstat -tulanp'

register_alias "ping" "Ping 5 times" "Network"
register_alias "ports" "Show all listening ports" "Network"

# ============================================================================
# 🔍 Search and Find Aliases
# ============================================================================
alias grep='grep --color=auto'
alias fhere='find . -name'
alias ff='find . -type f -name'
alias fd='find . -type d -name'

register_alias "grep" "Grep with colors" "Search"
register_alias "fhere" "Find by name in current directory" "Search"
register_alias "ff" "Find files by name" "Search"
register_alias "fd" "Find directories by name" "Search"

# ============================================================================
# 📝 Editor Aliases
# ============================================================================
alias vi='vim'

register_alias "vi" "Use vim instead of vi" "Editor"

# ============================================================================
# 🔧 Git Shortcuts
# ============================================================================
alias g='git'
alias gg='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

register_alias "g" "Git shortcut" "Git"
register_alias "gg" "Git status" "Git"
register_alias "ga" "Git add" "Git"
register_alias "gc" "Git commit" "Git"
register_alias "gp" "Git push" "Git"
register_alias "gl" "Git log (one line)" "Git"
register_alias "gd" "Git diff" "Git"
register_alias "gb" "Git branch" "Git"
register_alias "gco" "Git checkout" "Git"

# ============================================================================
# 🔍 Search and Filter Aliases
# ============================================================================
alias fzc='fzf | xargs -r code'

register_alias "fzc" "Fuzzy find and open in VS Code" "FZF"

# ============================================================================
# 🐳 Docker Aliases
# ============================================================================
alias dki='docker images'
alias dk='docker kill'
alias deit='docker exec -it'

register_alias "dki" "List docker images" "Docker"
register_alias "dk" "Kill docker container" "Docker"
register_alias "deit" "Execute interactive terminal in container" "Docker"

# ============================================================================
# 📊 TensorBoard Alias
# ============================================================================
alias tb='tensorboard --logdir '

register_alias "tb" "Start TensorBoard with log directory" "Python"

# ============================================================================
# 🔌 Tmux Aliases
# ============================================================================
alias ta='tmux a -t '
alias tk='tmux kill-session -t'

register_alias "ta" "Attach to tmux session" "Tmux"
register_alias "tk" "Kill tmux session" "Tmux"

# ============================================================================
# 🐍 Python and Jupyter Aliases
# ============================================================================
alias i='ipython'
alias iav='ipython --profile av'
alias ju='jupyter lab --allow-root --ip 0.0.0.0 --port '
alias nb-clean='jupyter nbconvert --ClearOutputPreprocessor.enabled=True --inplace'

register_alias "i" "Start IPython" "Python"
register_alias "iav" "Start IPython with av profile" "Python"
register_alias "ju" "Start Jupyter Lab" "Python"
register_alias "nb-clean" "Clean notebook outputs" "Python"

# ============================================================================
# 🛠️ Utility Aliases
# ============================================================================
alias checksize='sudo du -h ./ | sort -rh | head -n30'
alias gpus='watch -n0.1 nvidia-smi'
alias what-is-my-ip='wget -qO- https://ipecho.net/plain ; echo'
alias kill_processes='awk "{print \$2}" | xargs kill'

register_alias "checksize" "Show top 30 largest directories" "Utilities"
register_alias "gpus" "Watch nvidia-smi in real-time" "Utilities"
register_alias "what-is-my-ip" "Show public IP address" "Utilities"
register_alias "kill_processes" "Kill processes from piped input" "Utilities"

# ============================================================================
# 📦 Rsync Aliases
# ============================================================================
alias rs='rsync -av --progress'

register_alias "rs" "Rsync with progress" "File Operations"

# ============================================================================
# 🛠️ Custom Tools Aliases
# ============================================================================
alias code-debug='$HOME/dotfiles/bin/code-debug'

register_alias "code-debug" "Debug with VS Code" "Editor"

# ============================================================================
# 🔒 SSH Alias
# ============================================================================
alias run-autossh='autossh -M 20000 -o ServerAliveInterval=5 -f -N'

# ============================================================================
# 📝 Dotfiles Alias
# ============================================================================
alias update-dotfiles='cwd=$(pwd) && cd ~/dotfiles && git pull && cd $cwd'

# ============================================================================
# 🎨 FZF Shortcuts (if available)
# ============================================================================
if command -v fzf &> /dev/null; then
    alias fzf='fzf --height 40% --layout=reverse --border'
    alias fzfp='fzf --preview "cat {}"'
    alias fzfd='find . -type d | fzf'
    alias fzff='find . -type f | fzf'
fi
