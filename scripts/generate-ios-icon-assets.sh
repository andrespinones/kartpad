#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
master="${repo_root}/branding/KartPadIcon-k-circuit-ai.png"
app_icon="${repo_root}/apple/ios/Assets.xcassets/AppIcon.appiconset/KartPadIcon-1024.png"

command -v magick >/dev/null 2>&1 || {
  echo 'ImageMagick is required (brew install imagemagick).' >&2
  exit 69
}
[[ -f "${master}" ]] || {
  echo "ERROR: missing K-circuit icon master: ${master}" >&2
  exit 66
}

magick "${master}" \
  -auto-orient \
  -background '#061631' \
  -flatten \
  -resize '1024x1024^' \
  -gravity center \
  -extent 1024x1024 \
  -alpha off \
  -colorspace sRGB \
  -strip \
  -define png:color-type=2 \
  "${app_icon}"

dimensions="$(sips -g pixelWidth -g pixelHeight -g hasAlpha "${app_icon}")"
grep -q 'pixelWidth: 1024' <<<"${dimensions}"
grep -q 'pixelHeight: 1024' <<<"${dimensions}"
grep -q 'hasAlpha: no' <<<"${dimensions}"

echo "Generated universal iOS/iPadOS icon: ${app_icon}"
shasum -a 256 "${app_icon}"
