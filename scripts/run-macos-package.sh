#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || "$1" != /* || "$1" != *.app ]]; then
  echo "usage: $0 /absolute/path/to/KartPad.app" >&2
  exit 64
fi

repo_root="$(git rev-parse --show-toplevel)"
app="$1"

if [[ ! -d "${app}" ]]; then
  echo "missing macOS app bundle: ${app}" >&2
  exit 66
fi

if pgrep -f '/Contents/MacOS/(WiiCompiled-bin|KartPad)( |$)' >/dev/null ||
   pgrep -if 'Dolphin(\.app)?/Contents/MacOS/Dolphin' >/dev/null; then
  echo "refusing to launch while another KartPad or Dolphin game process is active" >&2
  exit 75
fi

booted_devices="$(xcrun simctl list devices booted)"
if [[ "${booted_devices}" == *"(Booted)"* ]]; then
  echo "refusing to overlap a macOS package run with a booted Simulator" >&2
  printf '%s\n' "${booted_devices}" >&2
  exit 75
fi

"${repo_root}/scripts/audit-macos-package.sh" "${app}"

echo "Launching audited macOS package: ${app}"
open -W "${app}"
echo "macOS package process exited."
