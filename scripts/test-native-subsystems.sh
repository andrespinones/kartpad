#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="${repo_root}/build/native-subsystems-arm64"

cmake -S "${repo_root}" -B "${build_dir}" -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0
cmake --build "${build_dir}" --target kartpad_apple_subsystem_smoke --parallel 4
MTL_DEBUG_LAYER=1 "${build_dir}/kartpad_apple_subsystem_smoke"
