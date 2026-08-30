#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
runtime_source="${1:-${repo_root}/build/g7-game-runtime-source}"
header="${runtime_source}/include/runtime_config.h"
toml_include="${runtime_source}/third_party/toml11"

if [[ ! -f "${header}" || ! -f "${toml_include}/toml.hpp" ]]; then
  echo "usage: $0 [/absolute/path/to/patched-runtime-source]" >&2
  exit 66
fi

probe_parent="$(mktemp -d)"
trap 'rm -rf "${probe_parent}"' EXIT
probe_root="$(cd "${probe_parent}" && pwd -P)"
mkdir -p "${probe_root}/bin" "${probe_root}/fake-home"

printf '%s\n' \
  '#include "runtime_config.h"' \
  '#include <iostream>' \
  'int main() {' \
  '  std::cout << RuntimeConfigFile::ApplicationDataDirectory().string() << "\n";' \
  '  std::cout << RuntimeConfigFile::CacheDataDirectory().string();' \
  '}' | \
  "${CXX:-clang++}" -std=c++20 -Wno-deprecated-literal-operator -x c++ - \
    -I "${runtime_source}/include" -I "${toml_include}" -o "${probe_root}/bin/probe"

installed_result="$(env HOME="${probe_root}/fake-home" "${probe_root}/bin/probe")"
expected_installed="${probe_root}/fake-home/Library/Application Support/KartPad"
expected_installed_cache="${probe_root}/fake-home/Library/Caches/KartPad"
installed_app_support="$(printf '%s\n' "${installed_result}" | sed -n '1p')"
installed_cache="$(printf '%s\n' "${installed_result}" | sed -n '2p')"
if [[ "${installed_app_support}" != "${expected_installed}" ||
      "${installed_cache}" != "${expected_installed_cache}" ]]; then
  echo "installed layout mismatch" >&2
  exit 1
fi

touch "${probe_root}/portable.txt"
portable_result="$(env HOME="${probe_root}/fake-home" "${probe_root}/bin/probe")"
expected_portable="${probe_root}/UserData"
expected_portable_cache="${probe_root}/UserData/Cache"
portable_app_support="$(printf '%s\n' "${portable_result}" | sed -n '1p')"
portable_cache="$(printf '%s\n' "${portable_result}" | sed -n '2p')"
if [[ "${portable_app_support}" != "${expected_portable}" ||
      "${portable_cache}" != "${expected_portable_cache}" ]]; then
  echo "portable layout mismatch" >&2
  exit 1
fi

echo "Runtime storage-layout contract passed."
echo "Installed durable: ${installed_app_support}"
echo "Installed cache: ${installed_cache}"
echo "Portable durable: ${portable_app_support}"
echo "Portable cache: ${portable_cache}"
