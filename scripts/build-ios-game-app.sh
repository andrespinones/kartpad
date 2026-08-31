#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
absolute_from_repo() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s/%s\n' "${repo_root}" "$1" ;;
  esac
}

runtime_source="$(absolute_from_repo "${1:-build/g14-ios-game-runtime-source}")"
xcode_build="$(absolute_from_repo "${2:-build/g14-ios-game-app-xcode}")"
translation_root="$(absolute_from_repo "${3:-private/g8-full-translation}")"
dawn_archive="${repo_root}/build/dependency-cache/dawn-ios-simulator-arm64-v20260603.191052.tar.gz"
dawn_sha256="c9272faca14a307e4545ea83cb66ab2f65e87fa33a0a687bf5c702666271bc03"
discio_source="${KARTPAD_DISCIO_SOURCE_DIR:-${repo_root}/build/dolphin-ios-discio-iphonesimulator-source}"
discio_build="${KARTPAD_DISCIO_BUILD_DIR:-${repo_root}/build/dolphin-ios-discio-iphonesimulator-build}"

if [[ ! -f "${runtime_source}/CMakeLists.txt" ]] ||
   ! rg -q 'MKW_KARTPAD_REPO_ROOT' "${runtime_source}/cmake/PublicProducts.cmake"; then
  echo "ERROR: prepare the integrated source first with scripts/prepare-ios-game-runtime.sh" >&2
  exit 66
fi
if [[ ! -f "${translation_root}/build_shards/shards.cmake" ]]; then
  echo "ERROR: missing real-title translation: ${translation_root}" >&2
  exit 66
fi
if [[ ! -f "${dawn_archive}" ]] ||
   [[ "$(shasum -a 256 "${dawn_archive}" | awk '{print $1}')" != "${dawn_sha256}" ]]; then
  echo "ERROR: missing or mismatched pinned Simulator Dawn archive" >&2
  exit 66
fi
if [[ ! -f "${discio_source}/Source/Core/DiscIO/DiscExtractor.h" ||
      ! -f "${discio_build}/Source/Core/DiscIO/libdiscio.a" ]]; then
  echo "ERROR: missing iOS Simulator DiscIO dependency" >&2
  exit 66
fi

"${repo_root}/scripts/verify-sunpad-overlay-snapshot.sh"
plutil -lint "${repo_root}/apple/ios/RuntimeInfo.plist" \
  "${repo_root}/apple/ios/PrivacyInfo.xcprivacy" >/dev/null

cmake -S "${runtime_source}" -B "${xcode_build}" -G Xcode \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CONFIGURATION_TYPES=Release \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_SYSTEM_PROCESSOR=arm64 \
  -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
  -DMKW_AURORA_DIR="${runtime_source}/aurora-main" \
  -DAURORA_DAWN_PACKAGE_URL="file://${dawn_archive}" \
  -DAURORA_DAWN_PACKAGE_URL_HASH="SHA256=${dawn_sha256}" \
  -DMKW_TRANSLATED_SHARD_MANIFEST="${translation_root}/build_shards/shards.cmake" \
  -DMKW_KARTPAD_RUNTIME_INCLUDE="${repo_root}/runtime/include" \
  -DMKW_KARTPAD_REPO_ROOT="${repo_root}" \
  -DMKW_KARTPAD_DISCIO_SOURCE_DIR="${discio_source}" \
  -DMKW_KARTPAD_DISCIO_BUILD_DIR="${discio_build}" \
  -DMKW_TRANSLATED_COMPILE_JOBS=2
cmake --build "${xcode_build}" --config Release --target WiiCompiled -- \
  -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO

app="${xcode_build}/Release-iphonesimulator/KartPad.app"
"${repo_root}/scripts/audit-ios-game-app.sh" "${app}"
echo "Built full translated iOS Simulator app: ${app}"
