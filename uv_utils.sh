#!/bin/bash
# ============================================================================
# 🚀 UV Virtual Environment Management - Unified System
# ============================================================================
# Comprehensive Python virtual environment management with UV
# Adapted from Zsh dotfiles with Bash compatibility

# Global variables
VENV_HISTORY_FILE="$HOME/.cache/dotfiles/venv_history"
VENV_HISTORY_LIMIT=30
VENV_AUTO_ACTIVATE_FILE="$HOME/.cache/dotfiles/venv_auto_activate"

# ============================================================================
# Helper Functions
# ============================================================================

# Save auto-activate path to file for persistence across sessions
_venv_save_auto_activate() {
    local activate_path="$1"
    mkdir -p "$(dirname "$VENV_AUTO_ACTIVATE_FILE")"
    echo "$activate_path" > "$VENV_AUTO_ACTIVATE_FILE"
}

# Clear auto-activate path
_venv_clear_auto_activate() {
    rm -f "$VENV_AUTO_ACTIVATE_FILE"
}

# Load auto-activate path from file
_venv_load_auto_activate() {
    if [[ -f "$VENV_AUTO_ACTIVATE_FILE" ]]; then
        cat "$VENV_AUTO_ACTIVATE_FILE"
    fi
}

# Update VS Code Python interpreter path without spamming errors
_venv_update_vscode_python_path() {
    local python_path="$1"
    local settings_file=".vscode/settings.json"

    [[ -f "$settings_file" ]] || return 1
    [[ -n "$python_path" ]] || return 1

    local err_file output status
    err_file="$(mktemp "${TMPDIR:-/tmp}/vscode-settings.err.XXXXXX")" || return 1

    output="$("$python_path" - "$settings_file" "$python_path" 2>"$err_file" <<'PY'
import json
import sys
from pathlib import Path

settings_path = Path(sys.argv[1])
python_path = sys.argv[2]

def strip_comments(source: str) -> str:
    result = []
    length = len(source)
    i = 0
    in_string = False
    escape = False

    while i < length:
        ch = source[i]
        if in_string:
            result.append(ch)
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            i += 1
            continue

        if ch == '"':
            in_string = True
            result.append(ch)
            i += 1
            continue

        if ch == '/' and i + 1 < length:
            nxt = source[i + 1]
            if nxt == '/':
                i += 2
                while i < length and source[i] not in '\n\r':
                    i += 1
                continue
            if nxt == '*':
                i += 2
                while i + 1 < length and not (source[i] == '*' and source[i + 1] == '/'):
                    i += 1
                i += 2
                continue

        result.append(ch)
        i += 1

    return ''.join(result)

try:
    text = settings_path.read_text(encoding="utf-8")
except FileNotFoundError:
    print("UNCHANGED")
    raise SystemExit(0)

clean_text = strip_comments(text).strip()
if clean_text:
    try:
        data = json.loads(clean_text)
    except json.JSONDecodeError as exc:
        print(f"invalid JSON: {exc}", file=sys.stderr)
        raise SystemExit(1)
else:
    data = {}

if not isinstance(data, dict):
    print("settings.json must contain a JSON object", file=sys.stderr)
    raise SystemExit(1)

needs_update = data.get("python.defaultInterpreterPath") != python_path
if needs_update:
    data["python.defaultInterpreterPath"] = python_path
    tmp_path = settings_path.with_suffix(settings_path.suffix + ".tmp")
    tmp_path.write_text(json.dumps(data, indent=4) + "\n", encoding="utf-8")
    tmp_path.replace(settings_path)

print("UPDATED" if needs_update else "UNCHANGED")
PY
)"
    status=$?
    if (( status != 0 )); then
        local err_msg
        err_msg="$(<"$err_file")"
        rm -f "$err_file"
        [[ -n "$err_msg" ]] && echo "⚠️  Unable to update VS Code settings: ${err_msg%%$'\n'*}"
        return $status
    fi

    rm -f "$err_file"
    if [[ "$output" == "UPDATED" ]]; then
        echo "✅ Updated VS Code python.defaultInterpreterPath to $python_path"
    fi
    return 0
}

# Update history file
_venv_update_history() {
    local activate_path="$1"
    
    mkdir -p "$(dirname "$VENV_HISTORY_FILE")"
    
    local -a entries=()
    entries+=("$activate_path")
    
    if [[ -f "$VENV_HISTORY_FILE" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" || "$line" == "$activate_path" ]] && continue
            entries+=("$line")
        done < "$VENV_HISTORY_FILE"
    fi
    
    if (( ${#entries[@]} > VENV_HISTORY_LIMIT )); then
        entries=("${entries[@]:0:$VENV_HISTORY_LIMIT}")
    fi
    
    : > "$VENV_HISTORY_FILE"
    for line in "${entries[@]}"; do
        printf '%s\n' "$line"
    done >> "$VENV_HISTORY_FILE"
}

# ============================================================================
# Help Documentation
# ============================================================================

venv-help() {
    cat << 'EOF'
🐍 Virtual Environment Management Commands

Core Commands:
  va, atv, ua [PATH]           Activate virtual environment
  vd                           Deactivate current environment  
  vc [OPTIONS] [PATH] [PKG]    Create new UV virtual environment
  vs, atv_select               Select from history with fzf

Management:
  venv-auto                    Show auto-activation status
  vl                           List environments from history
  venv-detect                  Auto-detect environment in current dir

Package Management:
  ul                           List packages (uv pip list)
  ui <package>                 Install package (uv pip install)
  uu <package>                 Uninstall package (uv pip uninstall)

Installation:
  install_uv                   Install UV Python toolchain

Examples:
  va                           # Activate .venv or select from history
  va --auto                    # Activate and enable auto-activation
  vc myproject numpy pandas    # Create environment with packages
  vc --python 3.13             # Create with specific Python version
  vs                           # Fuzzy select from history
  vd                           # Deactivate and disable auto-activation
  vl                           # List all environments

Note: Run 'show-help' to browse all dotfiles commands interactively
EOF
}

# ============================================================================
# Core Functions
# ============================================================================

# Activate virtual environment
venv-activate() {
    if [[ "$1" == "--help" ]]; then
        echo "Usage: va [PATH|--auto]"
        echo "Activate a Python virtual environment."
        echo ""
        echo "Arguments:"
        echo "  PATH      Path to virtualenv directory or activate script"
        echo "  --auto    Enable auto-activation for this environment"
        echo "  (none)    Activate .venv in current directory or select from history"
        echo ""
        echo "Examples:"
        echo "  va                    # Activate .venv or select"
        echo "  va /path/to/myenv     # Activate specific environment"
        echo "  va --auto             # Activate and enable auto-activation"
        echo ""
        echo "Use 'vd' to deactivate and disable auto-activation."
        return 0
    fi

    local enable_auto=false
    local target="$1"
    local activate_path=""

    # Check for --auto flag
    if [[ "$1" == "--auto" ]]; then
        enable_auto=true
        target=""
    fi

    # Determine target
    if [[ -z "$target" ]]; then
        # Check if .venv/bin/activate exists in current directory
        if [[ -f ".venv/bin/activate" ]]; then
            local current_venv_path="$(realpath .venv 2>/dev/null)"
            # If already in the same venv and --auto flag is set, enable auto-activation
            if [[ -n "$VIRTUAL_ENV" && "$(realpath "$VIRTUAL_ENV" 2>/dev/null)" == "$current_venv_path" ]]; then
                if [[ "$enable_auto" == true ]]; then
                    activate_path="$VIRTUAL_ENV/bin/activate"
                    export VENV_AUTO_ACTIVATE_PATH="$activate_path"
                    _venv_save_auto_activate "$activate_path"
                    echo -e "${BGreen}✅ Auto-activation enabled for: ${BYellow}$(basename "$VIRTUAL_ENV")${Color_Off}"
                    echo -e "${BCyan}💡 This environment will activate automatically in new terminals${Color_Off}"
                    return 0
                else
                    echo -e "${BCyan}ℹ️  Virtual environment already active: ${BGreen}$(basename "$VIRTUAL_ENV")${Color_Off}"
                    echo -e "${BCyan}📁 Path: ${BYellow}$VIRTUAL_ENV${Color_Off}"
                    echo -e "${BCyan}💡 Use 'vs' to switch to another environment${Color_Off}"
                    return 0
                fi
            else
                target=".venv"
            fi
        else
            # No local .venv found
            if [[ "$enable_auto" == true && -n "$VIRTUAL_ENV" ]]; then
                # --auto flag with already active venv (not local .venv)
                activate_path="$VIRTUAL_ENV/bin/activate"
                export VENV_AUTO_ACTIVATE_PATH="$activate_path"
                _venv_save_auto_activate "$activate_path"
                echo -e "${BGreen}✅ Auto-activation enabled for: ${BYellow}$(basename "$VIRTUAL_ENV")${Color_Off}"
                echo -e "${BCyan}💡 This environment will activate automatically in new terminals${Color_Off}"
                return 0
            elif [[ -n "$VIRTUAL_ENV" ]]; then
                echo -e "${BCyan}ℹ️  Current environment: ${BGreen}$(basename "$VIRTUAL_ENV")${Color_Off}"
                echo -e "${BCyan}ℹ️  No .venv/bin/activate found in current directory${Color_Off}"
            else
                echo -e "${BCyan}ℹ️  No .venv/bin/activate found in current directory${Color_Off}"
            fi
            echo -e "${BCyan}🔍 Select from available environments:${Color_Off}"
            # Pass through the enable_auto flag to the selection
            if venv-select; then
                # If --auto was specified, enable it for the activated environment
                if [[ "$enable_auto" == true && -n "$VIRTUAL_ENV" ]]; then
                    activate_path="$VIRTUAL_ENV/bin/activate"
                    export VENV_AUTO_ACTIVATE_PATH="$activate_path"
                    _venv_save_auto_activate "$activate_path"
                    echo -e "${BGreen}✅ Auto-activation enabled for this environment${Color_Off}"
                    echo -e "${BCyan}💡 This environment will activate automatically in new terminals${Color_Off}"
                fi
                return 0
            else
                return 1
            fi
        fi
    fi

    # Find activate script
    if [[ -d "$target" ]]; then
        if [[ -f "$target/bin/activate" ]]; then
            activate_path="$target/bin/activate"
        elif [[ -f "$target/activate" ]]; then
            activate_path="$target/activate"
        fi
    elif [[ -f "$target" ]]; then
        activate_path="$target"
    fi

    # Validate activate script
    if [[ -z "$activate_path" || "$(basename "$activate_path")" != "activate" ]]; then
        echo -e "${BRed}❌ venv-activate: could not find activate script for '$target'${Color_Off}"
        return 1
    fi

    activate_path="$(realpath "$activate_path" 2>/dev/null)"
    if [[ ! -f "$activate_path" ]]; then
        echo -e "${BRed}❌ venv-activate: activate script not found at $activate_path${Color_Off}"
        return 1
    fi

    # Activate environment
    echo -e "${BCyan}🔄 Activating virtualenv...${Color_Off}"
    if ! source "$activate_path"; then
        echo -e "${BRed}❌ Failed to source activate script: $activate_path${Color_Off}"
        return 1
    fi
    
    local env_root="$(dirname "$activate_path")"
    # Get a better display name: project/.venv
    local env_display="$(basename "$(dirname "$env_root")")/$(basename "$env_root")"
    echo -e "${BGreen}✅ Activated: ${BYellow}${env_display}${Color_Off}"
    
    # Verify activation worked
    if [[ -z "$VIRTUAL_ENV" ]]; then
        echo -e "${BYellow}⚠️  Warning: VIRTUAL_ENV not set after activation${Color_Off}"
        return 1
    fi
    
    # Update VS Code settings if present
    local python_path
    python_path=$(command -v python 2>/dev/null)
    if [[ -n "$python_path" ]]; then
        _venv_update_vscode_python_path "$python_path" 2>/dev/null
    fi

    # Update history
    _venv_update_history "$activate_path"

    # Enable auto-activation if --auto flag was used
    if [[ "$enable_auto" == true ]]; then
        export VENV_AUTO_ACTIVATE_PATH="$activate_path"
        _venv_save_auto_activate "$activate_path"
        echo -e "${BGreen}✅ Auto-activation enabled for this environment${Color_Off}"
        echo -e "${BCyan}💡 This environment will activate automatically in new terminals${Color_Off}"
    fi
}

# Deactivate virtual environment  
venv-deactivate() {
    if [[ "$1" == "--help" ]]; then
        echo "Usage: vd"
        echo "Deactivate current virtual environment and disable auto-activation."
        return 0
    fi

    if [[ -z "$VIRTUAL_ENV" ]]; then
        echo -e "${BCyan}ℹ️  No virtual environment currently active${Color_Off}"
        # Still clear auto-activation if set
        if [[ -n "$VENV_AUTO_ACTIVATE_PATH" ]]; then
            unset VENV_AUTO_ACTIVATE_PATH
            _venv_clear_auto_activate
            echo -e "${BGreen}✅ Auto-activation disabled${Color_Off}"
        fi
        return 0
    fi

    local old_env="$VIRTUAL_ENV"
    deactivate 2>/dev/null || true
    
    # Disable auto-activation
    unset VENV_AUTO_ACTIVATE_PATH
    _venv_clear_auto_activate

    echo -e "${BGreen}✅ Deactivated virtualenv: ${BYellow}$(basename "$old_env")${Color_Off}"
    echo -e "${BCyan}💡 Auto-activation disabled${Color_Off}"
}

# Create new virtual environment
venv-create() {
    if [[ "$1" == "--help" ]]; then
        echo "Usage: venv-create [UV_OPTIONS...] [PATH] [PACKAGES...]"
        echo "Create a new Python virtual environment using UV."
        echo ""
        echo "Arguments:"
        echo "  UV_OPTIONS    Flags for 'uv venv' (e.g. --python 3.13)"
        echo "  PATH          Path for virtualenv (default: .venv)"
        echo "  PACKAGES      Additional packages to install"
        echo ""
        echo "Examples:"
        echo "  vc                      # Create .venv with basic packages"
        echo "  vc --python 3.13        # Create with Python 3.13"
        echo "  vc .venv numpy pandas   # Create with extra packages"
        echo ""
        echo "Basic packages installed: pip, uv, jupyter"
        return 0
    fi

    if ! command -v uv >/dev/null 2>&1; then
        echo -e "${BRed}❌ UV not found. Please install UV first with 'install_uv'${Color_Off}"
        return 1
    fi

    local -a uv_args=()
    local venv_path=""

    while (( $# > 0 )); do
        case "$1" in
            --help)
                _venv_show_help "venv-create"
                return 0
                ;;
            --)
                shift
                break
                ;;
            -*)
                uv_args+=("$1")
                shift
                ;;
            *)
                venv_path="$1"
                shift
                break
                ;;
        esac
    done

    if [[ -z "$venv_path" ]]; then
        venv_path=".venv"
    fi

    local -a extra_packages=("$@")

    echo -e "${BCyan}🔨 Creating virtual environment at: ${BYellow}$venv_path${Color_Off}"
    if (( ${#uv_args[@]} )); then
        uv venv "${uv_args[@]}" "$venv_path" || return 1
    else
        uv venv "$venv_path" || return 1
    fi

    local venv_root="$(realpath "$venv_path" 2>/dev/null)"
    local activate_script="$venv_root/bin/activate"

    if [[ ! -f "$activate_script" ]]; then
        echo -e "${BRed}❌ Activate script not found at $activate_script${Color_Off}"
        return 1
    fi

    echo -e "${BCyan}📦 Installing basic packages...${Color_Off}"
    if ! source "$activate_script"; then
        echo -e "${BRed}❌ Failed to source activate script: $activate_script${Color_Off}"
        return 1
    fi

    hash -r 2>/dev/null || true

    # Install basic packages
    if (( ${#extra_packages[@]} )); then
        uv pip install pip uv jupyter "${extra_packages[@]}" || return 1
    else
        uv pip install pip uv jupyter || return 1
    fi

    echo -e "${BGreen}✅ Virtual environment created and activated!${Color_Off}"

    # Verify tools are from venv
    local -a tools=(pip jupyter)
    local venv_bin="$venv_root/bin"
    for cmd in "${tools[@]}"; do
        local cmd_path=$(command -v "$cmd" 2>/dev/null)
        local expected="$venv_bin/$cmd"
        if [[ -z "$cmd_path" ]]; then
            echo -e "${BYellow}⚠️  $cmd not found after installation${Color_Off}"
            continue
        fi
        cmd_path="$(realpath "$cmd_path" 2>/dev/null)"
        expected="$(realpath "$expected" 2>/dev/null)"
        if [[ "$cmd_path" != "$expected" ]]; then
            echo -e "${BYellow}⚠️  $cmd not from venv: $cmd_path${Color_Off}"
            echo -e "${BYellow}   Expected: $expected${Color_Off}"
        else
            echo -e "${BGreen}✅ $cmd: ${BYellow}$cmd_path${Color_Off}"
        fi
    done

    # Update history
    _venv_update_history "$activate_script"

    # Note: Use 'va --auto' to enable auto-activation
    echo -e "${BCyan}💡 Tip: Run 'va --auto' to enable auto-activation for this environment${Color_Off}"
}

# Select from history with fzf
venv-select() {
    if [[ "$1" == "--help" ]]; then
        echo "Usage: venv-select"
        echo "Select and activate a virtual environment from history using fzf."
        echo "Fallback to most recent if fzf is not available."
        return 0
    fi

    if [[ ! -f "$VENV_HISTORY_FILE" ]]; then
        echo -e "${BRed}❌ No virtual environment history found. Use 'venv-activate' to create history.${Color_Off}"
        return 1
    fi

    # Filter out deleted environments and update history file
    local -a valid_entries=()
    local cleaned=false
    while IFS= read -r path; do
        [[ -z "$path" ]] && continue
        if [[ -f "$path" ]]; then
            valid_entries+=("$path")
        else
            cleaned=true
        fi
    done < "$VENV_HISTORY_FILE"

    # Update history file if we removed any entries
    if [[ "$cleaned" == true ]]; then
        : > "$VENV_HISTORY_FILE"
        for entry in "${valid_entries[@]}"; do
            printf '%s\n' "$entry"
        done >> "$VENV_HISTORY_FILE"
    fi

    if (( ${#valid_entries[@]} == 0 )); then
        echo -e "${BRed}❌ No valid virtual environments found in history${Color_Off}"
        return 1
    fi

    local selection=""
    if command -v fzf >/dev/null 2>&1; then
        selection=$(printf '%s\n' "${valid_entries[@]}" | fzf --prompt="🐍 venv> " --height=40% --reverse)
    else
        selection="${valid_entries[0]}"
        if [[ -n "$selection" ]]; then
            echo -e "${BCyan}ℹ️  fzf not found; using most recent: ${BYellow}$selection${Color_Off}"
        fi
    fi

    if [[ -z "$selection" ]]; then
        echo -e "${BRed}❌ No environment selected${Color_Off}"
        return 1
    fi

    venv-activate "$selection"
}

# ============================================================================
# Management Functions  
# ============================================================================

# Auto-activation status check
venv-auto() {
    if [[ "$1" == "--help" ]]; then
        echo "Usage: venv-auto"
        echo "Show current auto-activation status."
        echo ""
        echo "To enable: va --auto"
        echo "To disable: vd"
        return 0
    fi

    local path="${VENV_AUTO_ACTIVATE_PATH:-none}"
    if [[ -z "$path" || "$path" == "none" ]]; then
        path="$(_venv_load_auto_activate)"
    fi
    
    if [[ -z "$path" || "$path" == "none" ]]; then
        echo -e "${BCyan}🔧 Auto-activation: ${BYellow}disabled${Color_Off}"
        echo -e "${BCyan}💡 Use 'va --auto' to enable auto-activation${Color_Off}"
    else
        # Get environment name (parent of bin directory)
        local env_root="$(dirname "$path")"
        local env_name="$(basename "$(dirname "$env_root")")/$(basename "$env_root")"
        echo -e "${BCyan}🔧 Auto-activation: ${BGreen}enabled${Color_Off}"
        echo -e "${BCyan}📁 Environment: ${BYellow}$env_name${Color_Off}"
        echo -e "${BCyan}📂 Path: ${BYellow}$path${Color_Off}"
        echo -e "${BCyan}💡 Use 'vd' to disable auto-activation${Color_Off}"
    fi
}

# List environments from history
venv-list() {
    if [[ "$1" == "--help" ]]; then
        echo "Usage: venv-list"
        echo "List all virtual environments from history with details."
        echo "Shows path, existence status, and Python version if available."
        echo "Automatically removes deleted environments from history."
        return 0
    fi

    if [[ ! -f "$VENV_HISTORY_FILE" ]]; then
        echo -e "${BRed}❌ No virtual environment history found${Color_Off}"
        return 1
    fi

    # Filter out deleted environments and update history file
    local -a valid_entries=()
    local -a deleted_entries=()
    while IFS= read -r path; do
        [[ -z "$path" ]] && continue
        if [[ -f "$path" ]]; then
            valid_entries+=("$path")
        else
            deleted_entries+=("$path")
        fi
    done < "$VENV_HISTORY_FILE"

    # Update history file if we found deleted entries
    if (( ${#deleted_entries[@]} > 0 )); then
        : > "$VENV_HISTORY_FILE"
        for entry in "${valid_entries[@]}"; do
            printf '%s\n' "$entry"
        done >> "$VENV_HISTORY_FILE"
        echo -e "${BYellow}🧹 Cleaned up ${#deleted_entries[@]} deleted environment(s) from history${Color_Off}"
        echo
    fi

    if (( ${#valid_entries[@]} == 0 )); then
        echo -e "${BRed}❌ No valid virtual environments found in history${Color_Off}"
        return 1
    fi

    echo -e "${BCyan}🐍 Virtual Environment History:${Color_Off}"
    echo "================================"
    
    local count=1
    for path in "${valid_entries[@]}"; do
        local env_dir="$(dirname "$path")"
        local python_version=""
        
        # Try to get Python version
        local python_exec="$env_dir/bin/python"
        if [[ -f "$python_exec" ]]; then
            python_version=$("$python_exec" --version 2>/dev/null | cut -d' ' -f2)
        fi
        
        # Show full path only (skip the redundant name line)
        printf "%2d. 📁 %s\n" "$count" "$env_dir"
        [[ -n "$python_version" ]] && printf "    🐍 Python %s\n" "$python_version"
        echo
        
        ((count++))
    done
}

# Auto-detect environment in current directory
venv-detect() {
    if [[ "$1" == "--help" ]]; then
        echo "Usage: venv-detect"
        echo "Detect and activate virtual environment in current directory."
        echo "Looks for UV projects (pyproject.toml/uv.lock) and standard venv dirs."
        return 0
    fi

    # Check for UV projects first
    if [[ -f "pyproject.toml" || -f "uv.lock" ]]; then
        if command -v uv >/dev/null 2>&1; then
            local python_exec=$(uv run python -c "import sys; print(sys.executable)" 2>/dev/null)
            if [[ "$python_exec" == *".venv"* ]]; then
                local activate_path="$(dirname "$python_exec")/activate"
                if [[ -f "$activate_path" ]]; then
                    echo -e "${BCyan}🔍 Detected UV project environment${Color_Off}"
                    venv-activate "$activate_path"
                    return 0
                fi
            fi
        fi
    fi

    # Check for standard virtualenv directories
    local venv_dirs=(".venv" "venv" "env" ".env")
    for dir in "${venv_dirs[@]}"; do
        if [[ -f "$dir/bin/activate" ]]; then
            echo -e "${BCyan}🔍 Detected virtualenv: ${BYellow}$dir${Color_Off}"
            venv-activate "$dir"
            return 0
        fi
    done

    echo -e "${BCyan}ℹ️  No virtual environment detected in current directory${Color_Off}"
    return 1
}

# Auto-startup function (called on shell initialization)
_venv_auto_startup() {
    # Load saved auto-activate path if not already set
    if [[ -z "$VENV_AUTO_ACTIVATE_PATH" ]]; then
        VENV_AUTO_ACTIVATE_PATH="$(_venv_load_auto_activate)"
    fi
    
    local activate_path="${VENV_AUTO_ACTIVATE_PATH:-}"
    
    # If no auto-activate path is set, do nothing
    if [[ -z "$activate_path" ]]; then
        return
    fi

    # If activate script doesn't exist, clear the setting
    if [[ ! -f "$activate_path" ]]; then
        unset VENV_AUTO_ACTIVATE_PATH
        _venv_clear_auto_activate
        return
    fi

    # Don't re-activate if already in the same environment
    local env_root="$(dirname "$activate_path")"
    if [[ -n "$VIRTUAL_ENV" && "$VIRTUAL_ENV" == "$env_root" ]]; then
        return
    fi

    # Get a better display name: project/.venv (not .venv/bin)
    # activate_path is /path/to/project/.venv/bin/activate
    # env_root is /path/to/project/.venv/bin
    # We want /path/to/project/.venv
    local venv_dir="$(dirname "$env_root")"
    local env_display="$(basename "$(dirname "$venv_dir")")/$(basename "$venv_dir")"
    # echo -e "${BCyan}🐍 Auto-activating: ${BGreen}$env_display${Color_Off}"
    echo -e "Python env: ${BCyan}📂 ${BGreen}$activate_path${Color_Off}"
    source "$activate_path" 2>/dev/null
    export VENV_AUTO_ACTIVATE_PATH="$activate_path"

}

# Call auto-startup on shell initialization
_venv_auto_startup

# ============================================================================
# Aliases for convenience
# ============================================================================

# Primary short aliases
alias va='venv-activate'
alias vd='venv-deactivate' 
alias vc='venv-create'
alias vs='venv-select'
alias vl='venv-list'
alias vh='venv-help'

# # Legacy compatibility aliases
# alias atv='venv-activate'
# alias ua='venv-activate'
# alias atv_select='venv-select'
# alias auto_atv_disable='venv-deactivate && venv-auto off'

# UV package management aliases
alias ul='uv pip list'
alias ui='uv pip install'
alias uu='uv pip uninstall'

# Register aliases
register_alias "va" "Activate virtual environment" "UV"
register_alias "vd" "Deactivate virtual environment" "UV"
register_alias "vc" "Create new virtual environment with UV" "UV"
register_alias "vs" "Select virtual environment from history" "UV"
register_alias "vl" "List virtual environments from history" "UV"
register_alias "vh" "Show virtual environment help" "UV"
# register_alias "atv" "Activate virtual environment (legacy)" "UV"
# register_alias "ua" "Activate virtual environment (legacy)" "UV"
# register_alias "atv_select" "Select virtual environment (legacy)" "UV"
register_alias "auto_atv_disable" "Deactivate and disable auto-activation" "UV"
register_alias "ul" "List UV packages in current environment" "UV"
register_alias "ui" "Install package with UV pip" "UV"
register_alias "uu" "Uninstall package with UV pip" "UV"

# ============================================================================
# Installation and Setup
# ============================================================================

# Install UV function
install_uv() {
    echo -e "${BCyan}📥 Installing uv (Python toolchain manager)...${Color_Off}"

    if command -v uv &> /dev/null; then
        echo -e "${BGreen}✅ uv is already installed!${Color_Off}"
        uv --version
        return 0
    fi

    echo -e "${BYellow}🚀 uv not found. Installing uv...${Color_Off}"

    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        echo -e "${BRed}❌ curl is required for uv installation. Please install curl first.${Color_Off}"
        return 1
    fi

    # Install uv using official installer
    echo -e "${BCyan}📥 Downloading and installing uv...${Color_Off}"
    if curl -fsSL https://astral.sh/uv/install.sh | sh; then
        echo -e "${BGreen}✅ uv download and installation completed!${Color_Off}"
    else
        echo -e "${BRed}❌ uv installation failed!${Color_Off}"
        return 1
    fi

    # Ensure ~/.local/bin is in PATH for current session
    if [[ -d "${HOME}/.local/bin" ]] && [[ ":$PATH:" != *":${HOME}/.local/bin:"* ]]; then
        export PATH="${HOME}/.local/bin:${PATH}"
        echo -e "${BCyan}📁 Added ~/.local/bin to PATH for this session.${Color_Off}"
    fi

    if command -v uv &> /dev/null; then
        echo -e "${BGreen}🎉 uv installation completed successfully!${Color_Off}"
        echo -e "${BYellow}💡 Please restart your terminal or run 'source ~/.bashrc' to ensure PATH is updated${Color_Off}"
        uv --version
    else
        echo -e "${BYellow}⚠️  uv installation did not complete. You can install manually: curl -fsSL https://astral.sh/uv/install.sh | sh${Color_Off}"
        return 1
    fi
}

# Check uv availability on startup
check_uv() {
    if ! command -v uv &> /dev/null; then
        echo -e "${BYellow}⚠️  uv not found! Type 'install_uv' to install it automatically.${Color_Off}"
        return 1
    fi
    return 0
}

# Function to get current uv environment for prompt
get_uv_env() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "($(basename "$VIRTUAL_ENV")) "
    fi
}

# ============================================================================
# Register Functions
# ============================================================================

# Core venv functions
register_func "venv-activate" "Activate Python virtual environment" "UV"
register_func "venv-deactivate" "Deactivate current virtual environment" "UV"
register_func "venv-create" "Create new virtual environment with UV" "UV"
register_func "venv-select" "Select virtual environment from history (fzf)" "UV"

# Management functions
register_func "venv-auto" "Show auto-activation status" "UV"
register_func "venv-list" "List all virtual environments from history" "UV"
register_func "venv-detect" "Auto-detect and activate venv in current dir" "UV"
register_func "venv-help" "Show comprehensive venv management help" "UV"

# Installation and utility functions
register_func "install_uv" "Install UV Python toolchain" "Installation"
register_func "check_uv" "Check if UV is available" "UV"
register_func "get_uv_env" "Get current virtual environment name for prompt" "UV"