# shellcheck shell=bash
# Installs the default language versions listed in
# home/.config/mise/config.toml. Projects can pin their own versions.

step_languages() {
  load_brew || die "Homebrew isn't installed. Run: ./setup.sh homebrew"
  need mise "Run: ./setup.sh packages" || return 0

  local config="$HOME/.config/mise/config.toml"
  if [ ! -e "$config" ]; then
    dry && { warn "$(pretty "$config") isn't linked yet; skipping in the dry run."; return 0; }
    die "$(pretty "$config") is missing. Run: ./setup.sh dotfiles"
  fi

  export MISE_YES=1
  if dry; then
    info "Would install these versions (missing ones only):"
    mise ls --global 2>&1 | sed 's/^/      /' || true
    return 0
  fi
  mise install
  ok "Installed:"
  mise ls --global | sed 's/^/      /'
}
