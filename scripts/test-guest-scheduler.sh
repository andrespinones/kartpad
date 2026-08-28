#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="${repo_root}/build/guest-scheduler-arm64"
sanitized_dir="${repo_root}/build/guest-scheduler-sanitized-arm64"

cmake -S "${repo_root}" -B "${build_dir}" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0
cmake --build "${build_dir}" --target kartpad_scheduler_tests --parallel 4
ctest --test-dir "${build_dir}" -R '^kartpad.scheduler.portable$' --output-on-failure

cmake -S "${repo_root}" -B "${sanitized_dir}" -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
  -DCMAKE_CXX_FLAGS='-fsanitize=address,undefined -fno-omit-frame-pointer' \
  -DCMAKE_EXE_LINKER_FLAGS='-fsanitize=address,undefined'
cmake --build "${sanitized_dir}" --target kartpad_scheduler_tests --parallel 4
ctest --test-dir "${sanitized_dir}" -R '^kartpad.scheduler.portable$' --output-on-failure
