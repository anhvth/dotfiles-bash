set -e

# Define paths
IPYTHON_DIR="${HOME}/.ipython"
CONFIG_DIR="${IPYTHON_DIR}/profile_default"
CONFIG_FILE="${CONFIG_DIR}/ipython_config.py"

# Ensure IPython is installed
if ! command -v ipython &>/dev/null; then
    echo "❌ IPython not found. Installing via pip..."
    pip install ipython --quiet
fi

# Generate default configuration if missing
if [ ! -f "$CONFIG_FILE" ]; then
    echo "🛠️ Generating default IPython configuration..."
    ipython profile create >/dev/null 2>&1
fi

# Backup old config
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
fi

# Write new config
cat > "$CONFIG_FILE" <<'EOF'
# type: ignore
# Configuration file for ipython.
c = get_config()  # noqa: F821

# Set up auto reload for modules
c.InteractiveShellApp.extensions = ['autoreload']
c.InteractiveShellApp.exec_lines = ['%autoreload 2', 'print("\\033[33mAutoreload is enabled.\\033[0m")']

# Display settings
c.TerminalInteractiveShell.confirm_exit = False
c.TerminalInteractiveShell.true_color = True

# History settings
c.HistoryManager.enabled = True
EOF

echo "✅ IPython configuration updated at: $CONFIG_FILE"
echo "💡 Next time you start IPython, autoreload will be enabled automatically."