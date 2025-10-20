
if ! grep -q "source ~/dotfiles-bash/bashrc.sh" ~/.bashrc; then
    echo "source ~/dotfiles-bash/bashrc.sh" >> ~/.bashrc
fi

sh setup_ipython.sh