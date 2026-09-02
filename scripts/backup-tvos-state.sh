#!/usr/bin/env bash
set -euo pipefail

if [[ $# != 2 || "$2" != /* ]]; then
  echo "usage: $0 <Apple-TV-device> /absolute/path/to/empty-backup-directory" >&2
  exit 64
fi
device="$1"
destination="$2"
if [[ -e "${destination}" ]]; then
  echo "ERROR: backup destination already exists: ${destination}" >&2
  exit 73
fi
mkdir -p "${destination}"
xcrun devicectl device copy from --device "${device}" \
  --source "Library/Application Support/KartPad" \
  --destination "${destination}" \
  --domain-type appDataContainer \
  --domain-identifier dev.kartpad.tv
echo "Backed up KartPad tvOS state to ${destination}."
