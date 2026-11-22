#!/bin/bash
# Checks that every entry in the Brewfile still exists and isn't deprecated or
# disabled, without installing anything. Catches renamed or removed casks
# before a new Mac does.
set -euo pipefail

brewfile="${1:-Brewfile}"
status=0

# Reading package info from a third-party tap needs tap trust, which the
# Brewfile's `trusted:` options only grant during `brew bundle install`.
export HOMEBREW_NO_REQUIRE_TAP_TRUST=1

for tap in $(brew bundle list --file "$brewfile" --tap); do
  brew tap "$tap" >/dev/null
done

check() {
  local kind="$1" label="$2" names
  names="$(brew bundle list --file "$brewfile" "--$kind")"
  [ -n "$names" ] || return 0
  local info
  # shellcheck disable=SC2086 # one argument per name
  if ! info="$(brew info --json=v2 "--$kind" $names)"; then
    echo "::error::Some $label in $brewfile don't exist (see the error above)."
    status=1
    return 0
  fi
  local bad
  bad="$(jq -r '(.formulae + .casks)[]
    | select(.deprecated or .disabled)
    | "\(.full_token // .full_name) is \(if .disabled then "disabled" else "deprecated" end): \(.disable_reason // .deprecation_reason // "no reason given")"' <<<"$info")"
  if [ -n "$bad" ]; then
    while IFS= read -r line; do echo "::error::$line"; done <<<"$bad"
    status=1
  fi
  echo "Checked $(wc -w <<<"$names" | tr -d ' ') $label."
}

check formula formulae
check cask casks

# App Store IDs: look each one up in Apple's public catalog.
while IFS= read -r line; do
  name="$(sed -E 's/^mas "([^"]+)".*/\1/' <<<"$line")"
  id="$(sed -E 's/.*id: *([0-9]+).*/\1/' <<<"$line")"
  found="$(curl -fsS "https://itunes.apple.com/lookup?id=$id&country=us" | jq -r '.results[0].trackName // empty')"
  if [ -z "$found" ]; then
    echo "::error::App Store ID $id ($name) wasn't found."
    status=1
  else
    echo "App Store $id: $found"
  fi
done < <(grep -E '^mas "' "$brewfile")

exit "$status"
