#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
translation="${1:-${repo_root}/private/self-build/translation}"
runtime_source="${2:-${repo_root}/build/self-build-macos-source}"
runtime_build="${3:-${repo_root}/build/self-build-macos-build}"
app="${4:-${repo_root}/build/KartPad-self-built.app}"

"${repo_root}/scripts/prepare-g7-game-runtime.sh" \
  "${translation}" "${runtime_source}" "${runtime_build}"
"${repo_root}/scripts/package-macos-runtime.sh" "${runtime_build}" "${app}"
"${repo_root}/scripts/audit-macos-package.sh" "${app}"
echo "Built and audited local KartPad app: ${app}"
