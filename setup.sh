#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/anhvth/dotfiles-bash.git"
INSTALL_DIR="${HOME}/dotfiles-bash"
BASHRC="${HOME}/.bashrc"

# Helper functions
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if git is installed
check_git() {
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed. Please install git first."
        echo "  Ubuntu/Debian: sudo apt-get install git"
        echo "  CentOS/RHEL:   sudo yum install git"
        echo "  macOS:         brew install git"
        exit 1
    fi
}

# Clone or update repository
install_repo() {
    if [ -d "$INSTALL_DIR" ]; then
        print_info "Repository already exists at $INSTALL_DIR"
        print_info "Updating repository..."
        cd "$INSTALL_DIR"
        
        # Stash any local changes
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            print_warning "Local changes detected, stashing them..."
            git stash push -m "Auto-stash before update $(date +%Y-%m-%d_%H:%M:%S)"
        fi
        
        git pull origin main || {
            print_error "Failed to update repository"
            exit 1
        }
        print_success "Repository updated successfully"
    else
        print_info "Cloning repository to $INSTALL_DIR..."
        git clone "$REPO_URL" "$INSTALL_DIR" || {
            print_error "Failed to clone repository"
            exit 1
        }
        print_success "Repository cloned successfully"
    fi
}

# Add source line to .bashrc
configure_bashrc() {
    local source_line="source ~/dotfiles-bash/bashrc.sh"
    
    print_info "Configuring .bashrc..."
    
    # Create .bashrc if it doesn't exist
    if [ ! -f "$BASHRC" ]; then
        touch "$BASHRC"
        print_warning ".bashrc did not exist, created new file"
    fi
    
    # Check if already configured
    if grep -Fxq "$source_line" "$BASHRC" 2>/dev/null; then
        print_success ".bashrc already configured"
    else
        # Add source line
        echo "" >> "$BASHRC"
        echo "# Dotfiles-bash configuration" >> "$BASHRC"
        echo "$source_line" >> "$BASHRC"
        print_success "Added source line to .bashrc"
    fi
}

# Setup IPython configuration
setup_ipython() {
    print_info "Setting up IPython configuration..."
    
    if [ -f "$INSTALL_DIR/setup_ipython.sh" ]; then
        cd "$INSTALL_DIR"
        bash setup_ipython.sh || {
            print_warning "IPython setup failed (this is optional)"
            return 0
        }
    else
        print_warning "IPython setup script not found (skipping)"
    fi
}

# Main installation flow
main() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║  Dotfiles-Bash Installation Script    ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    
    check_git
    install_repo
    configure_bashrc
    setup_ipython
    
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║  Installation Complete! 🎉             ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    print_success "Dotfiles-bash has been installed successfully!"
    echo ""
    print_info "To start using it, either:"
    echo "  1. Restart your terminal"
    echo "  2. Run: ${BLUE}source ~/.bashrc${NC}"
    echo ""
    print_info "Available commands after activation:"
    echo "  • ${BLUE}show-help${NC}       - Interactive help browser"
    echo "  • ${BLUE}show_functions${NC}  - List all available functions"
    echo "  • ${BLUE}show_aliases${NC}    - List all available aliases"
    echo ""
}

# Run main installation
main
