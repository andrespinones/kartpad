#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || "$1" != /* || "$1" != *.app ]]; then
  echo "usage: $0 /absolute/path/to/KartPad.app" >&2
  exit 64
fi

app="$1"
contents="${app}/Contents"
plist="${contents}/Info.plist"
if [[ ! -d "${app}" || ! -f "${plist}" ]]; then
  echo "not a macOS app bundle: ${app}" >&2
  exit 66
fi

plutil -lint "${plist}" >/dev/null
executable_name="$(plutil -extract CFBundleExecutable raw "${plist}")"
bundle_identifier="$(plutil -extract CFBundleIdentifier raw "${plist}")"
icon_name="$(plutil -extract CFBundleIconFile raw "${plist}")"
executable="${contents}/MacOS/${executable_name}"

test "${bundle_identifier}" = "dev.kartpad.app"
test -x "${executable}"
test -f "${contents}/Resources/${icon_name%.icns}.icns"
test -f "${contents}/MacOS/dsp_coef.bin"
test -f "${contents}/MacOS/initial_pipeline_cache.db"
test -d "${contents}/MacOS/wii_bootstrap/shared2/wc24"
if [[ "$(file -b "${executable}")" != *"Mach-O 64-bit executable arm64"* ]]; then
  echo "main executable is not arm64 Mach-O" >&2
  exit 65
fi
if [[ "$(plutil -extract LSMinimumSystemVersion raw "${plist}")" != "14.0" ]] ||
   [[ "$(vtool -show-build "${executable}" | awk '/minos/{print $2; exit}')" != "14.0" ]]; then
  echo "bundle or executable deployment target is not macOS 14.0" >&2
  exit 65
fi

for forbidden in portable.txt UserData Config.toml '*.wbfs' '*.iso' '*.rvz' '*.wia' '*.gcz'; do
  if find "${app}" -name "${forbidden}" -print -quit | rg -q .; then
    echo "package contains forbidden private or writable state: ${forbidden}" >&2
    exit 70
  fi
done

while IFS= read -r macho; do
  while IFS= read -r dependency; do
    case "${dependency}" in
      /System/Library/*|/usr/lib/*) ;;
      @rpath/*)
        test -f "${contents}/Frameworks/${dependency##*/}"
        ;;
      *)
        echo "non-portable dependency ${dependency} in ${macho}" >&2
        exit 69
        ;;
    esac
  done < <(otool -L "${macho}" | tail -n +2 | awk '{print $1}')
done < <(find "${contents}/MacOS" "${contents}/Frameworks" -type f -perm -111 -print)

if find "${contents}/MacOS" "${contents}/Frameworks" -type f -perm -111 -print0 | \
  xargs -0 strings | rg -F -q "${HOME}/"; then
  echo "package embeds the builder's home-directory path" >&2
  exit 70
fi

codesign --verify --deep --strict --verbose=2 "${app}"
app_hash="$(find "${app}" -type f -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256 | awk '{print $1}')"
echo "macOS package audit passed: ${app}"
echo "Bundle content hash: ${app_hash}"
