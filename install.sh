#!/bin/bash
# Creates symlinks from home directory to dotfiles

DOTFILES_DIR="$HOME/dotfiles"

ln -sf "$DOTFILES_DIR/.zshrc" ~/.zshrc
ln -sf "$DOTFILES_DIR/.zprofile" ~/.zprofile
ln -sf "$DOTFILES_DIR/.gitconfig" ~/.gitconfig

# iTerm2 preferences
cp "$DOTFILES_DIR/iterm2/com.googlecode.iterm2.plist" ~/Library/Preferences/com.googlecode.iterm2.plist
echo "iTerm2 prefs restored (restart iTerm2 to apply)"

echo "Dotfiles installed!"
