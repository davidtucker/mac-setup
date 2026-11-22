# shellcheck shell=bash
# Finishes Xcode setup after the App Store installs it: makes it the active
# developer directory, accepts the license, runs the first-launch install, and
# downloads the iOS simulator.

step_xcode() {
  local app=/Applications/Xcode.app
  local developer="$app/Contents/Developer"
  if [ ! -d "$app" ]; then
    warn "Xcode isn't installed yet. It comes from the App Store in the packages step."
    return 0
  fi

  if [ "$(xcode-select -p 2>/dev/null)" = "$developer" ]; then
    ok "Xcode is the active developer directory"
  else
    run sudo xcode-select --switch "$developer"
    did "Xcode is now the active developer directory"
  fi

  if xcodebuild -license check >/dev/null 2>&1; then
    ok "Xcode license accepted"
  else
    run sudo xcodebuild -license accept
    did "Accepted the Xcode license"
  fi

  if xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
    ok "Xcode's first-launch components are installed"
  else
    run sudo xcodebuild -runFirstLaunch
    did "Installed Xcode's first-launch components"
  fi

  local runtimes
  runtimes="$(xcrun simctl list runtimes 2>/dev/null || true)"
  if grep -q '^iOS' <<<"$runtimes"; then
    ok "An iOS simulator is installed"
  else
    info "Downloading the iOS simulator (several GB)..."
    run xcodebuild -downloadPlatform iOS
    did "Installed the iOS simulator"
  fi
}
