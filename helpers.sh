#!/bin/bash
# ============================================================================
# 📖 Auto-Documentation Helper System
# ============================================================================
# This file provides an automatic documentation system for aliases and functions
# using associative arrays to store metadata

# Initialize documentation arrays (bash 3.2 compatible)
FUNC_NAMES=()           # Array of function names
FUNC_DESCRIPTIONS=()    # Corresponding descriptions
FUNC_CATEGORIES=()      # Corresponding categories
ALIAS_NAMES=()          # Array of alias names  
ALIAS_DESCRIPTIONS=()   # Corresponding descriptions
ALIAS_CATEGORIES=()     # Corresponding categories

# ============================================================================
# 🔧 Registration Functions
# ============================================================================

# Register a function with description and category
# Usage: register_func "function_name" "Description of function" "Category"
register_func() {
    local name="$1"
    local desc="$2"
    local category="${3:-Utilities}"
    
    # Add to arrays
    FUNC_NAMES+=("$name")
    FUNC_DESCRIPTIONS+=("$desc")
    FUNC_CATEGORIES+=("$category")
}

# Register an alias with description and category
# Usage: register_alias "alias_name" "Description of alias" "Category"
register_alias() {
    local name="$1"
    local desc="$2"
    local category="${3:-General}"
    
    # Add to arrays
    ALIAS_NAMES+=("$name")
    ALIAS_DESCRIPTIONS+=("$desc")
    ALIAS_CATEGORIES+=("$category")
}

# ============================================================================
# 📋 Help Display Functions
# ============================================================================

# Show all registered functions
show_functions() {
    if [ ${#FUNC_NAMES[@]} -eq 0 ]; then
        echo -e "${BYellow}No functions registered yet.${Color_Off}"
        return
    fi

    # Get unique categories
    local categories=($(printf '%s\n' "${FUNC_CATEGORIES[@]}" | sort -u))
    
    for category in "${categories[@]}"; do
        echo -e "\n${BBlue}━━━ $category ━━━${Color_Off}"
        
        # Create sorted indices for this category
        local indices=()
        local max_idx=$(expr ${#FUNC_NAMES[@]} - 1)
        for i in $(seq 0 $max_idx); do
            if [[ "${FUNC_CATEGORIES[$i]}" == "$category" ]]; then
                indices+=($i)
            fi
        done
        
        # Sort by function name within category
        local sorted_indices=($(for idx in "${indices[@]}"; do echo "${FUNC_NAMES[$idx]} $idx"; done | sort | cut -d' ' -f2))
        
        for idx in "${sorted_indices[@]}"; do
            printf "  ${BGreen}%-20s${Color_Off} %s\n" "${FUNC_NAMES[$idx]}" "${FUNC_DESCRIPTIONS[$idx]}"
        done
    done
    echo ""
}

# Show all registered aliases
show_aliases() {
    if [ ${#ALIAS_NAMES[@]} -eq 0 ]; then
        echo -e "${BYellow}No aliases registered yet.${Color_Off}"
        return
    fi

    # Get unique categories
    local categories=($(printf '%s\n' "${ALIAS_CATEGORIES[@]}" | sort -u))
    
    for category in "${categories[@]}"; do
        echo -e "\n${BBlue}━━━ $category ━━━${Color_Off}"
        
        # Create sorted indices for this category
        local indices=()
        local max_idx=$(expr ${#ALIAS_NAMES[@]} - 1)
        for i in $(seq 0 $max_idx); do
            if [[ "${ALIAS_CATEGORIES[$i]}" == "$category" ]]; then
                indices+=($i)
            fi
        done
        
        # Sort by alias name within category
        local sorted_indices=($(for idx in "${indices[@]}"; do echo "${ALIAS_NAMES[$idx]} $idx"; done | sort | cut -d' ' -f2))
        
        for idx in "${sorted_indices[@]}"; do
            printf "  ${BGreen}%-20s${Color_Off} %s\n" "${ALIAS_NAMES[$idx]}" "${ALIAS_DESCRIPTIONS[$idx]}"
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
    
    local max_idx=$(expr ${#FUNC_NAMES[@]} - 1)
    for i in $(seq 0 $max_idx); do
        local func_name="${FUNC_NAMES[$i]}"
        local category="${FUNC_CATEGORIES[$i]}"
        local desc="${FUNC_DESCRIPTIONS[$i]}"
        local line=$(printf "%-20s [%s] %s" "$func_name" "$category" "$desc")
        selection_list+="$line"$'\n'
    done

    local selected=$(echo "$selection_list" | sort | fzf \
        --height=60% \
        --prompt="Select function: " \
        --preview='echo "Function: {1}"; echo ""; type {1} 2>/dev/null || echo "Function definition not found"' \
        --preview-window=right:60%:wrap)
    
    if [ -n "$selected" ]; then
        local func_name=$(echo "$selected" | awk '{print $1}')
        
        # Find the description and category for this function
        local func_desc=""
        local func_cat=""
        local max_idx=$(expr ${#FUNC_NAMES[@]} - 1)
        for i in $(seq 0 $max_idx); do
            if [[ "${FUNC_NAMES[$i]}" == "$func_name" ]]; then
                func_desc="${FUNC_DESCRIPTIONS[$i]}"
                func_cat="${FUNC_CATEGORIES[$i]}"
                break
            fi
        done
        
        echo -e "\n${BCyan}Function:${Color_Off} $func_name"
        echo -e "${BCyan}Description:${Color_Off} $func_desc"
        echo -e "${BCyan}Category:${Color_Off} $func_cat"
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
    
    local max_idx=$(expr ${#ALIAS_NAMES[@]} - 1)
    for i in $(seq 0 $max_idx); do
        local alias_name="${ALIAS_NAMES[$i]}"
        local category="${ALIAS_CATEGORIES[$i]}"
        local desc="${ALIAS_DESCRIPTIONS[$i]}"
        local line=$(printf "%-20s [%s] %s" "$alias_name" "$category" "$desc")
        selection_list+="$line"$'\n'
    done

    local selected=$(echo "$selection_list" | sort | fzf \
        --height=60% \
        --prompt="Select alias: " \
        --preview='echo "Alias: {1}"; echo ""; alias {1} 2>/dev/null || echo "Alias definition not found"' \
        --preview-window=right:60%:wrap)
    
    if [ -n "$selected" ]; then
        local alias_name=$(echo "$selected" | awk '{print $1}')
        
        # Find the description and category for this alias
        local alias_desc=""
        local alias_cat=""
        local max_idx=$(expr ${#ALIAS_NAMES[@]} - 1)
        for i in $(seq 0 $max_idx); do
            if [[ "${ALIAS_NAMES[$i]}" == "$alias_name" ]]; then
                alias_desc="${ALIAS_DESCRIPTIONS[$i]}"
                alias_cat="${ALIAS_CATEGORIES[$i]}"
                break
            fi
        done
        
        echo -e "\n${BCyan}Alias:${Color_Off} $alias_name"
        echo -e "${BCyan}Description:${Color_Off} $alias_desc"
        echo -e "${BCyan}Category:${Color_Off} $alias_cat"
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
