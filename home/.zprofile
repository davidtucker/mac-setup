# Login shell: PATH and environment. Interactive settings are in ~/.zshrc.

# Homebrew
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# Programs installed by `cargo install`, `go install`, and user scripts
typeset -U path
path=("$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/go/bin" $path)
