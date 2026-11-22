# Login shell: PATH and environment. Interactive settings are in ~/.zshrc.

# Homebrew
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# Programs installed by `cargo install`, `go install`, and user scripts
typeset -U path
path=("$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/go/bin" $path)

# Android SDK, which Android Studio downloads on first launch (adb, emulator)
export ANDROID_HOME="$HOME/Library/Android/sdk"
path=($path "$ANDROID_HOME/emulator" "$ANDROID_HOME/platform-tools")
