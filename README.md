# mac-setup

This is my setup for a new Mac.  Since I generally upgrade my machine every year, this provides a quicker way to configure the machine to how I work.  

**You cannot use this script directly**.  It references a git repo that is not public.  You can however fork this repo and customize it to your needs.

## Notice

This script uses [Homebrew](https://brew.sh/).  To install Homebrew you run a remote script on your machine.  You should not do this without understanding the security risks of taking this approach.  I have reviewed the code, but you will have to make a decision on whether you agree with the risk associated with this.

## Background

My name is David Tucker, and I am a CTO Consultant and Pluralsight Author.  When I am configuring a Mac, I am going to be using for two different key purposes: software development and media creation.  I need to have a machine that is setup to handle both of those daily tasks.  

## What This Doesn't Do

I truly wish that I could run a script and have my machine completely customized to my needs.  Unfortunately, there are things that are not easy to automate.  For example, interaction with the Mac App Store via CLI is broken in MacOS Monterey (using the [mas cli](https://github.com/mas-cli/mas) tool). Because of this and other reasons, some things need to be done manually.

### Apps to Install

The following applications for me still need to be installed after I run the script:

* BlackMagic Design ATEM Software Control
* Companion
* Davinci Resolve
* Elgato Control Center
* Elgato Stream Deck
* Focusrite Control
* ScanSnap
* Color Snapper 2

## Installation

You can install this on a Mac using the following command:

```
/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/davidtucker/mac-setup/main/install.sh)"
```

