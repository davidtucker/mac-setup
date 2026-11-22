# shellcheck shell=bash
# Checks the machine, asks the few questions setup needs, and caches sudo.
# Runs before every other step, in the main shell.

step_preflight() {
  [ "$(uname -s)" = Darwin ] || die "This only runs on macOS."
  [ "$(uname -m)" = arm64 ] || die "This expects an Apple silicon Mac."
  [ "$(id -u)" -ne 0 ] || die "Run this as your own user, not root. It asks for sudo when it needs it."

  local version major
  version="$(sw_vers -productVersion)"
  major="${version%%.*}"
  [ "$major" -ge 15 ] || die "macOS 15 or later is required (this Mac has $version)."
  ok "macOS $version on Apple silicon"
  dry && info "Dry run: nothing will be changed."

  load_answers
  if wants_step macos && [ -z "${SETUP_COMPUTER_NAME:-}" ]; then
    ask SETUP_COMPUTER_NAME "Computer name" "$(scutil --get ComputerName 2>/dev/null || true)"
  fi
  if wants_step dotfiles || wants_step github; then
    [ -n "${SETUP_GIT_NAME:-}" ] ||
      ask SETUP_GIT_NAME "Your name for git commits" "$(git config --global user.name 2>/dev/null || id -F 2>/dev/null || true)"
    [ -n "${SETUP_GIT_EMAIL:-}" ] ||
      ask SETUP_GIT_EMAIL "Your email for git commits" "$(git config --global user.email 2>/dev/null || true)"
  fi

  [ -z "${SETUP_COMPUTER_NAME:-}" ] || save_answer SETUP_COMPUTER_NAME "$SETUP_COMPUTER_NAME"
  [ -z "${SETUP_GIT_NAME:-}" ] || save_answer SETUP_GIT_NAME "$SETUP_GIT_NAME"
  [ -z "${SETUP_GIT_EMAIL:-}" ] || save_answer SETUP_GIT_EMAIL "$SETUP_GIT_EMAIL"
  export SETUP_COMPUTER_NAME SETUP_GIT_NAME SETUP_GIT_EMAIL
  if [ -n "${SETUP_COMPUTER_NAME:-}${SETUP_GIT_NAME:-}${SETUP_GIT_EMAIL:-}" ] && ! dry; then
    ok "Your answers are in $(pretty "$ANSWERS_FILE"); edit that file to change them"
  fi

  if wants_step homebrew || wants_step packages || wants_step macos || wants_step xcode; then
    start_sudo_keepalive
  fi
}
