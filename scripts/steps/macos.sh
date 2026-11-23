# shellcheck shell=bash
# macOS settings, Touch ID for sudo, and the computer's name.

step_macos() {
  set_computer_name
  enable_touch_id_for_sudo
  enable_fast_user_switching

  # Dock on the right, hidden until you point at it
  run defaults write com.apple.dock orientation -string right
  run defaults write com.apple.dock autohide -bool true

  # Keep Spaces in the order you set; don't reorder them by most recent use
  run defaults write com.apple.dock mru-spaces -bool false

  # Finder: show hidden files (dotfiles), all extensions, the sidebar, the
  # path and status bars, and the full path in the title; open windows in
  # list view
  run defaults write com.apple.finder AppleShowAllFiles -bool true
  run defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  run defaults write com.apple.finder ShowSidebar -bool true
  run defaults write com.apple.finder ShowStatusBar -bool true
  run defaults write com.apple.finder ShowPathbar -bool true
  run defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
  run defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
  run defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
  run chflags nohidden "$HOME/Library"

  # Open the save and print dialogs fully expanded
  run defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
  run defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
  run defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
  run defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

  # Save new documents to this Mac, not iCloud
  run defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

  # Type straight quotes and plain dashes (better for code)
  run defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
  run defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

  # Quit the printer app once print jobs finish
  run defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

  # Screenshots go to ~/Screenshots instead of the Desktop
  run mkdir -p "$HOME/Screenshots"
  run defaults write com.apple.screencapture location -string "$HOME/Screenshots"

  add_projects_folder

  # Restart the apps that read these settings
  local app
  for app in Dock Finder SystemUIServer; do
    run killall "$app" 2>/dev/null || true
  done
  did "Applied macOS settings"
}

set_computer_name() {
  local name="${SETUP_COMPUTER_NAME:-}" host key current
  if [ -z "$name" ]; then
    warn "No computer name given; leaving it as $(scutil --get ComputerName 2>/dev/null)."
    return 0
  fi
  # LocalHostName and HostName allow only letters, digits and hyphens.
  host="$(printf '%s' "$name" | tr -c 'A-Za-z0-9-' '-' | sed -E 's/-+/-/g; s/^-//; s/-$//')"

  if [ "$(scutil --get ComputerName 2>/dev/null)" != "$name" ]; then
    run sudo scutil --set ComputerName "$name"
  fi
  for key in LocalHostName HostName; do
    current="$(scutil --get "$key" 2>/dev/null || true)"
    [ "$current" = "$host" ] || run sudo scutil --set "$key" "$host"
  done
  ok "Computer name: $name (network name $host)"
}

# macOS 14+ reads /etc/pam.d/sudo_local, which, unlike /etc/pam.d/sudo,
# survives macOS updates.
enable_touch_id_for_sudo() {
  local file=/etc/pam.d/sudo_local
  if ! grep -q sudo_local /etc/pam.d/sudo 2>/dev/null; then
    warn "This macOS doesn't support $file; skipping Touch ID for sudo."
    return 0
  fi
  if [ -f "$file" ] && grep -Eq '^[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so' "$file"; then
    ok "Touch ID for sudo is on"
    return 0
  fi
  if dry; then
    info "${C_DIM}[dry-run]${C_RESET} add pam_tid.so to $file"
    return 0
  fi
  printf 'auth       sufficient     pam_tid.so\n' | sudo tee -a "$file" >/dev/null
  ok "Touch ID for sudo is on (in new terminal windows)"
}

# Fast user switching, with its menu in the menu bar. MultipleSessionEnabled
# turns the feature on; the controlcenter keys show its menu (18 = show in
# the menu bar).
enable_fast_user_switching() {
  run sudo defaults write /Library/Preferences/.GlobalPreferences MultipleSessionEnabled -bool true
  run defaults -currentHost write com.apple.controlcenter UserSwitcher -int 18
  run defaults write com.apple.controlcenter "NSStatusItem Visible UserSwitcher" -bool true
  did "Fast user switching is on and shown in the menu bar"
}

# ~/Projects, added to Finder's sidebar once. A marker file records that it
# was added, so a re-run doesn't add it again (or re-add it after you remove
# it from the sidebar yourself).
add_projects_folder() {
  local dir="$HOME/Projects" marker="$STATE_DIR/finder-sidebar-projects"
  [ -d "$dir" ] || run mkdir -p "$dir"
  if [ -f "$marker" ]; then
    ok "$(pretty "$dir") is in Finder's sidebar"
    return 0
  fi
  if dry; then
    info "${C_DIM}[dry-run]${C_RESET} add $(pretty "$dir") to Finder's sidebar"
    return 0
  fi
  if sfltool add-item com.apple.LSSharedFileList.FavoriteItems "file://$dir/" >/dev/null 2>&1; then
    mkdir -p "$STATE_DIR"
    touch "$marker"
    ok "Added $(pretty "$dir") to Finder's sidebar"
  else
    warn "Couldn't add $(pretty "$dir") to Finder's sidebar; drag it there from Finder."
  fi
}
