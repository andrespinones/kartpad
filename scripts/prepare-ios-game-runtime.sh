#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
absolute_from_repo() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s/%s\n' "${repo_root}" "$1" ;;
  esac
}

translation_root="$(absolute_from_repo "${1:-private/g8-full-translation}")"
runtime_source="$(absolute_from_repo "${2:-build/g14-ios-game-runtime-source}")"
runtime_build="$(absolute_from_repo "${3:-build/g14-ios-game-runtime-build}")"
runtime_ref="${repo_root}/ref/upstream/Wiicompiled/runtime"
dawn_archive="${repo_root}/build/dependency-cache/dawn-ios-simulator-arm64-v20260603.191052.tar.gz"
dawn_sha256="c9272faca14a307e4545ea83cb66ab2f65e87fa33a0a687bf5c702666271bc03"
sse2neon_url="https://raw.githubusercontent.com/DLTcollab/sse2neon/13a42df35dc7fcc94f987568e7274a998bb6cc86/sse2neon.h"
sse2neon_sha256="44b9fa3dec3a52ea473246e04b9f692a4e5b0ed654299eef7fe7ec3049e223e0"

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
  echo "ERROR: the iOS game-runtime build requires arm64 macOS" >&2
  exit 1
fi
if [[ ! -f "${translation_root}/build_shards/shards.cmake" ]]; then
  echo "ERROR: missing real-title translation: ${translation_root}" >&2
  exit 1
fi
if [[ -e "${runtime_source}" || -e "${runtime_build}" ]]; then
  echo "ERROR: output already exists; choose fresh output paths" >&2
  exit 1
fi
if [[ ! -f "${dawn_archive}" ]]; then
  echo "ERROR: missing pinned Simulator Dawn archive; run scripts/build-dawn-ios-simulator.sh" >&2
  exit 1
fi
actual_dawn_sha256="$(shasum -a 256 "${dawn_archive}" | awk '{print $1}')"
if [[ "${actual_dawn_sha256}" != "${dawn_sha256}" ]]; then
  echo "ERROR: Simulator Dawn hash mismatch: ${actual_dawn_sha256}" >&2
  exit 1
fi

mkdir -p "$(dirname "${runtime_source}")"
cp -R "${runtime_ref}" "${runtime_source}"
# Keep the immutable pinned Aurora checkout untouched. The iOS product builds
# against this disposable copy so its opaque letterbox fix is reproducible.
cp -R "${repo_root}/ref/upstream/Wiicompiled/aurora-main" \
  "${runtime_source}/aurora-main"
patch --batch -p1 -d "${runtime_source}/aurora-main" < \
  "${repo_root}/patches/aurora-ios-opaque-letterbox.patch"
patch --batch -p1 -d "${runtime_source}" < "${repo_root}/patches/wiicompiled-apple-runtime.patch"
patch --batch -p1 -d "${runtime_source}" < "${repo_root}/patches/wiicompiled-ios-app-integration.patch"
patch --batch -p1 -d "${runtime_source}" < "${repo_root}/patches/wiicompiled-ios-touch-core-buttons.patch"
patch --batch -p1 -d "${runtime_source}" < "${repo_root}/patches/wiicompiled-ios-settings-bridge.patch"
patch --batch -p1 -d "${runtime_source}" < "${repo_root}/patches/wiicompiled-ios-physical-controllers.patch"

mkdir -p "${runtime_source}/third_party/sse2neon"
curl --fail --location --silent --show-error \
  "${sse2neon_url}" -o "${runtime_source}/third_party/sse2neon/sse2neon.h"
actual_sse2neon_sha256="$(shasum -a 256 "${runtime_source}/third_party/sse2neon/sse2neon.h" | awk '{print $1}')"
if [[ "${actual_sse2neon_sha256}" != "${sse2neon_sha256}" ]]; then
  echo "ERROR: sse2neon hash mismatch: ${actual_sse2neon_sha256}" >&2
  exit 1
fi

# Mach-O C symbols have a leading underscore. Publish both spellings for the
# translator's assembly blobs without changing their contents.
blob_asm="${translation_root}/data_sections_init_blobs.S"
if [[ -f "${blob_asm}" ]] && ! rg -q '^\.globl _kData_' "${blob_asm}"; then
  perl -0pi -e 's/^\.globl (kData_[^\n]+)\n\1:/\.globl $1\n.globl _$1\n$1:\n_$1:/mg' "${blob_asm}"
fi

generated_link="${repo_root}/build/generated"
if [[ ! -e "${generated_link}" && ! -L "${generated_link}" ]]; then
  ln -s "${translation_root}" "${generated_link}"
elif [[ ! -L "${generated_link}" ||
        "$(realpath "${generated_link}")" != "$(realpath "${translation_root}")" ]]; then
  echo "ERROR: generated link does not select this translation: ${generated_link}" >&2
  exit 1
fi

cmake -S "${runtime_source}" -B "${runtime_build}" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_SYSTEM_PROCESSOR=arm64 \
  -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
  -DMKW_AURORA_DIR="${runtime_source}/aurora-main" \
  -DAURORA_DAWN_PACKAGE_URL="file://${dawn_archive}" \
  -DMKW_TRANSLATED_SHARD_MANIFEST="${translation_root}/build_shards/shards.cmake" \
  -DMKW_KARTPAD_RUNTIME_INCLUDE="${repo_root}/runtime/include" \
  -DMKW_KARTPAD_REPO_ROOT="${repo_root}" \
  -DMKW_TRANSLATED_COMPILE_JOBS=2
cmake --build "${runtime_build}" --target WiiCompiled --parallel 2

binary="${runtime_build}/KartPad.app/KartPad"
if [[ ! -x "${binary}" ]]; then
  echo "ERROR: missing linked Simulator runtime: ${binary}" >&2
  exit 1
fi
if ! xcrun vtool -show-build "${binary}" | rg -q 'platform IOSSIMULATOR'; then
  echo "ERROR: linked runtime is not an iOS Simulator Mach-O" >&2
  exit 1
fi
if otool -L "${binary}" | rg -q '/opt/homebrew|/usr/local'; then
  echo "ERROR: linked runtime contains a host-only library dependency" >&2
  exit 1
fi

echo "Built full translated iOS Simulator runtime: ${binary}"
shasum -a 256 "${binary}"
