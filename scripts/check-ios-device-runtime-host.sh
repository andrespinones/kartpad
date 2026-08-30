#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
xcode_build="${1:-${repo_root}/build/g14-ios-game-app-xcode}"
output_dir="${2:-${repo_root}/build/ios-device-runtime-host-check}"

if [[ "${xcode_build}" != /* || "${output_dir}" != /* ]]; then
  echo "usage: $0 /absolute/simulator-xcode-build [/absolute/output-dir]" >&2
  exit 64
fi

response_root="${xcode_build}/build/WiiCompiled.build/Release-iphonesimulator/Objects-normal/arm64"
if [[ ! -d "${response_root}" ]]; then
  echo "missing full-game Simulator compile arguments: ${response_root}" >&2
  exit 66
fi

response_files=()
while IFS= read -r response_file; do
  if rg -q 'OBJC_OLD_DISPATCH_PROTOTYPES' "${response_file}"; then
    response_files+=("${response_file}")
  fi
done < <(rg --files "${response_root}" | rg 'common-args\.resp$')
if [[ "${#response_files[@]}" -ne 1 ]]; then
  echo "expected one WiiCompiled Objective-C++ response file, found ${#response_files[@]}" >&2
  exit 66
fi

mkdir -p "${output_dir}"
object="${output_dir}/KartPadRuntimeOverlayHost.o"
sdk_path="$(xcrun --sdk iphoneos --show-sdk-path)"

xcrun --sdk iphoneos clang++ \
  -x objective-c++ \
  -target arm64-apple-ios16.0 \
  -isysroot "${sdk_path}" \
  -fobjc-arc \
  @"${response_files[0]}" \
  -c "${repo_root}/apple/ios/KartPadRuntimeOverlayHost.mm" \
  -o "${object}"

build_metadata="$(xcrun vtool -show-build "${object}")"
if [[ "$(awk '/platform/{print $2; exit}' <<<"${build_metadata}")" != "IOS" ]] ||
   [[ "$(awk '/minos/{print $2; exit}' <<<"${build_metadata}")" != "16.0" ]]; then
  echo "runtime host check did not produce an IOS 16.0 object" >&2
  exit 65
fi

for simulator_only_contract in \
  'KARTPAD_IMPORT_FORCE_SWAP_FAILURE' \
  'KARTPAD_TOUCH_HOLD_SELF_TEST' \
  'KARTPAD_TOUCH_INPUT_SELF_TEST'; do
  if strings "${object}" | rg -q "${simulator_only_contract}"; then
    echo "physical-iOS object contains Simulator-only contract: ${simulator_only_contract}" >&2
    exit 69
  fi
done

echo "physical-iOS runtime host compile passed: ${object}"
shasum -a 256 "${object}"
