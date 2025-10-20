#!/bin/bash
# ============================================================================
# 📖 Auto-Documentation Helper System
# ============================================================================
# This file provides an automatic documentation system for aliases and functions
# using associative arrays to store metadata

# Initialize documentation arrays
declare -gA FUNC_REGISTRY     # function_name => description
declare -gA FUNC_CATEGORY     # function_name => category
declare -gA ALIAS_REGISTRY    # alias_name => description  
declare -gA ALIAS_CATEGORY    # alias_name => category

# ============================================================================
# 🔧 Registration Functions
# ============================================================================

# Register a function with description and category
# Usage: register_func "function_name" "Description of function" "Category"
register_func() {
    local name="$1"
    local desc="$2"
    local category="${3:-Utilities}"
    FUNC_REGISTRY["$name"]="$desc"
    FUNC_CATEGORY["$name"]="$category"
}

# Register an alias with description and category
# Usage: register_alias "alias_name" "Description of alias" "Category"
register_alias() {
    local name="$1"
    local desc="$2"
    local category="${3:-General}"
    ALIAS_REGISTRY["$name"]="$desc"
    ALIAS_CATEGORY["$name"]="$category"
}

# ============================================================================
# 📋 Help Display Functions
# ============================================================================

# Show all registered functions
show_functions() {
    if [ ${#FUNC_REGISTRY[@]} -eq 0 ]; then
        echo -e "${BYellow}No functions registered yet.${Color_Off}"
        return
    fi

    # Get unique categories
    local categories=($(for cat in "${FUNC_CATEGORY[@]}"; do echo "$cat"; done | sort -u))
    
    for category in "${categories[@]}"; do
        echo -e "\n${BBlue}━━━ $category ━━━${Color_Off}"
        for func_name in $(echo "${!FUNC_REGISTRY[@]}" | tr ' ' '\n' | sort); do
            if [[ "${FUNC_CATEGORY[$func_name]}" == "$category" ]]; then
                printf "  ${BGreen}%-20s${Color_Off} %s\n" "$func_name" "${FUNC_REGISTRY[$func_name]}"
            fi
        done
    done
    echo ""
}

# Show all registered aliases
show_aliases() {
    if [ ${#ALIAS_REGISTRY[@]} -eq 0 ]; then
        echo -e "${BYellow}No aliases registered yet.${Color_Off}"
        return
    fi

    # Get unique categories
    local categories=($(for cat in "${ALIAS_CATEGORY[@]}"; do echo "$cat"; done | sort -u))
    
    for category in "${categories[@]}"; do
        echo -e "\n${BBlue}━━━ $category ━━━${Color_Off}"
        for alias_name in $(echo "${!ALIAS_REGISTRY[@]}" | tr ' ' '\n' | sort); do
            if [[ "${ALIAS_CATEGORY[$alias_name]}" == "$category" ]]; then
                printf "  ${BGreen}%-20s${Color_Off} %s\n" "$alias_name" "${ALIAS_REGISTRY[$alias_name]}"
            fi
        done
    done
    echo ""
}

# FZF-based interactive function browser
fzf_functions() {
    if ! command -v fzf &> /dev/null; then
        echo -e "${BYellow}fzf not found. Showing list instead:${Color_Off}"
        show_functions
        return
    fi

    # Build selection list with categories
    local selection_list=""
    local func_map=()
    
    for func_name in $(echo "${!FUNC_REGISTRY[@]}" | tr ' ' '\n' | sort); do
        local category="${FUNC_CATEGORY[$func_name]}"
        local desc="${FUNC_REGISTRY[$func_name]}"
        local line=$(printf "%-20s [%s] %s" "$func_name" "$category" "$desc")
        selection_list+="$line"$'\n'
        func_map+=("$func_name")
    done

    local selected=$(echo "$selection_list" | fzf \
        --height=60% \
        --prompt="Select function: " \
        --preview='echo "Function: {1}"; echo ""; type {1} 2>/dev/null || echo "Function definition not found"' \
        --preview-window=right:60%:wrap)
    
    if [ -n "$selected" ]; then
        local func_name=$(echo "$selected" | awk '{print $1}')
        echo -e "\n${BCyan}Function:${Color_Off} $func_name"
        echo -e "${BCyan}Description:${Color_Off} ${FUNC_REGISTRY[$func_name]}"
        echo -e "${BCyan}Category:${Color_Off} ${FUNC_CATEGORY[$func_name]}"
        echo -e "\n${BCyan}Definition:${Color_Off}"
        type "$func_name" 2>/dev/null || echo "Function definition not available"
    fi
}

# FZF-based interactive alias browser
fzf_aliases() {
    if ! command -v fzf &> /dev/null; then
        echo -e "${BYellow}fzf not found. Showing list instead:${Color_Off}"
        show_aliases
        return
    fi

    # Build selection list with categories
    local selection_list=""
    
    for alias_name in $(echo "${!ALIAS_REGISTRY[@]}" | tr ' ' '\n' | sort); do
        local category="${ALIAS_CATEGORY[$alias_name]}"
        local desc="${ALIAS_REGISTRY[$alias_name]}"
        local line=$(printf "%-20s [%s] %s" "$alias_name" "$category" "$desc")
        selection_list+="$line"$'\n'
    done

    local selected=$(echo "$selection_list" | fzf \
        --height=60% \
        --prompt="Select alias: " \
        --preview='echo "Alias: {1}"; echo ""; alias {1} 2>/dev/null || echo "Alias definition not found"' \
        --preview-window=right:60%:wrap)
    
    if [ -n "$selected" ]; then
        local alias_name=$(echo "$selected" | awk '{print $1}')
        echo -e "\n${BCyan}Alias:${Color_Off} $alias_name"
        echo -e "${BCyan}Description:${Color_Off} ${ALIAS_REGISTRY[$alias_name]}"
        echo -e "${BCyan}Category:${Color_Off} ${ALIAS_CATEGORY[$alias_name]}"
        echo -e "\n${BCyan}Definition:${Color_Off}"
        alias "$alias_name" 2>/dev/null || echo "Alias definition not available"
    fi
}

# Main help function with FZF integration
show-help() {
    if ! command -v fzf &> /dev/null; then
        echo -e "${BGreen}╔══════════════════════════════════════════════════════════════╗${Color_Off}"
        echo -e "${BGreen}║                    📖 Dotfiles Help System                   ║${Color_Off}"
        echo -e "${BGreen}╚══════════════════════════════════════════════════════════════╝${Color_Off}"
        echo -e "\n${BYellow}Available Help Commands:${Color_Off}"
        echo -e "  ${BGreen}show_functions${Color_Off}     - List all available functions"
        echo -e "  ${BGreen}show_aliases${Color_Off}       - List all available aliases"
        echo -e "  ${BGreen}show_keybindings${Color_Off}   - Show keyboard shortcuts"
        echo -e "  ${BGreen}show_system_info${Color_Off}   - Display system information"
        echo -e "\n${BYellow}Install fzf for interactive help:${Color_Off} ${BCyan}fzf_install${Color_Off}"
        return
    fi
    
    local options="Functions\nAliases\nKeybindings\nSystem Info\nInstallation"
    local choice=$(echo -e "$options" | fzf --height=40% --prompt="📖 Select help topic: ")
    
    case "$choice" in
        "Functions")
            fzf_functions
            ;;
        "Aliases")
            fzf_aliases
            ;;
        "Keybindings")
            show_keybindings
            ;;
        "System Info")
            show_system_info
            ;;
        "Installation")
            show_installation_help
            ;;
    esac
}

# Show keybindings
show_keybindings() {
    echo -e "\n${BBlue}━━━ Keyboard Shortcuts ━━━${Color_Off}"
    echo -e "  ${BGreen}Ctrl+G${Color_Off}             Git commit preparation"
    echo -e "  ${BGreen}Ctrl+V${Color_Off}             Edit and rerun command"
    echo -e "  ${BGreen}Ctrl+S${Color_Off}             Add sudo to command"
    echo -e "  ${BGreen}Ctrl+O${Color_Off}             Add code-debug to command"
    echo -e "  ${BGreen}Ctrl+N${Color_Off}             List files"
    echo -e "  ${BGreen}Ctrl+R${Color_Off}             Search history (fzf)"
    echo -e "  ${BGreen}Ctrl+H${Color_Off}             Show this help"
    if command -v fzf &> /dev/null; then
        echo -e "  ${BGreen}Ctrl+F${Color_Off}             Fuzzy file search"
        echo -e "  ${BGreen}Ctrl+B${Color_Off}             Fuzzy directory change"
    fi
    echo ""
}

# Show installation help
show_installation_help() {
    echo -e "\n${BBlue}━━━ Installation Tools ━━━${Color_Off}"
    echo -e "  ${BGreen}fzf_install${Color_Off}        Install fzf fuzzy finder"
    
    if [[ "$PACKAGE_MANAGER" == "conda" ]]; then
        echo -e "  ${BGreen}conda_install${Color_Off}      Install Miniconda"
    elif [[ "$PACKAGE_MANAGER" == "uv" ]]; then
        echo -e "  ${BGreen}install_uv${Color_Off}         Install uv Python toolchain"
    fi
    echo ""
}

# Register the helper functions themselves
register_func "show-help" "Interactive help system with FZF" "Help"
register_func "show_functions" "List all available functions by category" "Help"
register_func "show_aliases" "List all available aliases by category" "Help"
register_func "show_keybindings" "Display keyboard shortcuts" "Help"
register_func "show_system_info" "Display system information" "System"
register_func "fzf_functions" "Browse functions with FZF" "Help"
register_func "fzf_aliases" "Browse aliases with FZF" "Help"
