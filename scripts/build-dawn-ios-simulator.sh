#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
dawn_commit="13abc3bc8ea2d3c2050f9e77a12d012108ceee24"
dawn_source_sha256="713bea5b92d4f6c5175752fd7cbf1c3c5ce36598ff5dd98685d8a1216614ebba"
source_archive="${repo_root}/build/dependency-cache/dawn-${dawn_commit}.tar.gz"
absolute_from_repo() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s/%s\n' "${repo_root}" "$1" ;;
  esac
}

source_dir="$(absolute_from_repo "${1:-build/dawn-ios-simulator-source}")"
host_build_dir="$(absolute_from_repo "${2:-build/dawn-host-protoc-build}")"
simulator_build_dir="$(absolute_from_repo "${3:-build/dawn-ios-simulator-build}")"
install_dir="$(absolute_from_repo "${4:-build/dawn-ios-simulator-install}")"
package_path="$(absolute_from_repo "${5:-build/dependency-cache/dawn-ios-simulator-arm64-v20260603.191052.tar.gz}")"

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
  echo "ERROR: Dawn's iOS Simulator package requires arm64 macOS" >&2
  exit 1
fi

mkdir -p "$(dirname "${source_archive}")"
if [[ ! -f "${source_archive}" ]]; then
  curl --fail --location --silent --show-error \
    "https://github.com/google/dawn/archive/${dawn_commit}.tar.gz" \
    -o "${source_archive}"
fi
actual_source_sha256="$(shasum -a 256 "${source_archive}" | awk '{print $1}')"
if [[ "${actual_source_sha256}" != "${dawn_source_sha256}" ]]; then
  echo "ERROR: Dawn source archive hash mismatch: ${actual_source_sha256}" >&2
  exit 1
fi

if [[ ! -e "${source_dir}" ]]; then
  mkdir -p "${source_dir}"
  tar -xzf "${source_archive}" --strip-components=1 -C "${source_dir}"
fi
if [[ ! -f "${source_dir}/CMakeLists.txt" ]]; then
  echo "ERROR: incomplete Dawn source directory: ${source_dir}" >&2
  exit 1
fi

if [[ ! -x "${host_build_dir}/protoc" ]]; then
  cmake -S "${source_dir}" -B "${host_build_dir}" -G Ninja \
    -C "${source_dir}/.github/workflows/dawn-ci.cmake" \
    -C "${repo_root}/cmake/dawn-kartpad-ci.cmake" \
    -DCMAKE_BUILD_TYPE=Release
  cmake --build "${host_build_dir}" --target protoc --parallel 4
fi

cmake -S "${source_dir}" -B "${simulator_build_dir}" -G Ninja \
  -C "${source_dir}/.github/workflows/dawn-ci.cmake" \
  -C "${repo_root}/cmake/dawn-kartpad-ci.cmake" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
  -DCMAKE_SYSTEM_PROCESSOR=arm64 \
  -DWITH_PROTOC="${host_build_dir}/protoc"
cmake --build "${simulator_build_dir}" --parallel 4
cmake --install "${simulator_build_dir}" --prefix "${install_dir}"

if [[ ! -f "${install_dir}/lib/libwebgpu_dawn.a" ||
      ! -f "${install_dir}/lib/cmake/Dawn/DawnConfig.cmake" ]]; then
  echo "ERROR: Dawn Simulator install tree is incomplete" >&2
  exit 1
fi

# CMake's install-time ranlib refreshes the archive symbol table with a wall
# clock timestamp. Re-index it in Apple's deterministic archive mode before
# hashing or packaging the install tree.
ZERO_AR_DATE=1 ranlib "${install_dir}/lib/libwebgpu_dawn.a"

mkdir -p "$(dirname "${package_path}")"
# Normalize archive metadata and member order so the digest is a durable input
# to Aurora's FetchContent declaration rather than a timestamp from this host.
find "${install_dir}" -exec touch -h -t 198001010000 {} +
(
  cd "${install_dir}"
  find . -print | LC_ALL=C sort |
    COPYFILE_DISABLE=1 tar -cf - --no-recursion --uid 0 --gid 0 \
      --uname root --gname root --format=ustar -T -
) | gzip -n -9 > "${package_path}"
echo "Dawn iOS Simulator package: ${package_path}"
shasum -a 256 "${package_path}"
