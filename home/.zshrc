# Interactive zsh. PATH is set in ~/.zprofile. Put anything specific to one
# machine in ~/.zshrc.local, which isn't in git.

# ── History ──────────────────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS SHARE_HISTORY
setopt AUTO_CD INTERACTIVE_COMMENTS

# ── Completion (Homebrew installs completions for brew, gh, aws, docker...) ──
if [[ -n "$HOMEBREW_PREFIX" ]]; then
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
fi
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select

# ── Tools ────────────────────────────────────────────────────────────────────
(( $+commands[mise] ))     && eval "$(mise activate zsh)"
(( $+commands[starship] )) && eval "$(starship init zsh)"
(( $+commands[zoxide] ))   && eval "$(zoxide init zsh)"
(( $+commands[direnv] ))   && eval "$(direnv hook zsh)"
(( $+commands[fzf] ))      && source <(fzf --zsh)

# ── Aliases ──────────────────────────────────────────────────────────────────
if (( $+commands[eza] )); then
  alias ll='eza -l --git --group-directories-first'
  alias la='eza -la --git --group-directories-first'
  alias lt='eza --tree --level=2 --group-directories-first'
fi
alias mac-setup='cd ~/Developer/mac-setup'

# ── This machine only ────────────────────────────────────────────────────────
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# ── Plugins (syntax highlighting must load last) ─────────────────────────────
if [[ -n "$HOMEBREW_PREFIX" ]]; then
  [[ -f "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] &&
    source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -f "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] &&
    source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
