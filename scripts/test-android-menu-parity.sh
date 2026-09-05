#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
# shellcheck source=android-toolchain-versions.sh
source "$repo_root/scripts/android-toolchain-versions.sh"
sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Library/Android/sdk}}"
adb="$sdk_root/platform-tools/adb"
lane="${1:-phone}"
case "$lane" in
  phone) user_rotation=1 ;;
  tablet) user_rotation=0 ;;
  *) echo "ERROR: lane must be phone or tablet" >&2; exit 64 ;;
esac

device_count="$("$adb" devices | sed -n '2,$p' | grep -c '[[:space:]]device$' || true)"
[[ "$device_count" == 1 ]] || {
  echo "ERROR: expected exactly one connected Android emulator/device" >&2
  exit 1
}

"$repo_root/scripts/build-android-fixture.sh"
apk="$repo_root/android/app/build/outputs/apk/debug/app-debug.apk"
"$adb" install -r "$apk" >/dev/null
"$adb" shell input keyevent KEYCODE_WAKEUP >/dev/null
"$adb" shell wm dismiss-keyguard >/dev/null 2>&1 || true
"$adb" shell settings put system accelerometer_rotation 0
"$adb" shell settings put system user_rotation "$user_rotation"

artifact_root="$repo_root/.android-bootstrap/menu-parity-$lane"
mkdir -p "$artifact_root"
tree="$artifact_root/hierarchy.xml"

dump_tree() {
  for _ in {1..10}; do
    if "$adb" shell uiautomator dump /sdcard/kartpad-menu-parity.xml >/dev/null 2>&1 &&
        "$adb" exec-out cat /sdcard/kartpad-menu-parity.xml >"$tree"; then
      return 0
    fi
    sleep 1
  done
  echo "ERROR: could not capture menu hierarchy" >&2
  return 1
}

start_menu() {
  "$adb" shell am force-stop dev.kartpad.android
  "$adb" shell am start -W -n dev.kartpad.android/.KartPadActivity \
    --ez dev.kartpad.android.TEST_MENU true >/dev/null
  for _ in {1..20}; do
    dump_tree
    grep -Fq 'text="Switch Game Version…"' "$tree" && return 0
    sleep 1
  done
  echo "ERROR: KartPad menu did not open" >&2
  return 1
}

assert_labels() {
  python3 - "$tree" "$@" <<'PY'
import sys
import xml.etree.ElementTree as ET

tree, *expected = sys.argv[1:]
actual = {
    node.attrib.get("text", "")
    for node in ET.parse(tree).getroot().iter("node")
    if node.attrib.get("text")
}
missing = [label for label in expected if label not in actual]
if missing:
    raise SystemExit(f"ERROR: menu labels missing: {missing}; visible={sorted(actual)}")
PY
}

tap_label() {
  local label="$1"
  local coordinates
  coordinates="$(python3 - "$tree" "$label" <<'PY'
import re
import sys
import xml.etree.ElementTree as ET

tree, expected = sys.argv[1:]
for node in ET.parse(tree).getroot().iter("node"):
    if node.attrib.get("text") == expected:
        left, top, right, bottom = map(int, re.findall(r"\d+", node.attrib["bounds"]))
        print((left + right) // 2, (top + bottom) // 2)
        break
else:
    raise SystemExit(f"ERROR: cannot tap missing menu label {expected!r}")
PY
)"
  read -r x y <<<"$coordinates"
  "$adb" shell input tap "$x" "$y"
}

top=(
  "KartPad"
  "Switch Game Version…"
  "Multiplayer…"
  "Show FPS Counter"
  "Controls"
  "Display"
  "Game Data & Saves"
  "Report a Problem…"
)

start_menu
assert_labels "${top[@]}"

start_menu
tap_label "Controls"
sleep 1
dump_tree
assert_labels \
  "Controller Player Setup…" \
  "Controller Button Mapping…" \
  "Touch Control Settings…" \
  "Motion Steering…" \
  "Experimental Wii Remote + Nunchuk…"

start_menu
tap_label "Display"
sleep 1
dump_tree
assert_labels "Aspect Ratio…" "Render Resolution…"

start_menu
tap_label "Game Data & Saves"
sleep 1
dump_tree
assert_labels \
  "Import or Reimport Wii Disc Image…" \
  "Import from Extracted Folder…" \
  "Remove Stored Game Data…" \
  "Manage Retro Rewind…" \
  "Manage Saves…" \
  "Manage Miis…"

echo "Android menu parity passed: lane=$lane top=8 controls=5 display=2 data=6"
