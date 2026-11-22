# shellcheck shell=bash
# What setup can't do for you: sign-ins, licenses, and the permissions macOS
# only lets you grant by clicking. Offers to open each app in turn.

# One item per line: what to open | what to do there.
# "id:" opens by bundle ID, "app:" by app name, "-" opens nothing.
CHECKLIST="
id:com.1password.1password|1Password: sign in.
id:com.microsoft.Word|Microsoft 365: sign in to Word; that activates Excel, PowerPoint, Outlook and OneNote too.
id:com.microsoft.teams2|Teams: sign in.
id:com.adobe.acc.AdobeCreativeCloud|Adobe Creative Cloud: sign in, then install Photoshop, Premiere Pro and the rest from the Apps tab.
id:com.anthropic.claudefordesktop|Claude: sign in. Then run 'claude' in Ghostty to sign in to Claude Code.
id:com.microsoft.VSCode|VS Code: turn on Settings Sync (Accounts menu, Backup and Sync Settings) to bring back your settings and extensions.
id:com.raycast.macos|Raycast: finish onboarding. To give it Cmd-Space, first turn off Spotlight's shortcut in System Settings > Keyboard > Keyboard Shortcuts > Spotlight.
id:com.surteesstudios.Bartender|Bartender: enter your license and allow the Accessibility and Screen Recording permissions it asks for.
app:Jump Desktop|Jump Desktop: sign in.
id:com.tinyspeck.slackmacgap|Slack: sign in to your workspaces.
id:us.zoom.xos|Zoom: sign in.
app:Todoist|Todoist: sign in.
id:com.spotify.client|Spotify: sign in.
id:com.logos.desktop.logos|Logos: sign in and let it download your library.
app:Screenflick|Screenflick: enter your license and allow Screen Recording and Microphone.
id:com.corsair.ControlCenter|Elgato Control Center: connect your lights.
id:com.elgato.CameraHub|Elgato Camera Hub: check your camera.
app:DaVinci Resolve|DaVinci Resolve: open it once to finish setup.
id:com.brave.Browser|Brave: sign in to sync, and choose your default browser.
id:com.google.Chrome|Chrome: sign in to sync.
-|AWS: in Ghostty, run 'aws configure sso' for each account you use.
"

step_checklist() {
  local walk=0 target text
  if is_interactive && ! dry && confirm "Walk through these now, opening each app in turn?" y; then
    walk=1
  fi
  while IFS='|' read -r target text; do
    [ -n "$target" ] || continue
    if [ "$walk" = 1 ]; then
      printf '\n    %s\n' "$text"
      case "$target" in
        id:*) open -b "${target#id:}" 2>/dev/null || warn "Couldn't open it; is it installed?" ;;
        app:*) open -a "${target#app:}" 2>/dev/null || warn "Couldn't open it; is it installed?" ;;
      esac
      read -r -p "    Press Return for the next one..." _ </dev/tty
    else
      info "[ ] $text"
    fi
  done <<<"$CHECKLIST"
  [ "$walk" = 1 ] || info "Run ./setup.sh checklist any time to walk through these."
}
