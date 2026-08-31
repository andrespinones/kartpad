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
xcode_build="$(absolute_from_repo "${2:-build/g14-ios-device-game-app-xcode}")"
translation_root="$(absolute_from_repo "${3:-private/g8-full-translation}")"
dawn_archive="${repo_root}/build/dependency-cache/dawn-ios-arm64-v20260603.191052.tar.gz"
dawn_sha256="a361fcca75929fa5c766cfcde979c010a6da7d805e5db8e15c75e73fd8260e78"
discio_source="${KARTPAD_DISCIO_SOURCE_DIR:-${repo_root}/build/dolphin-ios-discio-iphoneos-source}"
discio_build="${KARTPAD_DISCIO_BUILD_DIR:-${repo_root}/build/dolphin-ios-discio-iphoneos-build}"
app="${xcode_build}/Release-iphoneos/KartPad.app"

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
  echo "ERROR: missing or mismatched pinned physical-iOS Dawn archive" >&2
  exit 66
fi
if [[ ! -f "${discio_source}/Source/Core/DiscIO/DiscExtractor.h" ||
      ! -f "${discio_build}/Source/Core/DiscIO/libdiscio.a" ]]; then
  echo "ERROR: missing physical-iOS DiscIO dependency" >&2
  exit 66
fi

generated_link="${repo_root}/build/generated"
if [[ -e "${generated_link}" && ! -L "${generated_link}" ]]; then
  echo "ERROR: generated path exists and is not a symlink: ${generated_link}" >&2
  exit 73
fi
previous_generated_target=""
if [[ -L "${generated_link}" ]]; then
  previous_generated_target="$(readlink "${generated_link}")"
fi
restore_generated_link() {
  if [[ -n "${previous_generated_target}" ]]; then
    ln -sfn "${previous_generated_target}" "${generated_link}"
  elif [[ -L "${generated_link}" ]]; then
    rm "${generated_link}"
  fi
}
trap restore_generated_link EXIT
ln -sfn "${translation_root}" "${generated_link}"

"${repo_root}/scripts/verify-sunpad-overlay-snapshot.sh"
plutil -lint "${repo_root}/apple/ios/RuntimeInfo.plist" \
  "${repo_root}/apple/ios/PrivacyInfo.xcprivacy" >/dev/null

# A prior device deployment may have signed this reusable build product in
# place. Remove only that generated signing residue before the unsigned build
# so the privacy audit cannot inspect a stale profile from an older install.
rm -f "${app}/embedded.mobileprovision"
if [[ -d "${app}/_CodeSignature" ]]; then
  rm -r "${app}/_CodeSignature"
fi

cmake -S "${runtime_source}" -B "${xcode_build}" -G Xcode \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CONFIGURATION_TYPES=Release \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_SYSTEM_PROCESSOR=arm64 \
  -DCMAKE_OSX_SYSROOT=iphoneos \
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
  -sdk iphoneos CODE_SIGNING_ALLOWED=NO

"${repo_root}/scripts/audit-ios-game-app.sh" "${app}" IOS
echo "Built full translated physical-iOS game app: ${app}"
