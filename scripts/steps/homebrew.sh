# shellcheck shell=bash
# Rosetta (for Intel-only apps and amd64 containers) and Homebrew.

step_homebrew() {
  if arch -x86_64 /usr/bin/true 2>/dev/null; then
    ok "Rosetta is installed"
  else
    run sudo softwareupdate --install-rosetta --agree-to-license
  fi

  if load_brew; then
    ok "Homebrew is installed ($(brew --version | head -n 1))"
  elif dry; then
    info "${C_DIM}[dry-run]${C_RESET} install Homebrew"
  else
    # The official installer. It also installs Apple's command-line developer
    # tools if they're missing. NONINTERACTIVE skips its "press Return" prompt;
    # it uses the sudo password cached by preflight.
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    load_brew || die "Homebrew installed, but brew isn't where it should be."
    ok "Installed Homebrew"
  fi
}
