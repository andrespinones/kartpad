#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
image="${1:-${repo_root}/ref/Mario Kart Wii.wbfs}"

KARTPAD_DISC_PATH="${image}" "${repo_root}/scripts/verify-sources.sh"
"${repo_root}/scripts/check-repo-safety.sh"
"${repo_root}/scripts/translate-base.sh" "${image}"
"${repo_root}/scripts/build-macos-app.sh"

app="${repo_root}/build/KartPad-self-built.app"
prepared_data="${repo_root}/private/self-build/disc"
KARTPAD_SELF_BUILD_GAME_DATA_ROOT="${prepared_data}" \
  "${app}/Contents/MacOS/KartPad"

config="${HOME}/Library/Application Support/KartPad/Config.toml"
expected_setting="dvd_root = \"${prepared_data}\""
if [[ ! -f "${config}" ]] || ! rg -F -q "${expected_setting}" "${config}"; then
  echo "ERROR: self-build did not configure the validated game-data root" >&2
  exit 70
fi

echo "KartPad macOS self-build complete and configured: ${app}"
