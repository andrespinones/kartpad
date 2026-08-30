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
  'int main() { std::cout << RuntimeConfigFile::ApplicationDataDirectory().string(); }' | \
  "${CXX:-clang++}" -std=c++20 -Wno-deprecated-literal-operator -x c++ - \
    -I "${runtime_source}/include" -I "${toml_include}" -o "${probe_root}/bin/probe"

installed_result="$(env HOME="${probe_root}/fake-home" "${probe_root}/bin/probe")"
expected_installed="${probe_root}/fake-home/Library/Application Support/KartPad"
if [[ "${installed_result}" != "${expected_installed}" ]]; then
  echo "installed layout mismatch: ${installed_result}" >&2
  exit 1
fi

touch "${probe_root}/portable.txt"
portable_result="$(env HOME="${probe_root}/fake-home" "${probe_root}/bin/probe")"
expected_portable="${probe_root}/UserData"
if [[ "${portable_result}" != "${expected_portable}" ]]; then
  echo "portable layout mismatch: ${portable_result}" >&2
  exit 1
fi

echo "Runtime storage-layout contract passed."
echo "Installed: ${installed_result}"
echo "Portable: ${portable_result}"
