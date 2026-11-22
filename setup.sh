#!/bin/bash
# Sets up this Mac. Safe to re-run: every step checks before it changes
# anything, so re-running is also how you apply changes to this repo.
#
#   ./setup.sh                 run every step
#   ./setup.sh docker xcode    run only these steps
#   ./setup.sh --dry-run       show what would change without changing it
#   ./setup.sh --help

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ROOT

# shellcheck source=scripts/lib.sh
. "$ROOT/scripts/lib.sh"

# Run order. Interactive steps (password, questions, GitHub sign-in) come
# first so the long unattended install can run without you.
STEPS="homebrew github packages macos dotfiles languages docker xcode checklist"

for _step in preflight $STEPS; do
  # shellcheck source=/dev/null
  . "$ROOT/scripts/steps/$_step.sh"
done

describe_step() {
  case "$1" in
    homebrew)  echo "Homebrew and Rosetta" ;;
    github)    echo "SSH key and GitHub sign-in" ;;
    packages)  echo "Apps and tools from the Brewfile" ;;
    macos)     echo "macOS settings, Touch ID for sudo, computer name" ;;
    dotfiles)  echo "Config files from home/ and your git identity" ;;
    languages) echo "Node, Python, Java, Go and Rust (mise)" ;;
    docker)    echo "Docker on a Colima VM" ;;
    xcode)     echo "Xcode license, first launch, iOS simulator" ;;
    checklist) echo "Sign-ins and other manual steps" ;;
  esac
}

usage() {
  cat <<EOF
Usage: ./setup.sh [options] [step...]

Runs every step in order, or only the steps you name.

Steps:
EOF
  for s in $STEPS; do printf '  %-10s %s\n' "$s" "$(describe_step "$s")"; done
  cat <<EOF

Options:
  -n, --dry-run          Show what would change without changing anything
  -y, --non-interactive  Never prompt; take answers from SETUP_COMPUTER_NAME,
                         SETUP_GIT_NAME and SETUP_GIT_EMAIL (or saved answers)
  -h, --help             Show this help
EOF
}

is_step() {
  local s
  for s in $STEPS; do [ "$s" = "$1" ] && return 0; done
  return 1
}

SELECTED=""
while [ $# -gt 0 ]; do
  case "$1" in
    -n | --dry-run) DRY_RUN=1 ;;
    -y | --non-interactive) NON_INTERACTIVE=1 ;;
    -h | --help) usage; exit 0 ;;
    -*) usage >&2; die "Unknown option: $1" ;;
    *) is_step "$1" || { usage >&2; die "Unknown step: $1"; }
       SELECTED="$SELECTED $1" ;;
  esac
  shift
done
[ -n "$SELECTED" ] || SELECTED="$STEPS"
export DRY_RUN NON_INTERACTIVE

# ERR trap for steps: name the command that stopped the step. Skips failures
# inside $(...) (they don't stop the step) and a step's own `return 1` (it
# has already said why).
report_failure() {
  [ "$BASH_SUBSHELL" = "$step_level" ] || return 0
  case "$1" in return*) return 0 ;; esac
  fail "Failed: $1"
}

wants_step() {
  case " $SELECTED " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

# Preflight runs in this shell (not a subshell) so its answers reach every step.
header "Preflight"
step_preflight

PASSED=""
FAILED=""
for s in $STEPS; do
  wants_step "$s" || continue
  header "$(describe_step "$s")"
  # Each step runs in a subshell with errexit, so the first failing command
  # stops that step and the run moves on to the next one. The status is read
  # afterwards on purpose: inside `if ( ... )`, bash would ignore errexit.
  (
    set -eE
    # -E also runs the trap inside $(...), where a failure doesn't stop the
    # step, so only report failures at the step's own level.
    step_level=$BASH_SUBSHELL
    trap 'report_failure "$BASH_COMMAND"' ERR
    "step_$s"
  )
  status=$?
  if [ "$status" -eq 0 ]; then
    PASSED="$PASSED $s"
  else
    FAILED="$FAILED $s"
  fi
done

header "Summary"
for s in $PASSED; do ok "$s"; done
for s in $FAILED; do fail "$s"; done
if [ -n "$FAILED" ]; then
  info ""
  info "Fix the errors above, then re-run the failed steps:"
  info "  $ROOT/setup.sh$FAILED"
  exit 1
fi
dry && { info ""; info "Dry run: nothing was changed."; exit 0; }
info ""
info "Done. Open a new Ghostty window to load your new shell."
