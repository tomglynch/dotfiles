#!/bin/bash
# Creates symlinks from home directory to dotfiles

DOTFILES_DIR="$HOME/dotfiles"

ln -sf "$DOTFILES_DIR/.zshrc" ~/.zshrc
ln -sf "$DOTFILES_DIR/.zprofile" ~/.zprofile
ln -sf "$DOTFILES_DIR/.gitconfig" ~/.gitconfig

# iTerm2 preferences - point to dotfiles folder so iTerm2 reads/writes there directly
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$DOTFILES_DIR/iterm2"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
echo "iTerm2 prefs configured (restart iTerm2 to apply)"

echo "Dotfiles installed!"
