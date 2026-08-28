#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
build_dir="${repo_root}/build/g7-aurora-host-frame"
capture_path="${build_dir}/g7-aurora-host-frame.bmp"
dawn_archive="${repo_root}/build/dependency-cache/dawn-darwin-arm64-v20260603.191052.tar.gz"

cmake_args=(
  -S "${repo_root}"
  -B "${build_dir}"
  -G Ninja
  -DCMAKE_BUILD_TYPE=RelWithDebInfo
  -DCMAKE_OSX_ARCHITECTURES=arm64
  -DMKW_BUILD_AURORA_G7_FIXTURES=ON
)
if [[ -f "${dawn_archive}" ]]; then
  cmake_args+=("-DAURORA_DAWN_PACKAGE_URL=file://${dawn_archive}")
fi

cmake "${cmake_args[@]}"
cmake --build "${build_dir}" --target kartpad_g7_aurora_host_frame --parallel 4
rm -f "${capture_path}"
"${build_dir}/kartpad_g7_aurora_host_frame" "${capture_path}"
test -s "${capture_path}"
sips -g pixelWidth -g pixelHeight "${capture_path}"

pixel_offset="$(od -An -tu4 -j 10 -N 4 "${capture_path}" | tr -d '[:space:]')"
width="$(od -An -tu4 -j 18 -N 4 "${capture_path}" | tr -d '[:space:]')"
height="$(od -An -tu4 -j 22 -N 4 "${capture_path}" | tr -d '[:space:]')"
file_size="$(stat -f '%z' "${capture_path}")"
first_pixel="$(od -An -tx1 -v -j "${pixel_offset}" -N 4 "${capture_path}" | tr -d '[:space:]')"
last_pixel="$(od -An -tx1 -v -j "$((file_size - 4))" -N 4 "${capture_path}" | tr -d '[:space:]')"
if (( width == 0 || height == 0 )); then
  echo "ERROR: Aurora capture has invalid dimensions ${width}x${height}" >&2
  exit 1
fi
if [[ "${first_pixel}" != "563412ff" || "${last_pixel}" != "563412ff" ]]; then
  echo "ERROR: expected #123456ff corner pixels, got ${first_pixel}/${last_pixel}" >&2
  exit 1
fi
echo "Validated Aurora/Dawn Metal readback: ${width}x${height}, corner BGRA=563412ff"
shasum -a 256 "${capture_path}"
