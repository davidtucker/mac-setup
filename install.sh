#!/bin/zsh

###############################
# Mac Initial Setup Script
# David Tucker, davidtucker.net
###############################
# I pulled several settings from:
# https://gist.github.com/bradp/bea76b16d3325f5c47d4
# https://github.com/pathikrit/mac-setup-script
###############################

# Output formatting
BLUE="\033[0;34m"
RED="\033[0;31m"
NO_COLOR="\033[0m"
DIVIDER=$'\n\n'"----------------------------------------------------------"
echo "$DIVIDER"
echo "Mac install script"
echo -e "Installing ${RED}Homebrew${NO_COLOR} and applications....."

############################
# Setup Homebrew and Apps
############################

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
if [[ $(uname -p) == 'arm' ]]; then
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

brew doctor
brew install cask
brew cask doctor

############################
# Utilities
############################

# Utilities
brew install wget
brew install tree

# Rosetta
if [[ $(uname -p) == 'arm' ]]; then
	softwareupdate --install-rosetta  --agree-to-license
fi

############################
# Other Applications
############################

# Doesn't currently work with Apple Silicon
# brew install --cask adobe-creative-cloud

brew install --cask 1password
brew install --cask bartender
brew install --cask docker
brew install --cask firefox
brew install --cask google-chrome
brew install --cask hammerspoon
brew install --cask iterm2
brew install --cask macdown
brew install --cask microsoft-office
brew install --cask postman
brew install --cask slack
brew install --cask spotify
brew install --cask sublime-text
brew install --cask visual-studio-code
brew install --cask zoom

############################
# Dev Environments - Java
############################

echo "$DIVIDER"
echo -e "Installing ${BLUE}Development Environments${NO_COLOR}"
echo -e "Configuring ${BLUE}Java${NO_COLOR}...."

# Java Environment and IntelliJ Community Edition
brew install openjdk
export CPPFLAGS="-I/opt/homebrew/opt/openjdk/include"
brew install --cask intellij-idea-ce 

############################
# Dev Environments - Node
############################

echo -e "Configuring ${BLUE}Node${NO_COLOR}...."

# Install nvm
brew update 
brew install nvm 
mkdir ~/.nvm 

echo '' >> ~/.zshrc
echo '# NVM Configuration' >> ~/.zshrc
echo 'export NVM_DIR=~/.nvm' >> ~/.zshrc
echo 'source $(brew --prefix nvm)/nvm.sh' >> ~/.zshrc

# Global Node Modules
npm install -g yarn

############################
# Dev Environments - Python
############################

echo -e "Configuring ${BLUE}Python${NO_COLOR}...."

# Install Apple-silicon supported version of Python
brew install python@3.9

# Cleanup
brew cleanup

echo "App installation complete..."
echo "$DIVIDER"
echo -e "Setting ${BLUE}MacOS Customizations${NO_COLOR}"

############################
# Mac Configuration
############################

# Dock Configuration
defaults write com.apple.dock orientation left
defaults write com.apple.dock autohide -bool true
killall Dock

# Expand the Save Panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show status and path bar in Finder 
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true

# Show POSIX path as window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Show library folder
chflags nohidden ~/Library

# Disable specific auto corrections
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Set default to save to disk and not iCloud
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Disabling the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Disable the quarantine dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Use column view in all Finder windows by default
defaults write com.apple.finder FXPreferredViewStyle Clmv

# Set new Screenshots location
mkdir ~/Screenshots
defaults write com.apple.screencapture location -string "$HOME/Screenshots"

killall Finder

echo "Mac customizations complete..."

############################
# Setup ZSH and Prompt
############################

echo "$DIVIDER"
echo -e "Configuring ${BLUE}Shell${NO_COLOR}"

# Install OhMyZsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install PowerLevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Install Fonts for Powerlevel10k
wget -P ~/Library/Fonts https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
wget -P ~/Library/Fonts https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
wget -P ~/Library/Fonts https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
wget -P ~/Library/Fonts https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf

# Set the ZSH_THEME
sed -i.bak 's~\(ZSH_THEME="\)[^"]*\(".*\)~\1powerlevel10k\/powerlevel10k\2~' ~/.zshrc

# Have .zshrc load PowerLevel10K config if it exists
echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> ~/.zshrc

############################
# Key Setup
############################

echo "$DIVIDER"
echo -e "Configuring ${BLUE}Key${NO_COLOR}"

ssh-keygen -t ed25519 -C "david@davidtucker.net"
eval "$(ssh-agent -s)"
touch ~/.ssh/config
echo "Host *" >> ~/.ssh/config
echo "  AddKeysToAgent yes" >> ~/.ssh/config
echo "  UseKeychain yes" >> ~/.ssh/config
echo "  IdentityFile ~/.ssh/id_ed25519" >> ~/.ssh/config
echo " " >> ~/.ssh/config
pbcopy < ~/.ssh/id_ed25519.pub 
echo ""
echo "Public key is copied to the clipboard and is ready to paste in Github...."
echo "${RED}You must paste in the key to Github, as upcoming steps require the pull of private repositories...${NO_COLOR}"
read "?Press any key to continue after setting up the key in GitHub ..."

############################
# Command Line Tools
############################

echo "$DIVIDER"
echo -e "Installing ${BLUE}Command Line Tools${NO_COLOR}"

# Install AWS CLIv2
wget -O ~/Downloads/AWSCLIV2.pkg https://awscli.amazonaws.com/AWSCLIV2.pkg 
sudo installer -pkg ~/Downloads/AWSCLIV2.pkg -target /

# Install Session Manager for AWS CLI
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/session-manager-plugin.pkg" -o "session-manager-plugin.pkg"
sudo installer -pkg session-manager-plugin.pkg -target /
mkdir -p /usr/local/bin
sudo ln -s /usr/local/sessionmanagerplugin/bin/session-manager-plugin /usr/local/bin/session-manager-plugin

# Install AWS SAM
brew tap aws/tap
brew install aws-sam-cli

# Install Azure CLI
brew install azure-cli

# Install Github CLI
brew install gh

# Install GCP Cloud SDK
brew install --cask google-cloud-sdk

############################
# Dotfiles
############################

echo "$DIVIDER"
echo -e "Configuring ${BLUE}dotfiles${NO_COLOR}"

git clone --bare git@github.com:davidtucker/dotfiles.git $HOME/.cfg
/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME checkout
/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME config --local status.showUntrackedFiles no

echo '' >> ~/.zshrc
echo '# Dotfiles' >> ~/.zshrc
echo "alias dotfiles='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'" >> ~/.zshrc

# Update PATH and Source .zshrc
echo '' >> ~/.zshrc
echo '# Path' >> ~/.zshrc
echo 'export PATH="/opt/homebrew/opt/openjdk/bin:/usr/local/bin:$PATH"' >> ~/.zshrc

# Open iTerm2
open -a /Applications/iTerm.app

echo "$DIVIDER"
echo -e "${BLUE}Installation Complete${NO_COLOR}"
