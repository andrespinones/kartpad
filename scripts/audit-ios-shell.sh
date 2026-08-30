#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 || "$1" != /* || "$1" != *.app ]]; then
  echo "usage: $0 /absolute/path/to/KartPad.app [IOSSIMULATOR|IOS]" >&2
  exit 64
fi

app="$1"
expected_platform="${2:-IOSSIMULATOR}"
if [[ "${expected_platform}" != "IOSSIMULATOR" && "${expected_platform}" != "IOS" ]]; then
  echo "expected platform must be IOSSIMULATOR or IOS" >&2
  exit 64
fi
plist="${app}/Info.plist"
binary="${app}/KartPad"

test -d "${app}"
test -x "${binary}"
test -f "${plist}"
test -f "${app}/PrivacyInfo.xcprivacy"
test -f "${app}/Assets.car"
plutil -lint "${plist}" "${app}/PrivacyInfo.xcprivacy" >/dev/null
test "$(plutil -extract CFBundleIdentifier raw "${plist}")" = "dev.kartpad.app"
test "$(plutil -extract MinimumOSVersion raw "${plist}")" = "16.0"

if [[ "$(file -b "${binary}")" != *"Mach-O 64-bit executable arm64"* ]]; then
  echo "Simulator shell is not arm64 Mach-O" >&2
  exit 65
fi
build_metadata="$(vtool -show-build "${binary}")"
if [[ "$(awk '/platform/{print $2; exit}' <<<"${build_metadata}")" != "${expected_platform}" ]] ||
   [[ "$(awk '/minos/{print $2; exit}' <<<"${build_metadata}")" != "16.0" ]]; then
  echo "binary is not an ${expected_platform} 16.0 artifact" >&2
  exit 65
fi

for forbidden in '*.wbfs' '*.iso' '*.rvz' '*.wia' '*.gcz' '*.mobileprovision'; do
  if find "${app}" -name "${forbidden}" -print -quit | rg -q .; then
    echo "Simulator shell contains forbidden private/signing data: ${forbidden}" >&2
    exit 70
  fi
done

while IFS= read -r dependency; do
  case "${dependency}" in
    /System/Library/*|/usr/lib/*) ;;
    *)
      echo "Simulator shell contains non-system dependency: ${dependency}" >&2
      exit 69
      ;;
  esac
done < <(otool -L "${binary}" | tail -n +2 | awk '{print $1}')

if strings "${binary}" | rg -F -q '/Users/'; then
  echo "Simulator shell embeds a builder home path" >&2
  exit 70
fi

if ! nm -gj "${binary}" | rg -q 'KartPadCoreIntegrationSummary' ||
   ! strings "${binary}" | rg -F -q 'KartPad mobile core checks passed' ||
   ! strings "${binary}" | rg -F -q 'translated fixture output mismatch'; then
  echo "Simulator shell does not contain the linked mobile core self-check" >&2
  exit 69
fi

echo "iOS ${expected_platform} shell audit passed: ${app}"
