#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="${repo_root}/build/host-portability-arm64"

cmake -S "${repo_root}" -B "${build_dir}" -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
  -DMKW_GUEST_MEMORY_CHECKED=ON \
  -DMKW_GUEST_MEMORY_FLAT=OFF
cmake --build "${build_dir}" --parallel 4
ctest --test-dir "${build_dir}" --output-on-failure

for forbidden in shell32 windowsapp dbghelp user32 winmm ws2_32 iphlpapi secur32 crypt32 setupapi winusb '-march=x86-64'; do
  if rg -F -- "${forbidden}" "${build_dir}/build.ninja" >/dev/null; then
    echo "Forbidden Windows/x86 token in Darwin graph: ${forbidden}" >&2
    exit 1
  fi
done

test -s "${build_dir}/manifest/kartpad-build-manifest.json"
echo "Darwin host graph isolation passed."
