#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
# shellcheck source=android-toolchain-versions.sh
source "$repo_root/scripts/android-toolchain-versions.sh"

bundle="${1:-$repo_root/android/app/build/outputs/bundle/release/app-release.aab}"
sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Library/Android/sdk}}"
adb="${KARTPAD_ADB:-$sdk_root/platform-tools/adb}"
aapt2="$sdk_root/build-tools/$KARTPAD_ANDROID_BUILD_TOOLS/aapt2"
java="$repo_root/.android-bootstrap/jdk-$KARTPAD_ANDROID_JDK_VERSION/Contents/Home/bin/java"
python="${KARTPAD_PYTHON:-python3}"
bundletool="$repo_root/.android-bootstrap/dependencies/bundletool-all-1.18.1.jar"
debug_keystore="${KARTPAD_ANDROID_LOCAL_TEST_KEYSTORE:-$HOME/.android/debug.keystore}"
package="dev.kartpad.android"
expected_main_dol_sha256="80d18895b39c63bd80f457398bfcbb91b7d16ac116a41a88967e954080155b05"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

for tool in "$adb" "$aapt2" "$java"; do
  [[ -x "$tool" ]] || fail "required executable is unavailable: $tool"
done
command -v "$python" >/dev/null || fail "Python is unavailable: $python"
[[ -f "$bundle" ]] || fail "AAB is unavailable at $bundle"
[[ -f "$bundletool" ]] || fail "pinned bundletool is unavailable at $bundletool"
[[ -f "$debug_keystore" ]] || fail "local Android test keystore is unavailable"

devices="$($adb devices -l)"
ready_count="$(printf '%s\n' "$devices" |
  awk 'NR > 1 && $2 == "device" { count++ } END { print count + 0 }')"
[[ "$ready_count" == 1 ]] || fail "expected exactly one ready Android target"
serial="$(printf '%s\n' "$devices" |
  awk 'NR > 1 && $2 == "device" { print $1; exit }')"
adb_target=("$adb" -s "$serial")
[[ "$("${adb_target[@]}" shell getprop ro.kernel.qemu | tr -d '\r')" == 1 ]] ||
  fail "the connected target is not an Android emulator"

temp_root="$(mktemp -d "$repo_root/.android-bootstrap/bundle-derived.XXXXXX")"
[[ "$temp_root" == "$repo_root/.android-bootstrap/bundle-derived."* ]] ||
  fail "temporary directory escaped the guarded Android bootstrap root"
restore_apk="$temp_root/installed-debug.apk"
restore_required=0

restore_selector() {
  "${adb_target[@]}" shell am force-stop "$package" >/dev/null 2>&1 || true
  "${adb_target[@]}" shell am start -W \
    -n "$package/.KartPadLaunchActivity" >/dev/null 2>&1 || true
}

cleanup() {
  local status=$?
  if [[ "$restore_required" == 1 && -f "$restore_apk" ]]; then
    "${adb_target[@]}" install -r "$restore_apk" >/dev/null 2>&1 || true
  fi
  restore_selector
  rm -rf -- "$temp_root"
  exit "$status"
}
trap cleanup EXIT

remote_exists() {
  "${adb_target[@]}" shell run-as "$package" test -e "$1"
}

file_digest() {
  local remote_file="$1"
  if remote_exists "$remote_file"; then
    "${adb_target[@]}" exec-out run-as "$package" sha256sum "$remote_file" |
      awk '{ print $1 }'
  else
    printf 'absent\n'
  fi
}

tree_digest() {
  local remote_root="$1"
  if remote_exists "$remote_root"; then
    "${adb_target[@]}" exec-out run-as "$package" tar -cf - "$remote_root" |
      shasum -a 256 | awk '{ print $1 }'
  else
    printf 'absent\n'
  fi
}

state_digest() {
  {
    printf 'config=%s\n' "$(file_digest files/KartPad/Config.toml)"
    printf 'main_dol=%s\n' "$(file_digest files/KartPad/GameData/sys/main.dol)"
    printf 'nand=%s\n' "$(tree_digest files/KartPad/NAND)"
    printf 'saves=%s\n' "$(tree_digest files/KartPad/Saves)"
    printf 'preferences=%s\n' "$(tree_digest shared_prefs)"
    printf 'retro_version=%s\n' \
      "$(file_digest files/KartPad/RetroRewind/RetroRewind6/version.txt)"
  } | shasum -a 256 | awk '{ print $1 }'
}

installed_version_code() {
  "${adb_target[@]}" shell dumpsys package "$package" |
    sed -n 's/^[[:space:]]*versionCode=\([0-9][0-9]*\).*/\1/p' |
    head -1 | tr -d '\r'
}

original_mode_bounds() {
  local ui_tree="/sdcard/kartpad-bundle-derived.xml"
  "${adb_target[@]}" shell uiautomator dump "$ui_tree" >/dev/null 2>&1 || return 1
  "${adb_target[@]}" exec-out cat "$ui_tree" | "$python" -c '
import re
import sys
import xml.etree.ElementTree as ET

root = ET.fromstring(sys.stdin.read())
nodes = {node.attrib.get("resource-id"): node for node in root.iter("node")}
original = nodes.get("dev.kartpad.android:id/kartpad_mode_original")
retro = nodes.get("dev.kartpad.android:id/kartpad_mode_retro_rewind")
if original is None or retro is None or original.attrib.get("enabled") != "true":
    raise SystemExit(1)
match = re.fullmatch(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", original.attrib["bounds"])
if match is None:
    raise SystemExit(1)
print(" ".join(match.groups()))
'
}

selector_is_visible() {
  original_mode_bounds >/dev/null
}

wait_for_selector() {
  local ready=0
  for _ in {1..20}; do
    if selector_is_visible; then
      ready=1
      break
    fi
    sleep 1
  done
  [[ "$ready" == 1 ]] || fail "the production game selector did not become visible"
}

tap_original_mode() {
  local bounds
  bounds="$(original_mode_bounds)" ||
    fail "could not locate an enabled Original-game selector card"
  local left top right bottom
  read -r left top right bottom <<<"$bounds"
  "${adb_target[@]}" shell input tap \
    "$(((left + right) / 2))" "$(((top + bottom) / 2))"
}

"$repo_root/scripts/audit-android-bundle.sh" "$bundle" >/dev/null
bundle_sha256="$(shasum -a 256 "$bundle" | awk '{ print $1 }')"

installed_path="$("${adb_target[@]}" shell pm path "$package" |
  sed -n 's/^package://p' | head -1 | tr -d '\r')"
[[ -n "$installed_path" ]] || fail "KartPad is not installed on the emulator"
"${adb_target[@]}" pull "$installed_path" "$restore_apk" >/dev/null
[[ "$("$aapt2" dump badging "$restore_apk")" == *"package: name='$package'"* ]] ||
  fail "the recoverable installed APK has the wrong package identity"
restore_version="$(installed_version_code)"
[[ -n "$restore_version" ]] || fail "could not determine the installed version code"
[[ "$(file_digest files/KartPad/GameData/sys/main.dol)" == \
    "$expected_main_dol_sha256" ]] ||
  fail "app-private GameData is not the approved fixture"
before_state="$(state_digest)"

"$java" -jar "$bundletool" build-apks \
  --bundle="$bundle" \
  --output="$temp_root/app.apks" \
  --mode=universal \
  --ks="$debug_keystore" \
  --ks-pass=pass:android \
  --ks-key-alias=androiddebugkey \
  --key-pass=pass:android >/dev/null
unzip -q "$temp_root/app.apks" universal.apk -d "$temp_root"
derived_apk="$temp_root/universal.apk"
[[ -f "$derived_apk" ]] || fail "bundletool did not produce a universal APK"
derived_badging="$("$aapt2" dump badging "$derived_apk")"
[[ "$derived_badging" == *"package: name='$package'"* ]] ||
  fail "bundle-derived APK has the wrong package identity"
[[ "$derived_badging" != *"application-debuggable"* ]] ||
  fail "bundle-derived release APK is unexpectedly debuggable"
derived_version="$(printf '%s\n' "$derived_badging" |
  sed -n "s/^package: .*versionCode='\([0-9][0-9]*\)'.*/\1/p")"
[[ "$derived_version" == "$restore_version" ]] ||
  fail "bundle-derived APK and recoverable installed APK have different versions"
"$repo_root/scripts/audit-android-package.sh" "$derived_apk" >/dev/null
derived_apk_sha256="$(shasum -a 256 "$derived_apk" | awk '{ print $1 }')"

restore_required=1
"${adb_target[@]}" install -r "$derived_apk" >/dev/null
[[ "$(installed_version_code)" == "$derived_version" ]] ||
  fail "installed bundle-derived APK version does not match"

"${adb_target[@]}" shell input keyevent KEYCODE_WAKEUP >/dev/null
"${adb_target[@]}" shell wm dismiss-keyguard >/dev/null 2>&1 || true
restore_selector
wait_for_selector

"${adb_target[@]}" logcat -c
tap_original_mode
runtime_started=0
for _ in {1..30}; do
  if "${adb_target[@]}" logcat -d -s SDL:V '*:S' |
      grep -Eq 'Running main function SDL_main from library .*/lib/arm64/libmain\.so'; then
    runtime_started=1
    break
  fi
  sleep 1
done
[[ "$runtime_started" == 1 ]] ||
  fail "bundle-derived release activity did not execute SDL_main from libmain.so"
"${adb_target[@]}" shell am force-stop "$package"

"${adb_target[@]}" install -r "$restore_apk" >/dev/null
restore_required=0
[[ "$(installed_version_code)" == "$restore_version" ]] ||
  fail "recoverable debug APK version was not restored"
after_state="$(state_digest)"
[[ "$before_state" == "$after_state" ]] ||
  fail "app-private durable state changed across bundle-derived APK testing"
restore_selector
wait_for_selector

echo "Android bundle-derived APK emulator test passed: aab_sha256=$bundle_sha256 derived_apk_sha256=$derived_apk_sha256 version_code=$derived_version release_non_debuggable=yes selector_visible=yes sdl_main_executed=yes debug_apk_restored=yes durable_state_preserved=yes"
