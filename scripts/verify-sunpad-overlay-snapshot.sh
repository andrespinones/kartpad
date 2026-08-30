#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
snapshot="${repo_root}/apple/third_party/sunpad"
reference="${repo_root}/ref/sunpad"

files=(
  "apple/ios/SunPadGameOverlay.h"
  "apple/ios/SunPadGameOverlay.mm"
  "apple/shared/SunPadInputState.h"
  "apple/shared/SunPadInputMixer.h"
  "apple/shared/SunPadInputMixer.mm"
  "apple/shared/SunPadSettings.h"
  "apple/shared/SunPadSettings.mm"
)

for upstream in "${files[@]}"; do
  name="$(basename "${upstream}")"
  cmp "${reference}/${upstream}" "${snapshot}/${name}"
done

expected_commit="e43f0ea6b797e5110787171957c9dc3c6213269c"
actual_commit="$(git -C "${reference}" rev-parse HEAD)"
if [[ "${actual_commit}" != "${expected_commit}" ]]; then
  echo "SunPad reference moved: expected ${expected_commit}, found ${actual_commit}" >&2
  exit 65
fi

cmp "${reference}/LICENSE" "${repo_root}/LICENSES/GPL-3.0.txt"
echo "SunPad overlay snapshot is byte-identical at ${expected_commit}"
