#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
normal_build="${repo_root}/build/guest-memory-arm64"
sanitized_build="${repo_root}/build/guest-memory-sanitized-arm64"

cmake -S "${repo_root}" -B "${normal_build}" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
  -DMKW_GUEST_MEMORY_CHECKED=ON \
  -DMKW_GUEST_MEMORY_FLAT=OFF
cmake --build "${normal_build}" --target kartpad_checked_memory_tests kartpad_darwin_vm_probe --parallel 4
ctest --test-dir "${normal_build}" -R '^kartpad.memory.(checked|darwin-vm-probe)$' --output-on-failure

cmake -S "${repo_root}" -B "${sanitized_build}" -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
  -DMKW_GUEST_MEMORY_CHECKED=ON \
  -DMKW_GUEST_MEMORY_FLAT=OFF \
  -DCMAKE_CXX_FLAGS='-fsanitize=address,undefined -fno-omit-frame-pointer' \
  -DCMAKE_EXE_LINKER_FLAGS='-fsanitize=address,undefined'
cmake --build "${sanitized_build}" --target kartpad_checked_memory_tests --parallel 4
ctest --test-dir "${sanitized_build}" -R '^kartpad.memory.checked$' --output-on-failure
