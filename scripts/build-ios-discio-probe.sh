#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
absolute_from_repo() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s/%s\n' "${repo_root}" "$1" ;;
  esac
}
source_root="$(absolute_from_repo "${1:-ref/upstream/dolphin}")"
sdk="${4:-iphonesimulator}"
work_source="$(absolute_from_repo "${2:-build/dolphin-ios-discio-${sdk}-source}")"
work_build="$(absolute_from_repo "${3:-build/dolphin-ios-discio-${sdk}-build}")"
path_map_flags="-ffile-prefix-map=${work_source}=Dolphin -fmacro-prefix-map=${work_source}=Dolphin"
resume="${KARTPAD_DISCIO_RESUME:-0}"

if [[ "${resume}" != "0" && "${resume}" != "1" ]]; then
  echo "ERROR: KARTPAD_DISCIO_RESUME must be 0 or 1" >&2
  exit 64
fi

case "${sdk}" in
  iphonesimulator)
    cmake_sysroot=iphonesimulator
    expected_platform=IOSSIMULATOR
    ;;
  iphoneos)
    cmake_sysroot=iphoneos
    expected_platform=IOS
    ;;
  *)
    echo "usage: $0 [source] [work-source] [work-build] [iphonesimulator|iphoneos]" >&2
    exit 64
    ;;
esac

if [[ "$(git -C "${source_root}" rev-parse HEAD^{commit})" != \
      "4f8af23db516d8b6e9cd00e7b261a65b026514a8" ]]; then
  echo "ERROR: Dolphin source is not the pinned KartPad revision" >&2
  exit 65
fi
if [[ -n "$(git -C "${source_root}" status --porcelain)" ]]; then
  echo "ERROR: Dolphin source must be clean" >&2
  exit 65
fi
for required in \
  Externals/bzip2/CMakeLists.txt \
  Externals/curl/curl/CMakeLists.txt \
  Externals/fmt/fmt/CMakeLists.txt \
  Externals/zstd/zstd/build/cmake/CMakeLists.txt; do
  if [[ ! -f "${source_root}/${required}" ]]; then
    echo "ERROR: required Dolphin submodule content is missing: ${required}" >&2
    exit 66
  fi
done
if [[ "${resume}" == "0" && ( -e "${work_source}" || -e "${work_build}" ) ]]; then
  echo "ERROR: work source/build already exists; choose fresh paths" >&2
  exit 73
fi

if [[ "${resume}" == "0" ]]; then
  mkdir -p "$(dirname "${work_source}")" "$(dirname "${work_build}")"
  cp -R "${source_root}" "${work_source}"
  patch --batch -p1 -d "${work_source}" < \
    "${repo_root}/patches/dolphin-ios-discio.patch"
  patch --batch -p1 -d "${work_source}" < \
    "${repo_root}/patches/dolphin-ios-discio-coreless.patch"
  patch --batch -p1 -d "${work_source}/Externals/curl/curl" < \
    "${repo_root}/patches/dolphin-curl-ios-pipe2.patch"
elif [[ ! -f "${work_build}/CMakeCache.txt" ||
        ! -f "${work_source}/Source/Core/Common/FilesystemWatcher_iOS.cpp" ]]; then
  echo "ERROR: DiscIO resume paths are not a configured KartPad worktree" >&2
  exit 66
fi

cmake -S "${work_source}" -B "${work_build}" -G Ninja \
  -DCMAKE_C_FLAGS="${path_map_flags}" \
  -DCMAKE_CXX_FLAGS="${path_map_flags}" \
  -DCMAKE_OBJC_FLAGS="${path_map_flags}" \
  -DCMAKE_OBJCXX_FLAGS="${path_map_flags}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_SYSTEM_PROCESSOR=arm64 \
  -DCMAKE_OSX_SYSROOT="${cmake_sysroot}" \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
  -DCMAKE_C_FLAGS_RELEASE="-O3 -DNDEBUG ${path_map_flags}" \
  -DCMAKE_CXX_FLAGS_RELEASE="-O3 -DNDEBUG ${path_map_flags}" \
  -DCMAKE_OBJCXX_FLAGS_RELEASE="-O3 -DNDEBUG ${path_map_flags}" \
  -DENABLE_QT=OFF \
  -DENABLE_NOGUI=OFF \
  -DENABLE_CLI_TOOL=OFF \
  -DENABLE_TESTS=OFF \
  -DENABLE_VULKAN=OFF \
  -DENABLE_CUBEB=OFF \
  -DENABLE_LLVM=OFF \
  -DENABLE_AUTOUPDATE=OFF \
  -DENABLE_ANALYTICS=OFF \
  -DENABLE_SDL=OFF \
  -DUSE_DISCORD_PRESENCE=OFF \
  -DUSE_MGBA=OFF \
  -DUSE_RETRO_ACHIEVEMENTS=OFF \
  -DUSE_UPNP=OFF \
  -DUSE_SYSTEM_LIBS=OFF \
  -DMACOS_CODE_SIGNING=OFF \
  -DKARTPAD_DISCIO_PROBE_SOURCE="${repo_root}/tests/ios_discio_probe.cpp"
cmake --build "${work_build}" --target kartpad-discio-probe --parallel 2

binary="${work_build}/kartpad-discio-probe.app/kartpad-discio-probe"
if [[ ! -x "${binary}" ]]; then
  echo "ERROR: missing DiscIO probe: ${binary}" >&2
  exit 65
fi
if [[ "$(xcrun vtool -show-build "${binary}" | awk '/platform/{print $2; exit}')" != \
      "${expected_platform}" ]]; then
  echo "ERROR: DiscIO probe has the wrong Apple platform" >&2
  exit 65
fi
if otool -L "${binary}" | rg -q '/opt/homebrew|/usr/local'; then
  echo "ERROR: DiscIO probe contains a host-only dependency" >&2
  exit 65
fi
if rg -a -F -q "${work_source}" "${binary}"; then
  echo "ERROR: DiscIO probe exposes its private build path" >&2
  exit 65
fi

echo "Built clean pinned Dolphin DiscIO probe: ${binary}"
shasum -a 256 "${binary}"
