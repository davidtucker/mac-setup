#!/bin/bash
# The first thing to run on a new Mac:
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/davidtucker/mac-setup/main/bootstrap.sh)"
#
# Installs Homebrew (which brings Apple's command-line tools, including git),
# clones this repo to ~/Developer/mac-setup, and runs setup.sh.
#
# To try a branch: MAC_SETUP_BRANCH=my-branch /bin/bash -c "$(curl -fsSL \
#   https://raw.githubusercontent.com/davidtucker/mac-setup/my-branch/bootstrap.sh)"

set -euo pipefail

REPO="${MAC_SETUP_REPO:-https://github.com/davidtucker/mac-setup.git}"
BRANCH="${MAC_SETUP_BRANCH:-main}"
DEST="${MAC_SETUP_DIR:-$HOME/Developer/mac-setup}"

[ "$(uname -s)" = Darwin ] || { echo "This only runs on macOS." >&2; exit 1; }
[ "$(uname -m)" = arm64 ] || { echo "This expects an Apple silicon Mac." >&2; exit 1; }

echo "==> mac-setup"
echo "    Stay for the first few minutes: your password, three questions, and a"
echo "    GitHub sign-in in your browser. After that it runs on its own."
echo
sudo -v

# Keep sudo's cached password fresh while Homebrew installs. setup.sh, which
# replaces this process below, keeps it fresh from then on.
( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done ) &

if [ ! -x /opt/homebrew/bin/brew ]; then
  echo "==> Installing Homebrew and Apple's command-line tools"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv bash)"

if [ -d "$DEST/.git" ]; then
  echo "==> Updating $DEST"
  git -C "$DEST" pull --ff-only
else
  echo "==> Downloading mac-setup to $DEST"
  mkdir -p "$(dirname "$DEST")"
  git clone --branch "$BRANCH" "$REPO" "$DEST"
fi

# ${1+"$@"} passes any arguments through; a bare "$@" with none can trip
# `set -u` in older bash.
exec "$DEST/setup.sh" ${1+"$@"}
