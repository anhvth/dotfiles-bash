#!/bin/bash
# ============================================================================
# 🚀 UV Utilities and Functions  
# ============================================================================

# UV/Python shortcuts
alias ua='uv activate'
alias ul='uv list'
alias ue='uv env list'

register_alias "ua" "Activate UV virtual environment" "UV"
register_alias "ul" "List UV packages" "UV"
register_alias "ue" "List UV environments" "UV"

# Auto-activate virtual environment on startup if it exists
_venv_auto_startup() {
    if [[ -f ".venv/bin/activate" ]]; then
        source .venv/bin/activate
        echo -e "${BGreen}✅ Auto-activated virtual environment: .venv${Color_Off}"
    elif [[ -f "venv/bin/activate" ]]; then
        source venv/bin/activate
        echo -e "${BGreen}✅ Auto-activated virtual environment: venv${Color_Off}"
    fi
}

# Call auto-startup on shell initialization
_venv_auto_startup

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

# Function to get current uv environment
get_uv_env() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "($(basename "$VIRTUAL_ENV")) "
    fi
}

# Register UV functions
register_func "install_uv" "Install UV Python toolchain" "Installation"
register_func "check_uv" "Check if UV is available" "UV"
register_func "get_uv_env" "Get current virtual environment name" "UV"