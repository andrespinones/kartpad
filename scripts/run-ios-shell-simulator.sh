#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 simulator-udid /absolute/path/to/KartPad.app" >&2
  exit 64
fi

udid="$1"
app="$2"
repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

if [[ "${app}" != /* || "${app}" != *.app ]]; then
  echo "app path must be an absolute .app path" >&2
  exit 64
fi
"${repo_root}/scripts/audit-ios-shell.sh" "${app}"

if pgrep -f '/KartPadRuntime.app/Contents/MacOS/WiiCompiled-bin|/KartPad.app/Contents/MacOS/KartPad' >/dev/null; then
  echo "refusing to launch Simulator while the macOS game is running" >&2
  exit 75
fi

booted=()
while IFS= read -r booted_udid; do
  booted[${#booted[@]}]="${booted_udid}"
done < <(xcrun simctl list devices | sed -nE 's/.*\(([0-9A-F-]{36})\) \(Booted\).*/\1/p')
if (( ${#booted[@]} > 1 )); then
  echo "more than one Simulator is already booted" >&2
  exit 75
fi
if (( ${#booted[@]} == 1 )) && [[ "${booted[0]}" != "${udid}" ]]; then
  echo "a different Simulator is already booted: ${booted[0]}" >&2
  exit 75
fi

if ! xcrun simctl list devices available | rg -F -q "(${udid})"; then
  echo "requested Simulator is unavailable: ${udid}" >&2
  exit 66
fi
if (( ${#booted[@]} == 0 )); then
  xcrun simctl boot "${udid}"
  xcrun simctl bootstatus "${udid}" -b
fi

xcrun simctl terminate "${udid}" dev.kartpad.app 2>/dev/null || true
xcrun simctl install "${udid}" "${app}"
xcrun simctl launch --console-pty "${udid}" dev.kartpad.app
