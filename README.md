# 🧰 dotfiles-bash

A personal and customizable **Bash-based environment setup** that provides a collection of useful shell functions, aliases, and developer tools to make your terminal experience faster and more productive.

---

## 🚀 Features

- 💡 Predefined helper functions for `git`, `docker`, `tmux`, and `python`
- ⚡ Command shortcuts for quick navigation and process management
- 🐋 Docker workflow automation (build, run, attach, kill)
- 🔍 Search tools with `fzf` integration (file finder, process killer, command history)
- 🔧 Environment and alias management helpers
- 🧠 Developer utilities: formatting, linting, proxy test, GPU monitoring, etc.

---

## 🛠️ Installation

### Quick Install (Recommended)

Install with a single command using `curl` or `wget`:

```bash
# Using curl
curl -fsSL https://raw.githubusercontent.com/anhvth/dotfiles-bash/main/setup.sh | bash

# Or using wget
wget -qO- https://raw.githubusercontent.com/anhvth/dotfiles-bash/main/setup.sh | bash
```

### Manual Installation

Clone the repository and run the installer:

```bash
git clone https://github.com/anhvth/dotfiles-bash ~/dotfiles-bash
cd ~/dotfiles-bash
./install.sh
```

---

## 🎯 Quick Start

After installation, reload your shell:

```bash
source ~/.bashrc
```

Then explore the available features:

```bash
show-help        # Interactive help browser (FZF required)
show_functions   # List all available functions
show_aliases     # List all available aliases
```

---

## 📚 Documentation

For detailed information about the architecture, patterns, and development guidelines, see the [Copilot Instructions](.github/copilot-instructions.md).

---

## 🤝 Contributing

Feel free to fork, customize, and submit PRs! This is a personal dotfiles repo, but contributions are welcome.

---

## 📄 License

This project is open source and available under the MIT License.
