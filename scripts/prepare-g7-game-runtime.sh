#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
runtime_ref="${repo_root}/ref/upstream/Wiicompiled/runtime"
translation_root="${1:-${repo_root}/private/g6-real-translation}"
runtime_source="${2:-${repo_root}/build/g7-game-runtime-source}"
runtime_build="${3:-${repo_root}/build/g7-game-runtime-build}"
dawn_archive="${repo_root}/build/dependency-cache/dawn-darwin-arm64-v20260603.191052.tar.gz"
sse2neon_url="https://raw.githubusercontent.com/DLTcollab/sse2neon/13a42df35dc7fcc94f987568e7274a998bb6cc86/sse2neon.h"
sse2neon_sha256="44b9fa3dec3a52ea473246e04b9f692a4e5b0ed654299eef7fe7ec3049e223e0"

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
  echo "ERROR: the G7 game-runtime spike requires arm64 macOS" >&2
  exit 1
fi
if [[ ! -f "${translation_root}/build_shards/shards.cmake" ]]; then
  echo "ERROR: missing real-title translation: ${translation_root}" >&2
  exit 1
fi
if [[ ! -f "${dawn_archive}" ]]; then
  echo "ERROR: missing pinned Dawn archive: ${dawn_archive}" >&2
  exit 1
fi
if [[ -e "${runtime_source}" || -e "${runtime_build}" ]]; then
  echo "ERROR: output already exists; choose fresh output paths" >&2
  exit 1
fi

mkdir -p "$(dirname "${runtime_source}")"
cp -R "${runtime_ref}" "${runtime_source}"
patch -p1 -d "${runtime_source}" < "${repo_root}/patches/wiicompiled-apple-runtime.patch"

mkdir -p "${runtime_source}/third_party/sse2neon"
curl --fail --location --silent --show-error \
  "${sse2neon_url}" -o "${runtime_source}/third_party/sse2neon/sse2neon.h"
actual_sse2neon_sha256="$(shasum -a 256 "${runtime_source}/third_party/sse2neon/sse2neon.h" | awk '{print $1}')"
if [[ "${actual_sse2neon_sha256}" != "${sse2neon_sha256}" ]]; then
  echo "ERROR: sse2neon hash mismatch: ${actual_sse2neon_sha256}" >&2
  exit 1
fi

# Mach-O C symbols have a leading underscore. The translator's assembly blob
# labels are emitted in ELF/COFF spelling, so publish both spellings without
# changing the bytes or the generated C++ graph.
blob_asm="${translation_root}/data_sections_init_blobs.S"
if [[ -f "${blob_asm}" ]] && ! rg -q '^\.globl _kData_' "${blob_asm}"; then
  perl -0pi -e 's/^\.globl (kData_[^\n]+)\n\1:/\.globl $1\n.globl _$1\n$1:\n_$1:/mg' "${blob_asm}"
fi

generated_link="${repo_root}/build/generated"
if [[ -e "${generated_link}" || -L "${generated_link}" ]]; then
  echo "ERROR: generated link already exists: ${generated_link}" >&2
  exit 1
fi
ln -s "${translation_root}" "${generated_link}"

cmake -S "${runtime_source}" -B "${runtime_build}" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
  -DMKW_AURORA_DIR="${repo_root}/ref/upstream/Wiicompiled/aurora-main" \
  -DAURORA_DAWN_PACKAGE_URL="file://${dawn_archive}" \
  -DMKW_TRANSLATED_SHARD_MANIFEST="${translation_root}/build_shards/shards.cmake" \
  -DMKW_TRANSLATED_COMPILE_JOBS=2
cmake --build "${runtime_build}" --target WiiCompiled --parallel 4

echo "Built translated Mario Kart Wii runtime: ${runtime_build}/WiiCompiled"
