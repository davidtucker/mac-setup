# shellcheck shell=bash
# Everything in the Brewfile: command-line tools, apps, and App Store apps.

step_packages() {
  load_brew || die "Homebrew isn't installed. Run: ./setup.sh homebrew"
  local brewfile="$ROOT/Brewfile"

  if dry; then
    info "Would install anything in the Brewfile that's missing or outdated:"
    brew bundle check --file "$brewfile" --verbose 2>&1 | sed 's/^/      /' || true
    return 0
  fi

  info "This is the long one: Office, Adobe Creative Cloud and Xcode are big downloads."
  info "App Store apps (Xcode, DaVinci Resolve) need you signed in to the App Store."
  if ! brew bundle install --file "$brewfile"; then
    die "Some packages didn't install (see above). If they're App Store apps, sign in to the App Store, then run: ./setup.sh packages"
  fi
  ok "Everything in the Brewfile is installed"
}
