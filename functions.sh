#!/usr/bin/env bash
# ============================================================================
# 🔧 Bash Utility Functions
# ============================================================================

# ============================================================================
# 📦 Archive Functions
# ============================================================================
extract() {
    if [ -f "$1" ] ; then
        case $1 in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
register_func "extract" "Extract various archive formats" "Archive"

compress() {
    if [ -z "$1" ]; then
        echo "Usage: compress <file/directory> [format]"
        echo "Formats: zip (default), tar, tar.gz, tar.bz2"
        return 1
    fi
    
    local target="$1"
    local format="${2:-zip}"
    
    if [ ! -e "$target" ]; then
        echo "Error: '$target' does not exist"
        return 1
    fi
    
    local basename=$(basename "$target")
    
    case $format in
        zip)
            zip -r "${basename}.zip" "$target"
            echo "Created: ${basename}.zip"
            ;;
        tar)
            tar cf "${basename}.tar" "$target"
            echo "Created: ${basename}.tar"
            ;;
        tar.gz|tgz)
            tar czf "${basename}.tar.gz" "$target"
            echo "Created: ${basename}.tar.gz"
            ;;
        tar.bz2|tbz2)
            tar cjf "${basename}.tar.bz2" "$target"
            echo "Created: ${basename}.tar.bz2"
            ;;
        *)
            echo "Unsupported format: $format"
            echo "Supported formats: zip, tar, tar.gz, tar.bz2"
            return 1
            ;;
    esac
}
register_func "compress" "Compress files/directories (zip, tar, tar.gz, tar.bz2)" "Archive"

# ============================================================================
# 📁 Directory Functions
# ============================================================================
mkcd() {
    mkdir -p "$1" && cd "$1"
}
register_func "mkcd" "Create directory and cd into it" "Directory"

c() {
    if [ -d "$1" ]; then
        cd "$1" || return
    elif [ -f "$1" ]; then
        cd "$(dirname "$1")" || return
    else
        echo -e "\e[31m$1 is not a valid file or directory\e[0m"
        return 1
    fi
    echo -e "\e[32mcd to $(pwd)\e[0m"
    ls
}
register_func "c" "Smart cd - change to directory or file's parent directory" "Directory"

# ============================================================================
# 📊 System Information Functions
# ============================================================================
info() {
    echo -e "\n${BBlue}Current Location:${Color_Off}"
    pwd
    echo -e "\n${BBlue}Directory Contents:${Color_Off}"
    ls -la
    echo -e "\n${BBlue}Disk Usage:${Color_Off}"
    df -h
    echo -e "\n${BBlue}Memory Usage:${Color_Off}"
    free -h
}
register_func "info" "Show location, contents, disk and memory usage" "System"

show_system_info() {
    echo -e "${BGreen}╔══════════════════════════════════════════════════════════════╗${Color_Off}"
    echo -e "${BGreen}║                    🖥️  System Information                     ║${Color_Off}"
    echo -e "${BGreen}╠══════════════════════════════════════════════════════════════╣${Color_Off}"
    echo -e "${BYellow} Hostname:${Color_Off} $(hostname)"
    echo -e "${BYellow} Uptime:${Color_Off} $(uptime -p 2>/dev/null || uptime)"
    echo -e "${BYellow} Kernel:${Color_Off} $(uname -r)"
    echo -e "${BYellow} Shell:${Color_Off} $SHELL"
    if command -v lsb_release &> /dev/null; then
        echo -e "${BYellow} OS:${Color_Off} $(lsb_release -d | cut -f2)"
    fi
    echo -e "${BGreen}╚══════════════════════════════════════════════════════════════╝${Color_Off}"
}
register_func "show_system_info" "Display detailed system information" "System"

# ============================================================================
# 🔍 FZF Enhanced Functions
# ============================================================================
if command -v fzf &> /dev/null; then
    # Enhanced cd with fzf
    fcd() {
        local dir
        dir=$(find ${1:-.} -path '*/\.*' -prune -o -type d -print 2> /dev/null | fzf +m) &&
        cd "$dir"
    }
    register_func "fcd" "Fuzzy find and cd to directory" "FZF"
    
    # Enhanced file opening with fzf
    fopen() {
        local file
        file=$(find ${1:-.} -type f 2> /dev/null | fzf +m) &&
        ${EDITOR:-nano} "$file"
    }
    register_func "fopen" "Fuzzy find and open file in editor" "FZF"
    
    # Enhanced process kill with fzf
    fkill() {
        local pid
        pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
        if [ -n "$pid" ]; then
            echo "$pid" | xargs kill -"${1:-9}"
        fi
    }
    register_func "fkill" "Fuzzy find and kill process" "FZF"
    
    # Enhanced git branch checkout with fzf
    fgco() {
        local branch
        branch=$(git branch -a | grep -v HEAD | sed 's/.* //' | sed 's#remotes/[^/]*/##' | sort -u | fzf +m) &&
        git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
    }
    register_func "fgco" "Fuzzy find and checkout git branch" "Git"
    
    # Enhanced history search with fzf
    fh() {
        eval "$(history | fzf +s --tac | sed 's/ *[0-9]*\*? *//' | sed 's/\\/\\\\/g')"
    }
    register_func "fh" "Fuzzy search and execute command from history" "FZF"
fi

# ============================================================================
# 🔄 Rsync and Path Functions
# ============================================================================
rs_git_sync() {
    local x="rsync -avzhe ssh --progress --filter=':- .gitignore' $1 $2 --delete"
    watch "$x"
}
register_func "rs_git_sync" "Sync directories via rsync respecting .gitignore" "File Operations"

absp() {
    local file_or_folder="$1"
    local current_dir
    current_dir=$(pwd)

    if [ -z "$file_or_folder" ]; then
        file_or_folder=$(fzf)
    fi

    file_or_folder=${file_or_folder#"./"}
    file_or_folder=${file_or_folder#"/"}

    if [[ "$file_or_folder" != /* ]]; then
        file_or_folder="$current_dir/$file_or_folder"
    fi

    file_or_folder=$(echo "$file_or_folder" | sed 's|//|/|g')
    echo "$cname:$file_or_folder"
}
register_func "absp" "Get absolute path of file/folder with FZF" "File Operations"

# ============================================================================
# 🐳 Docker Functions
# ============================================================================
docker_run() {
    local HISTORY_FILE="${HOME}/docker-history/${PWD}"
    mkdir -p "${HOME}/docker-history"
    touch "$HISTORY_FILE"

    local CONTAINER_NAME
    CONTAINER_NAME=${1:-$DOCKER_ACTIVE_CONTAINER}

    if docker ps -a | grep -q "$CONTAINER_NAME"; then
        echo "Restarting $CONTAINER_NAME"
        docker kill "$CONTAINER_NAME" >/dev/null 2>&1
        docker rm "$CONTAINER_NAME" >/dev/null 2>&1
    else
        echo "Starting $CONTAINER_NAME"
    fi

    docker run --name "$CONTAINER_NAME" -it -p "${2:-8888}:8888" \
        -v "$(pwd):/docker-container/" \
        -v "$HISTORY_FILE:/root/.bash_history" \
        --rm "$DOCKER_ACTIVE_IMAGE" /bin/bash
}
register_func "docker_run" "Run docker container with persistent history" "Docker"

docker_attach() {
    echo "Which container do you want to attach?"
    docker ps -a
    read -r container_name
    echo "Attaching $container_name"
    docker attach "$container_name"
}
register_func "docker_attach" "Attach to a running docker container" "Docker"

docker_commit() {
    docker commit "$DOCKER_ACTIVE_CONTAINER" "$DOCKER_ACTIVE_IMAGE"
    echo "Would you like to push $DOCKER_ACTIVE_IMAGE image to the cloud? (y/n)"
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "Pushing $DOCKER_ACTIVE_IMAGE"
        docker push "$DOCKER_ACTIVE_IMAGE"
    fi
}
register_func "docker_commit" "Commit docker container and optionally push" "Docker"

docker_kill() {
    docker kill $(docker ps -qa)
    docker rm $(docker ps -qa)
}
register_func "docker_kill" "Kill and remove all docker containers" "Docker"

# ============================================================================
# 🖥️  Tmux Functions
# ============================================================================
tm() {
    local change session
    [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
    if [ -n "$1" ]; then
        tmux "$change" -t "$1" 2>/dev/null || (tmux new-session -d -s "$1" && tmux "$change" -t "$1")
        return
    fi
    session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0)
    if [ -n "$session" ]; then
        tmux "$change" -t "$session"
    else
        echo "No sessions found."
    fi
}
register_func "tm" "Fuzzy tmux session switcher/creator" "Tmux"

# ============================================================================
# 🔍 File Search Functions
# ============================================================================
fif() {
    local s=""
    for arg in "$@"; do
        s+="$arg "
    done
    local _file
    _file=$(grep --line-buffered --color=never -I -r "$s" * | fzf)
    local file
    file=$(echo "$_file" | cut -d':' -f1)
    echo "$file"
}
register_func "fif" "Find in files and select with FZF" "Search"

fiv() {
    vi "$(fif "$@")"
}
register_func "fiv" "Find in files and open in vim" "Search"

fic() {
    code "$(fif "$@")"
}
register_func "fic" "Find in files and open in VS Code" "Search"

# ============================================================================
# 🐍 Python Process Management
# ============================================================================
kill_all_python_except_jupyter() {
    ps aux | grep -i python | grep -vw jupyter | grep -vw vscode | grep "$USER" | awk '{print $2}' | xargs -r kill -9
}
register_func "kill_all_python_except_jupyter" "Kill all Python processes except Jupyter and VS Code" "Python"

kill_all_python_jupyter() {
    ps aux | grep -i python | grep -vw vscode | awk '{print $2}' | xargs -r kill -9
}
register_func "kill_all_python_jupyter" "Kill all Python processes except VS Code" "Python"

# ============================================================================
# 🌐 Network and SSH Functions
# ============================================================================
use_ssh() {
    local root
    root=$(pwd)
    cd "$HOME/.ssh" || return
    rm -f config
    cp "config_$1" config
    cd "$root" || return
}
register_func "use_ssh" "Switch SSH config profiles" "Network"

test_proxy() {
    local output
    output=$(curl -x 127.0.0.1:"$1" -I https://www.google.com)
    if echo "$output" | grep -q "200"; then
        echo "Proxy is working"
    else
        echo "Proxy is not working"
    fi
}
register_func "test_proxy" "Test if proxy is working" "Network"

# ============================================================================
# ⚙️  Environment and Configuration Functions
# ============================================================================
set_env() {
    local varname=$1
    local value=$2
    local env_file="$HOME/.env"

    if [ -z "$varname" ] || [ -z "$value" ]; then
        echo "Usage: set_env <varname> <value>"
        return 1
    fi

    touch "$env_file"
    grep -q "^${varname}=" "$env_file" && sed -i "/^${varname}=/d" "$env_file"
    echo "${varname}=${value}" >> "$env_file"
    echo "Persisted ${varname} in ~/.env"
}
register_func "set_env" "Persist environment variable to ~/.env" "Config"

unset_env() {
    local varname=$1
    local env_file="$HOME/.env"

    if [ -z "$varname" ]; then
        echo "Usage: unset_env <varname>"
        return 1
    fi

    if [[ -f "$env_file" ]]; then
        sed -i "/^${varname}=/d" "$env_file"
        echo "Unset ${varname} from ~/.env"
    fi

    unset "$varname"
}
register_func "unset_env" "Remove environment variable from ~/.env" "Config"

setup_vscode() {
    if command -v code &>/dev/null; then
        export EDITOR=code
    elif command -v code-insiders &>/dev/null; then
        export EDITOR=code-insiders
        alias code='code-insiders'
    else
        export EDITOR=vi
    fi
}
register_func "setup_vscode" "Setup VS Code as default editor" "Config"

set_alias() {
    local aliasname=$1
    local command=$2
    local alias_file="$HOME/dotfiles-bash/alias.sh"

    if [ -z "$aliasname" ] || [ -z "$command" ]; then
        echo "Usage: set_alias <aliasname> <command>"
        return 1
    fi

    grep -q "^alias ${aliasname}=" "$alias_file" && sed -i "/^alias ${aliasname}=/d" "$alias_file"
    echo "alias ${aliasname}=\"${command}\"" >> "$alias_file"
    source "$alias_file"
    echo "Set alias ${aliasname}=\"${command}\" in $alias_file"
}
register_func "set_alias" "Create or update an alias" "Config"

# ============================================================================
# 🔧 Utility Functions
# ============================================================================
timebash() {
  local shell=${1:-$SHELL}
  for i in $(seq 1 10); do /usr/bin/time "$shell" -i -c exit; done
}
register_func "timebash" "Benchmark shell startup time" "Utilities"

bash_reload() {
    echo "🔄 Reloading bash configuration..."
    source ~/.bashrc
    echo "✅ Done!"
}
register_func "bash_reload" "Reload bash configuration" "Utilities"