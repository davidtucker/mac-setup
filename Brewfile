# Everything this Mac installs from Homebrew and the Mac App Store.
#
#   brew bundle --file Brewfile            install what's missing (./setup.sh packages)
#   brew bundle cleanup --file Brewfile    list what's installed but not in here
#
# Add a line here rather than running `brew install`, so the next Mac gets it too.

tap "davidtucker/tap"

# ── Git ───────────────────────────────────────────────────────────────────────
brew "git"
brew "gh"
brew "git-lfs"              # large files (video, images) in git
brew "git-delta"            # readable diffs; set as git's pager in home/.config/git/config

# ── Command-line basics ───────────────────────────────────────────────────────
brew "bat"                  # cat with syntax highlighting
brew "btop"                 # process and resource monitor
brew "direnv"               # per-directory environment variables (.envrc)
brew "exiftool"             # image metadata; git diffs images with it (diff=exif)
brew "eza"                  # ls with git status (ll, la, lt aliases)
brew "fd"                   # faster, friendlier find
brew "fzf"                  # fuzzy finder: Ctrl-R history, Ctrl-T files
brew "jq"                   # JSON
brew "ripgrep"              # faster grep (rg)
brew "tlrc"                 # short command examples (tldr)
brew "tree"
brew "wget"
brew "yq"                   # YAML
brew "zoxide"               # cd to frequent directories (z)

# ── Shell ─────────────────────────────────────────────────────────────────────
brew "starship"             # prompt; config in home/.config/starship.toml
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"

# ── Languages ─────────────────────────────────────────────────────────────────
brew "mise"                 # Node, Python, Java, Go, Rust; versions in home/.config/mise/config.toml
brew "uv"                   # Python packages and virtual environments
brew "pnpm"                 # Node package manager (a standalone binary)
brew "go-task"              # Taskfile runner: `task` (the "task" formula is Taskwarrior)

# ── AWS ───────────────────────────────────────────────────────────────────────
brew "awscli"
brew "aws-sam-cli"
cask "session-manager-plugin"
cask "davidtucker/tap/envhaul", trusted: true   # your tap; Homebrew 6+ requires trusting third-party casks

# ── Containers: Docker CLI on a Colima VM, no Docker Desktop ──────────────────
brew "colima"
brew "docker"
brew "docker-buildx"
brew "docker-compose"
brew "docker-credential-helper"

# ── Mobile: iOS and Android (Xcode is in the App Store section) ───────────────
brew "watchman"             # file watcher used by React Native's bundler
brew "cocoapods"            # iOS dependency manager
cask "android-studio"
cask "zulu@17"              # the JDK React Native's Android builds expect

# ── Mac App Store (sign in to the App Store first) ────────────────────────────
brew "mas"
mas "Xcode", id: 497799835
mas "DaVinci Resolve", id: 571213070   # Studio, if you own it: id 900392332

# ── Terminal, editors, AI ─────────────────────────────────────────────────────
cask "ghostty"
cask "visual-studio-code"
cask "sublime-text"
cask "claude"
cask "claude-code"
cask "font-jetbrains-mono-nerd-font"   # prompt icons in VS Code's terminal; Ghostty has its own

# ── Browsers ──────────────────────────────────────────────────────────────────
cask "brave-browser"
cask "google-chrome"

# ── Office and communication ──────────────────────────────────────────────────
cask "microsoft-office-businesspro"    # Word, Excel, PowerPoint, Outlook, OneNote, OneDrive, Teams
cask "slack"
cask "zoom"

# ── Productivity ──────────────────────────────────────────────────────────────
cask "1password"
cask "1password-cli"
cask "bartender"
cask "jump-desktop"
cask "logos"
cask "openlogi"                        # Logitech mouse and keyboard settings, without Options+
cask "raycast"
cask "spotify"
cask "todoist-app"

# ── Media ─────────────────────────────────────────────────────────────────────
cask "adobe-creative-cloud"            # install Photoshop, Premiere, etc. from inside Creative Cloud
cask "elgato-camera-hub"
cask "elgato-control-center"
cask "screenflick"
