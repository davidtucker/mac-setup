# shellcheck shell=bash
# An SSH key (no passphrase), GitHub CLI sign-in, and the key added to your
# GitHub account. Runs early because the sign-in opens a browser.

step_github() {
  load_brew || die "Homebrew isn't installed. Run: ./setup.sh homebrew"
  has gh || run brew install gh
  need gh "Run: brew install gh" || return 0

  local key="$HOME/.ssh/id_ed25519"
  if [ ! -d "$HOME/.ssh" ]; then
    run mkdir -p "$HOME/.ssh"
    run chmod 700 "$HOME/.ssh"
  fi
  if [ -f "$key" ]; then
    ok "SSH key exists: $(pretty "$key")"
  else
    run ssh-keygen -q -t ed25519 -N "" -C "${SETUP_GIT_EMAIL:-$USER@$(hostname -s)}" -f "$key"
    did "Created $(pretty "$key") with no passphrase"
  fi

  # GitHub's host keys, fetched over authenticated HTTPS rather than trusted
  # on first connect.
  if ssh-keygen -F github.com >/dev/null 2>&1; then
    ok "GitHub's host keys are in ~/.ssh/known_hosts"
  elif dry; then
    info "${C_DIM}[dry-run]${C_RESET} add GitHub's host keys to ~/.ssh/known_hosts"
  else
    gh api meta --jq '.ssh_keys[]' | sed 's/^/github.com /' >>"$HOME/.ssh/known_hosts"
    ok "Added GitHub's host keys to ~/.ssh/known_hosts"
  fi

  if gh auth status --hostname github.com >/dev/null 2>&1; then
    ok "Signed in to GitHub as $(gh api user --jq .login)"
  elif dry; then
    info "${C_DIM}[dry-run]${C_RESET} gh auth login (opens your browser)"
    return 0
  elif is_interactive; then
    info "Signing in to GitHub. Your browser will open; enter the code shown here."
    gh auth login --hostname github.com --git-protocol ssh --web --skip-ssh-key --scopes admin:public_key
  else
    warn "Not signed in to GitHub, so the SSH key wasn't added to your account."
    warn "Run this later: ./setup.sh github"
    return 0
  fi

  if dry; then
    info "${C_DIM}[dry-run]${C_RESET} add the SSH key to your GitHub account if it isn't there"
    return 0
  fi

  # Sign-ins made without this script may lack permission to manage SSH keys.
  if ! gh api user/keys >/dev/null 2>&1; then
    info "GitHub needs one more permission to add your SSH key."
    gh auth refresh --hostname github.com --scopes admin:public_key
  fi

  # Compare "type base64" only; GitHub doesn't keep the key's comment.
  local pub on_github
  pub="$(cut -d' ' -f1,2 "$key.pub")"
  on_github="$(gh api --paginate user/keys --jq '.[].key')"
  if grep -qxF "$pub" <<<"$on_github"; then
    ok "Your SSH key is on your GitHub account"
  else
    gh ssh-key add "$key.pub" --title "$(scutil --get ComputerName)"
    ok "Added your SSH key to GitHub"
  fi

  # `ssh -T` exits 1 even when authentication works, so check its message.
  local greeting
  greeting="$(ssh -T -o BatchMode=yes -o ConnectTimeout=10 git@github.com 2>&1 || true)"
  case "$greeting" in
    *"successfully authenticated"*) ok "SSH to GitHub works" ;;
    *) warn "SSH to GitHub didn't work yet: $greeting" ;;
  esac

  # This repo was cloned over HTTPS before the key existed; switch it to SSH
  # so you can push changes.
  local origin
  origin="$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)"
  case "$origin" in
    https://github.com/*)
      origin="${origin#https://github.com/}"
      run git -C "$ROOT" remote set-url origin "git@github.com:${origin%.git}.git"
      did "This repo now pushes over SSH"
      ;;
  esac
}
