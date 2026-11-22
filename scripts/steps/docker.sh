# shellcheck shell=bash
# Docker without Docker Desktop: the Docker CLI talks to a Linux VM run by
# Colima, which starts when you log in.

step_docker() {
  load_brew || die "Homebrew isn't installed. Run: ./setup.sh homebrew"
  need colima "Run: ./setup.sh packages" || return 0
  need docker "Run: ./setup.sh packages" || return 0
  need jq "Run: ./setup.sh packages" || return 0

  configure_docker_cli
  create_colima_vm
  start_colima_at_login
}

# Homebrew's compose and buildx plugins live outside Docker's default plugin
# folder, and registry logins should go to the macOS keychain.
configure_docker_cli() {
  local config="$HOME/.docker/config.json"
  local plugins="$HOMEBREW_PREFIX/lib/docker/cli-plugins"
  local updated
  if [ -f "$config" ]; then
    updated="$(jq --arg dir "$plugins" '
      .cliPluginsExtraDirs = (((.cliPluginsExtraDirs // []) + [$dir]) | unique)
      | .credsStore //= "osxkeychain"' "$config")"
  else
    updated="$(jq -n --arg dir "$plugins" '{cliPluginsExtraDirs: [$dir], credsStore: "osxkeychain"}')"
  fi
  printf '%s\n' "$updated" | write_file "$config"
  did "Docker finds compose and buildx, and stores logins in the keychain"
}

# The VM gets half this Mac's CPUs and memory. It uses Apple's virtualization
# framework, with Rosetta so amd64 (Intel) images run fast.
create_colima_vm() {
  if colima list --json 2>/dev/null | jq -e -s 'any(.[]; .name == "default")' >/dev/null; then
    ok "Colima VM exists (change its size with: colima start --edit)"
    return 0
  fi
  local cpus memory
  cpus=$(($(sysctl -n hw.ncpu) / 2))
  memory=$(($(sysctl -n hw.memsize) / 1073741824 / 2))
  [ "$cpus" -ge 2 ] || cpus=2
  [ "$memory" -ge 4 ] || memory=4
  info "Creating the Colima VM: $cpus CPUs, $memory GB memory, 100 GB disk"
  run colima start --vm-type vz --vz-rosetta --cpus "$cpus" --memory "$memory" --disk 100
  # Stop it so the login service below owns the running VM.
  run colima stop
  did "Created the Colima VM"
}

start_colima_at_login() {
  local status
  status="$(brew services list | awk '$1 == "colima" { print $2 }')"
  if [ "$status" = started ]; then
    ok "Colima starts at login"
  else
    run brew services start colima
    did "Colima starts at login"
  fi

  dry && return 0
  info "Waiting for Docker to come up..."
  for _ in $(seq 1 30); do
    if docker info >/dev/null 2>&1; then
      ok "Docker works (try: docker run --rm hello-world)"
      return 0
    fi
    sleep 3
  done
  warn "Docker isn't answering yet. Check: colima status, and $(pretty "$HOMEBREW_PREFIX/var/log/colima.log")"
}
