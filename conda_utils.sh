#!/bin/bash
# ============================================================================
# 🐍 Conda Utilities and Functions
# ============================================================================

# Python/Conda shortcuts
alias ca='conda activate'
alias cl='conda list'
alias ce='conda env list'

register_alias "ca" "Activate conda environment" "Conda"
register_alias "cl" "List conda packages" "Conda"
register_alias "ce" "List conda environments" "Conda"

# Check and install conda if not available
conda_install() {
    if command -v conda &> /dev/null; then
        echo -e "${BGreen}✅ Conda is already installed!${Color_Off}"
        conda --version
        return 0
    fi
    
    echo -e "${BYellow}🐍 Conda not found. Installing Miniconda...${Color_Off}"
    
    # Create temporary directory for download
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR" || exit 1
    
    echo -e "${BCyan}📥 Downloading Miniconda3-latest-Linux-x86_64.sh...${Color_Off}"
    if wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh; then
        echo -e "${BGreen}✅ Download completed!${Color_Off}"
        
        echo -e "${BCyan}🔧 Installing Miniconda...${Color_Off}"
        echo -e "${BYellow}⚠️  Please follow the installation prompts${Color_Off}"
        
        if bash Miniconda3-latest-Linux-x86_64.sh; then
            echo -e "${BGreen}🎉 Miniconda installation completed!${Color_Off}"
            echo -e "${BYellow}💡 Please restart your terminal or run 'source ~/.bashrc' to use conda${Color_Off}"
        else
            echo -e "${BRed}❌ Miniconda installation failed!${Color_Off}"
            cd - > /dev/null
            rm -rf "$TEMP_DIR"
            return 1
        fi
    else
        echo -e "${BRed}❌ Download failed! Please check your internet connection.${Color_Off}"
        cd - > /dev/null
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # Clean up
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    
    echo -e "${BGreen}🧹 Cleanup completed!${Color_Off}"
}

# Check conda availability on startup
check_conda() {
    if ! command -v conda &> /dev/null; then
        echo -e "${BYellow}⚠️  Conda not found! Type 'conda_install' to install it automatically.${Color_Off}"
        return 1
    fi
    return 0
}

# Function to get current conda environment (only if conda PS1 isn't already set)
get_conda_env() {
    # Don't show conda env if conda is already handling the prompt
    if [[ -n "$CONDA_DEFAULT_ENV" && -z "$CONDA_PROMPT_MODIFIER" ]]; then
        echo "($CONDA_DEFAULT_ENV) "
    fi
}

# Register conda functions
register_func "conda_install" "Install Miniconda" "Installation"
register_func "check_conda" "Check if conda is available" "Conda"
register_func "get_conda_env" "Get current conda environment name" "Conda"