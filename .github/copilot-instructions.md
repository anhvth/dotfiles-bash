# Dotfiles-Bash Copilot Instructions

## Architecture Overview

This is a **modular Bash configuration system** with automatic documentation. The architecture follows a strict loading order:

1. **`bashrc.sh`** - Main entry point (sourced from `~/.bashrc`)
2. **`helpers.sh`** - MUST load first (provides `register_func()` and `register_alias()`)
3. **`alias.sh`** - Command shortcuts
4. **`conda_utils.sh` OR `uv_utils.sh`** - Package manager utilities (controlled by `PACKAGE_MANAGER` variable)
5. **`functions.sh`** - Utility functions

```bash
# Loading order in bashrc.sh:
source helpers.sh      # ← Registration system
source alias.sh        # ← Uses register_alias()
source {conda|uv}_utils.sh
source functions.sh    # ← Uses register_func()
```

## Auto-Documentation System

**Critical Pattern**: Every alias and function MUST be registered for auto-discovery:

```bash
# After defining an alias:
alias ga='git add'
register_alias "ga" "Git add" "Git"

# After defining a function:
extract() { ... }
register_func "extract" "Extract various archive formats" "Archive"
```

### Registration Categories

- **Aliases**: Navigation, Listing, File Operations, Git, Docker, Python, FZF, Network, Utilities
- **Functions**: Archive, Directory, System, FZF, Search, Docker, Tmux, Python, Network, Config, Utilities, Help, Installation

## Key Files

### `helpers.sh` - Registration Infrastructure
- Declares global associative arrays: `FUNC_REGISTRY`, `FUNC_CATEGORY`, `ALIAS_REGISTRY`, `ALIAS_CATEGORY`
- Provides `register_func()` and `register_alias()` - **never call these before sourcing helpers.sh**
- Implements help system: `show-help`, `show_functions`, `show_aliases`, `fzf_functions`, `fzf_aliases`
- Uses FZF for interactive browsing with live preview

### `bashrc.sh` - Main Configuration
- Sets `PACKAGE_MANAGER="conda"` or `"uv"` to control which package manager loads
- Defines color variables (`BGreen`, `BYellow`, etc.) used throughout
- Configures keybindings: `Ctrl+G` (git commit), `Ctrl+S` (sudo), `Ctrl+R` (fzf history)
- Must source `helpers.sh` **before** any file that registers aliases/functions

### `functions.sh` - Utility Functions
- Conditional FZF functions only load `if command -v fzf &> /dev/null`
- Docker functions use `$DOCKER_ACTIVE_CONTAINER` and `$DOCKER_ACTIVE_IMAGE` env vars
- All functions end with `register_func "name" "description" "Category"`

### `alias.sh` - Command Shortcuts
- Each alias block ends with registration calls
- Uses `register_alias "name" "description" "Category"`
- Check for `code-insiders` at top, alias `code` if available

## Critical Workflows

### Adding New Functions/Aliases

```bash
# 1. Define the function/alias in appropriate file
# 2. IMMEDIATELY register it after definition (same file)
my_func() { echo "hello"; }
register_func "my_func" "Say hello" "Utilities"

# 3. No need to update help system - it's automatic!
```

### Package Manager Switching

Edit `bashrc.sh`:
```bash
PACKAGE_MANAGER="conda"  # or "uv"
```

This controls which utility file loads (`conda_utils.sh` vs `uv_utils.sh`).

### Installation

```bash
# install.sh adds ONE line to ~/.bashrc:
source ~/dotfiles-bash/bashrc.sh

# No other setup needed - everything loads from bashrc.sh
```

## Common Patterns

### FZF Integration
- Always check `if command -v fzf &> /dev/null` before defining FZF functions
- Use `--height=60%` for consistent UI
- Add `--preview` for enhanced UX

### Color Usage
```bash
echo -e "${BGreen}Success${Color_Off}"
echo -e "${BYellow}Warning${Color_Off}"
echo -e "${BRed}Error${Color_Off}"
```

### Keybindings
```bash
bind -x '"\C-g": "function_name"'  # Execute function
bind '"\C-v": "fc\n"'              # Execute string
```

## Testing Changes

```bash
# Quick reload without restart:
source ~/dotfiles-bash/bashrc.sh

# Or use built-in:
bash_reload

# Verify registrations:
show_functions  # List all registered functions
show_aliases    # List all registered aliases
show-help       # Interactive FZF browser
```

## Anti-Patterns to Avoid

❌ **DON'T** define functions/aliases without registering them
❌ **DON'T** call `register_func()`/`register_alias()` before sourcing `helpers.sh`
❌ **DON'T** duplicate function definitions across files (check for duplicates first)
❌ **DON'T** use hardcoded paths - use `$HOME` or `~/` for portability
❌ **DON'T** register in one file but define in another

✅ **DO** register immediately after definition in the same file
✅ **DO** check command availability with `command -v`
✅ **DO** use consistent category names for related items
✅ **DO** maintain loading order: helpers → alias → package_utils → functions

## Debugging

```bash
# Check if function is registered:
declare -p FUNC_REGISTRY | grep "function_name"

# Check if alias is registered:
declare -p ALIAS_REGISTRY | grep "alias_name"

# View all categories:
for cat in "${FUNC_CATEGORY[@]}"; do echo "$cat"; done | sort -u
```

## External Dependencies (Optional)

- **fzf**: Enhanced fuzzy finding (auto-install: `fzf_install`)
- **conda/miniconda**: Python environment management (auto-install: `conda_install`)
- **uv**: Alternative Python toolchain (auto-install: `install_uv`)

All tools check availability and offer installation if missing.
