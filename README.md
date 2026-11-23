# mac-setup

Sets up a new Apple silicon Mac for development and media work with one
command: apps, command-line tools, languages, Docker, macOS settings, shell
and git config, and an SSH key on GitHub.

Every step checks before it changes anything, so you can run it again at any
time. Running it again is also how you apply changes you make to this repo.

## Before you start

On the new Mac:

1. Finish the setup screens and sign in with your Apple ID. That also signs
   you in to the App Store, which Xcode and DaVinci Resolve install from.
2. Turn on FileVault if the setup screens didn't.
3. Install any macOS updates (System Settings > General > Software Update).

## Run it

Open Terminal and run:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/davidtucker/mac-setup/main/bootstrap.sh)"
```

Stay for the first few minutes. It asks for your password, a computer name,
and your name and email for git commits, then opens your browser to sign in
to GitHub. After that it runs on its own; Office, Adobe Creative Cloud and
Xcode make the install take a while. At the end it lists what's left to do by
hand and offers to open each app in turn.

The bootstrap script installs Homebrew (which brings Apple's command-line
tools and git), clones this repo to `~/Developer/mac-setup`, and runs
`setup.sh`. From then on, run `setup.sh` from there:

```sh
cd ~/Developer/mac-setup
./setup.sh                  # every step
./setup.sh docker xcode     # only these steps
./setup.sh --dry-run        # show what would change, change nothing
./setup.sh --help
```

If a step fails, the others still run, and the summary tells you which steps
to re-run once you've fixed the problem.

## What it does

| Step | What it does |
|---|---|
| `homebrew` | Installs Rosetta and Homebrew |
| `github` | Creates `~/.ssh/id_ed25519` (no passphrase), signs in to the GitHub CLI, adds the key to your GitHub account, and switches this repo's remote to SSH |
| `packages` | Installs everything in the [`Brewfile`](Brewfile) |
| `macos` | Sets the computer name, turns on Touch ID for `sudo`, and turns on fast user switching, creates `~/Projects` and adds it to Finder's sidebar, and applies Finder, Dock, Spaces, screenshot and typing settings ([`scripts/steps/macos.sh`](scripts/steps/macos.sh)) |
| `dotfiles` | Links every file in [`home/`](home) into your home folder and writes your git name and email to `~/.gitconfig` |
| `languages` | Installs Node, Python, Java, Go, Rust and the AWS CDK with [mise](https://mise.jdx.dev), at the versions in [`home/.config/mise/config.toml`](home/.config/mise/config.toml) |
| `docker` | Creates a Colima VM sized to half the Mac's CPUs and memory, sets it to start at login, and points Docker at Homebrew's compose and buildx plugins |
| `xcode` | Makes Xcode the active developer directory, accepts its license, finishes its first launch, and downloads the iOS simulator |
| `checklist` | Lists the sign-ins and permissions you have to do by hand, and offers to open each app |

### Apps and tools

The [`Brewfile`](Brewfile) is the full list. In short:

- **Development:** Ghostty, VS Code, Sublime Text, Claude and Claude Code,
  git, GitHub CLI, mise, uv, pnpm, Task, Docker CLI with Colima
- **AWS:** AWS CLI, SAM CLI, CDK, Session Manager plugin, envhaul
- **Mobile:** Xcode, Android Studio, Java 17 (Zulu), CocoaPods, Watchman
- **Shell:** starship prompt, zsh autosuggestions and syntax highlighting,
  ripgrep, fd, fzf, bat, eza, zoxide, jq, yq, btop, direnv and more
- **Work:** Microsoft 365 with Teams, Slack, Zoom, 1Password and its CLI,
  Todoist, Jump Desktop, Brave, Chrome
- **Media:** Adobe Creative Cloud, DaVinci Resolve, Screenflick, Elgato
  Control Center and Camera Hub
- **Everything else:** Raycast, Bartender, OpenLogi, Logos, Spotify

## What you still do by hand

macOS and these apps don't allow the rest to be scripted:

- **Sign-ins and licenses:** App Store (before you start), 1Password,
  Microsoft 365, Adobe, Claude, Jump Desktop, Slack, Zoom, Bartender,
  Screenflick and the rest. `./setup.sh checklist` walks through them.
- **Adobe apps:** Homebrew installs the Creative Cloud app. Install
  Photoshop, Premiere Pro and the others from inside it.
- **Privacy permissions:** apps ask for Screen Recording, Accessibility,
  Camera and Microphone the first time they need them, and macOS only lets
  you grant those by clicking.
- **App Store apps:** `mas` can install only apps already on your Apple ID;
  it can't buy them.

## Making changes

- **Add an app or tool:** add a line to the `Brewfile`, then run
  `./setup.sh packages`. Use the Brewfile rather than `brew install`, so the
  next Mac gets it too. `brew bundle cleanup --file Brewfile` lists anything
  installed that isn't in the Brewfile.
- **Change a config file:** the files in your home folder that came from
  `home/` are links into this repo, so editing either one edits the other.
  Commit the change.
- **Add a config file:** put it under `home/` at the same path it should have
  in your home folder, then run `./setup.sh dotfiles`. If a file was already
  there, it's moved to `~/.mac-setup-backup/` first, never deleted.
- **Settings for one Mac only:** put them in `~/.zshrc.local` and
  `~/.gitconfig`, which aren't in this repo.
- **Change a language version:** edit `home/.config/mise/config.toml`, then
  run `mise install`.
- **Android builds:** mise makes Java 25 the default. React Native's Android
  build expects Java 17, so add `java = "zulu-17"` to the project's
  `mise.toml`. Builds inside Android Studio use its own bundled Java.
- **Change your answers:** edit `~/.config/mac-setup/answers.sh`.

## Repository layout

```
bootstrap.sh            first command on a new Mac
setup.sh                runs the steps
Brewfile                apps and tools
scripts/lib.sh          helpers shared by the steps
scripts/steps/          one file per step
home/                   config files linked into ~
.github/                CI that checks the scripts and the Brewfile
```

## Testing

GitHub Actions checks every push:

- ShellCheck on every script, and a syntax check of the zsh config
- Every Brewfile entry still exists and isn't deprecated or disabled; this
  also runs weekly to catch apps that are renamed or removed
- On a macOS runner: a dry run of every step, a real run of the `macos` and
  `dotfiles` steps, and a second run to confirm it changes nothing

The scripts are written for the bash 3.2 that ships with macOS, so they run
before anything else is installed.

## Security notes

- `bootstrap.sh` runs Homebrew's official installer from GitHub, and
  `brew bundle` installs software from Homebrew and the App Store. Review the
  scripts before running them.
- The SSH key has no passphrase, so anyone who can use your Mac account can
  use the key. FileVault protects it while the Mac is off or locked.
- Nothing secret is stored in this repo. Your git name and email go to
  `~/.gitconfig` and `~/.config/mac-setup/answers.sh` on the Mac.
