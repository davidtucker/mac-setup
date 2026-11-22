# shellcheck shell=bash
# Helpers shared by setup.sh and every step. Written for the bash 3.2 that
# ships with macOS: no associative arrays, mapfile, or ${var,,}.

if [ -t 1 ]; then
  C_BLUE=$'\033[1;34m' C_GREEN=$'\033[0;32m' C_YELLOW=$'\033[0;33m'
  C_RED=$'\033[0;31m' C_DIM=$'\033[2m' C_RESET=$'\033[0m'
else
  C_BLUE='' C_GREEN='' C_YELLOW='' C_RED='' C_DIM='' C_RESET=''
fi

DRY_RUN="${DRY_RUN:-0}"
NON_INTERACTIVE="${NON_INTERACTIVE:-0}"
STATE_DIR="$HOME/.config/mac-setup"
ANSWERS_FILE="$STATE_DIR/answers.sh"
BACKUP_DIR="$HOME/.mac-setup-backup/$(date +%Y%m%d-%H%M%S)"

header() { printf '\n%s==> %s%s\n' "$C_BLUE" "$*" "$C_RESET"; }
info()   { printf '    %s\n' "$*"; }
ok()     { printf '    %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn()   { printf '    %s!%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
fail()   { printf '    %s✗%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
die()    { fail "$*"; exit 1; }
# did "message": report an action taken with `run`; silent in a dry run, where
# `run` has already printed what it would do.
did()    { dry || ok "$@"; }

has() { command -v "$1" >/dev/null 2>&1; }
dry() { [ "$DRY_RUN" = 1 ]; }
is_interactive() { [ "$NON_INTERACTIVE" != 1 ] && [ -t 0 ]; }

# Show a path with $HOME as ~.
pretty() {
  # shellcheck disable=SC2088 # a literal ~ for display
  case "$1" in
    "$HOME"/*) printf '~/%s' "${1#"$HOME"/}" ;;
    *) printf '%s' "$1" ;;
  esac
}

# run CMD [ARGS...]: run a command that changes the machine. With --dry-run,
# print it instead.
run() {
  if dry; then
    printf '    %s[dry-run]%s' "$C_DIM" "$C_RESET"
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  # `|| return` keeps a failure from tripping errexit in here, so the step's
  # error message names the caller's `run ...` line rather than "$@".
  "$@" || return
}

# need CMD HINT: succeed if CMD exists. Otherwise fail the step, or, in a dry
# run (where earlier steps only pretended to install things), warn and return
# 1 so the caller can `|| return 0`.
need() {
  has "$1" && return 0
  if dry; then
    warn "$1 isn't installed yet; skipping the rest of this step in the dry run."
    return 1
  fi
  die "$1 isn't installed. $2"
}

# Put Homebrew on PATH and set HOMEBREW_PREFIX for this process. Returns 1 if
# it isn't installed.
load_brew() {
  if [ -n "${HOMEBREW_PREFIX:-}" ] && has brew; then
    return 0
  fi
  local b
  for b in "$(command -v brew 2>/dev/null || true)" /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -n "$b" ] && [ -x "$b" ]; then
      eval "$("$b" shellenv bash)"
      return 0
    fi
  done
  return 1
}

# ask VAR "Question" [DEFAULT]: prompt for a value; Return keeps the default.
# Non-interactive and dry runs take the default without asking.
ask() {
  local _var="$1" _prompt="$2" _default="${3:-}" _reply=""
  if is_interactive && ! dry; then
    if [ -n "$_default" ]; then
      read -r -p "    $_prompt [$_default]: " _reply
    else
      read -r -p "    $_prompt: " _reply
    fi
  fi
  [ -n "$_reply" ] || _reply="$_default"
  printf -v "$_var" '%s' "$_reply"
}

# confirm "Question" [y|n]: yes/no prompt. Non-interactive runs get the default.
confirm() {
  local _prompt="$1" _default="${2:-y}" _reply=""
  if is_interactive; then
    if [ "$_default" = y ]; then
      read -r -p "    $_prompt [Y/n]: " _reply
    else
      read -r -p "    $_prompt [y/N]: " _reply
    fi
  fi
  [ -n "$_reply" ] || _reply="$_default"
  case "$_reply" in [Yy]*) return 0 ;; *) return 1 ;; esac
}

# Answers to setup questions persist in ~/.config/mac-setup/answers.sh so a
# re-run doesn't ask again. SETUP_* environment variables take precedence.
load_answers() {
  local env_name="${SETUP_COMPUTER_NAME:-}" env_git_name="${SETUP_GIT_NAME:-}" env_git_email="${SETUP_GIT_EMAIL:-}"
  # shellcheck source=/dev/null
  [ -f "$ANSWERS_FILE" ] && . "$ANSWERS_FILE"
  [ -n "$env_name" ] && SETUP_COMPUTER_NAME="$env_name"
  [ -n "$env_git_name" ] && SETUP_GIT_NAME="$env_git_name"
  [ -n "$env_git_email" ] && SETUP_GIT_EMAIL="$env_git_email"
  return 0
}

save_answer() {
  local key="$1" value="$2" tmp
  dry && return 0
  mkdir -p "$STATE_DIR"
  touch "$ANSWERS_FILE"
  tmp="$(mktemp)"
  grep -v "^$key=" "$ANSWERS_FILE" >"$tmp" || true
  printf '%s=%q\n' "$key" "$value" >>"$tmp"
  mv "$tmp" "$ANSWERS_FILE"
}

# write_file DEST < content: write DEST only if its content would change.
write_file() {
  local dest="$1" tmp
  tmp="$(mktemp)"
  cat >"$tmp"
  if [ -f "$dest" ] && cmp -s "$tmp" "$dest"; then
    rm -f "$tmp"
    return 0
  fi
  if dry; then
    rm -f "$tmp"
    info "${C_DIM}[dry-run]${C_RESET} write $(pretty "$dest")"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  # mktemp creates files as 0600; give config files normal permissions.
  chmod 644 "$tmp"
  mv "$tmp" "$dest"
  ok "Wrote $(pretty "$dest")"
}

# link_file SRC DEST: symlink DEST -> SRC. An existing file at DEST is moved
# into ~/.mac-setup-backup/<timestamp>/ first, never deleted.
link_file() {
  local src="$1" dest="$2" backup
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    return 0
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    backup="$BACKUP_DIR/${dest#"$HOME"/}"
    run mkdir -p "$(dirname "$backup")"
    run mv "$dest" "$backup"
    warn "Moved the existing $(pretty "$dest") to $(pretty "$backup")"
  fi
  [ -d "$(dirname "$dest")" ] || run mkdir -p "$(dirname "$dest")"
  run ln -s "$src" "$dest"
  did "Linked $(pretty "$dest")"
}

# Keep sudo's cached password fresh until this script exits, so long installs
# don't stop to ask again.
start_sudo_keepalive() {
  dry && return 0
  info "Some steps need administrator rights, so macOS will ask for your password."
  sudo -v || die "Couldn't get administrator rights."
  # Its output goes to /dev/null so it never holds this script's stdout open
  # (otherwise `./setup.sh | tee log` waits for its last sleep to end).
  (
    while kill -0 "$$" 2>/dev/null; do
      sudo -n true 2>/dev/null
      sleep 50
    done
  ) >/dev/null 2>&1 &
  SUDO_KEEPALIVE_PID=$!
  trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT
}
