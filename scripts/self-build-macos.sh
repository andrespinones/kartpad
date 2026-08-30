#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
image="${1:-${repo_root}/ref/Mario Kart Wii.wbfs}"

KARTPAD_DISC_PATH="${image}" "${repo_root}/scripts/verify-sources.sh"
"${repo_root}/scripts/check-repo-safety.sh"
"${repo_root}/scripts/translate-base.sh" "${image}"
"${repo_root}/scripts/build-macos-app.sh"

echo "KartPad macOS self-build complete: ${repo_root}/build/KartPad-self-built.app"
