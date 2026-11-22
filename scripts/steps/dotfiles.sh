# shellcheck shell=bash
# Links every file under home/ into your home folder, so edits on either side
# are edits to this repo. Writes your git name and email to ~/.gitconfig,
# which stays out of the repo.

step_dotfiles() {
  local src
  while IFS= read -r src; do
    link_file "$src" "$HOME/${src#"$ROOT/home/"}"
  done < <(find "$ROOT/home" -type f ! -name .DS_Store | sort)
  ok "Config files from home/ are linked"

  # Shared git settings live in ~/.config/git/config (linked above).
  # ~/.gitconfig holds this machine's identity, and it must exist so that
  # `git config --global` and tools like gh write there instead of into the
  # linked file in this repo.
  local gitconfig="$HOME/.gitconfig"
  [ -e "$gitconfig" ] || run touch "$gitconfig"
  set_git_value user.name "${SETUP_GIT_NAME:-}"
  set_git_value user.email "${SETUP_GIT_EMAIL:-}"
}

set_git_value() {
  local key="$1" value="$2" gitconfig="$HOME/.gitconfig"
  if [ -z "$value" ]; then
    warn "No value for git $key; set it with: git config --global $key ..."
    return 0
  fi
  if [ "$(git config --file "$gitconfig" "$key" 2>/dev/null || true)" != "$value" ]; then
    run git config --file "$gitconfig" "$key" "$value"
  fi
  ok "git $key: $value"
}
