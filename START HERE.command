#!/bin/bash
#
# Double-click this file. It opens Terminal, checks the Mac has what it needs,
# builds Bridge, and tells you what happened in plain words.
#
# It changes nothing outside this folder and installs nothing.

cd "$(dirname "$0")" || exit 1

bold=$'\033[1m'; green=$'\033[32m'; red=$'\033[31m'; amber=$'\033[33m'; off=$'\033[0m'
say()  { printf '%s\n' "$*"; }
ok()   { printf '%s✓%s %s\n' "$green" "$off" "$*"; }
bad()  { printf '%s✗%s %s\n' "$red" "$off" "$*"; }
warn() { printf '%s!%s %s\n' "$amber" "$off" "$*"; }
rule() { printf '%s\n' "────────────────────────────────────────────────────────"; }

clear
say "${bold}Bridge · setting up on this Mac${off}"
rule
say

# ---- 1. macOS version -------------------------------------------------------
major=$(sw_vers -productVersion | cut -d. -f1)
if [ "$major" -lt 14 ]; then
  bad "This Mac runs macOS $(sw_vers -productVersion). Bridge needs macOS 14 (Sonoma) or newer."
  say "  Apple menu → System Settings → General → Software Update."
  say; read -r -p "Press return to close. " _; exit 1
fi
ok "macOS $(sw_vers -productVersion)"

# ---- 2. Xcode ---------------------------------------------------------------
# The full Xcode app, not just the Command Line Tools. Swift's package manager
# needs the SDK that only the full app carries.
if [ ! -d "/Applications/Xcode.app" ]; then
  bad "Xcode is not installed."
  say
  say "  Bridge needs the full ${bold}Xcode${off} app — not 'Command Line Tools'."
  say
  say "  1. Open the ${bold}App Store${off} (blue 'A' icon in your Dock or Applications)."
  say "  2. Search for ${bold}Xcode${off}."
  say "  3. Click Get, then Install. It is about 7 GB, so allow 20–40 minutes."
  say "  4. Open Xcode once when it finishes and accept the licence."
  say "  5. Come back and double-click this file again."
  say; read -r -p "Press return to close. " _; exit 1
fi
ok "Xcode is installed"

# Point the tools at the full Xcode if they are aimed at the Command Line Tools.
current=$(xcode-select -p 2>/dev/null)
if [ "$current" != "/Applications/Xcode.app/Contents/Developer" ]; then
  warn "The developer tools point at: ${current:-nothing}"
  say "  Bridge needs them pointed at Xcode. This asks for your password once."
  say
  if sudo xcode-select -s /Applications/Xcode.app/Contents/Developer 2>/dev/null; then
    ok "Pointed at Xcode"
  else
    bad "Could not change it."
    say "  Run this yourself, then try again:"
    say "    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    say; read -r -p "Press return to close. " _; exit 1
  fi
fi

# Licence acceptance blocks every build with an unhelpful error otherwise.
if ! xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
  warn "Xcode needs to finish its first-run setup. This asks for your password."
  sudo xcodebuild -runFirstLaunch 2>/dev/null || true
fi

swiftver=$(swift --version 2>/dev/null | head -1)
if [ -z "$swiftver" ]; then
  bad "Swift is not answering. Open Xcode once, accept the licence, then try again."
  say; read -r -p "Press return to close. " _; exit 1
fi
ok "${swiftver}"

say
rule
say "${bold}Building Bridge. First time takes a few minutes.${off}"
rule
say

# ---- 3. Build ---------------------------------------------------------------
logfile="build-log.txt"
if swift build --package-path Bridge 2>&1 | tee "$logfile"; then
  say
  ok "${bold}It builds.${off}"
  say
  say "Now the tests:"
  say
  swift test --package-path Bridge 2>&1 | tail -30
else
  errors=$(grep -c "error:" "$logfile" 2>/dev/null); errors=${errors:-0}
  say
  warn "${bold}It did not build yet — ${errors} error(s).${off}"
  say
  say "  This is expected. None of this code has met a compiler before."
  say "  The full list is saved in:  ${bold}build-log.txt${off}"
  say
  say "  ${bold}Send me that file and I will fix them.${off}"
  say
  say "  The first few:"
  grep "error:" "$logfile" 2>/dev/null | head -5 | sed 's/^/    /'
fi

# ---- 4. Open it -------------------------------------------------------------
say
rule
say
say "Opening the project in Xcode now."
say "If Xcode asks about trusting the folder, choose ${bold}Trust${off}."
open Bridge/Package.swift
say
say "In Xcode:  ${bold}⌘B${off} builds   ${bold}⌘U${off} runs the tests"
say
read -r -p "Press return to close this window. " _
