#!/bin/bash
# Creates symlinks from home directory to dotfiles

DOTFILES_DIR="$HOME/dotfiles"

ln -sf "$DOTFILES_DIR/.zshrc" ~/.zshrc
ln -sf "$DOTFILES_DIR/.zprofile" ~/.zprofile
ln -sf "$DOTFILES_DIR/.gitconfig" ~/.gitconfig

echo "Dotfiles installed!"
