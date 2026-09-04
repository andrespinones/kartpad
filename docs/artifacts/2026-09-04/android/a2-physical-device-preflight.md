# Android A2 physical-device preflight

Date: 2026-09-04
Branch: `codex/android-a2-cold-input`
Starting commit: `a520c34303140b5724af264739a072d42ee7f559`

Host: macOS 26.6.2 (`25G83`), Apple Silicon arm64
Dependency-lock SHA-256:
`19c98a240293d3c0115ddd48d7aa4f5ae028c5904a94a4c3a378e5b9f9479ee6`

## Result

No physical Android device was attached to this host. `adb devices -l`
returned no targets, so no install, launch, app-data mutation, or physical A2
acceptance attempt was made. A2 remains open exactly as required by the goal
loop.

This checkpoint adds `scripts/check-android-physical-device.sh`, a read-only
intake gate for the next hardware session. It requires exactly one authorized
ADB target, rejects an emulator, and validates:

- API 28 or newer and primary ABI `arm64-v8a`;
- a supported 4 KiB or 16 KiB runtime page size;
- at least 4 GiB free on `/data` for the A2 Original-mode staging/run;
- sanitized manufacturer/model evidence;
- informational installed-package and Vulkan-inventory state; and
- the number of Android input devices advertising gamepad or joystick source
  bits.

The serial is used only for ADB command selection and is never printed. Input
device names and Vulkan JSON are also not emitted. A missing controller is a
notice rather than a false platform failure so the controller can be attached
after USB debugging is established.

## Contract test

Command:

```sh
./scripts/test-android-physical-device-preflight.sh
```

Result:

```text
Android physical-device preflight contract passed (11 cases; ADB serial redacted).
```

The eleven isolated fake-ADB cases cover a passing 16 KiB ARM64 device,
optional package/Vulkan inventory absence, missing controller notice, no
target, unauthorized target, emulator rejection, mid-probe disconnect, API
27, wrong ABI, unsupported page size, and insufficient free space. Every case
also rejects accidental appearance of the sentinel ADB serial in command
output, including an ADB error that contains it.

The controller masks are the pinned NDK definitions from `android/input.h`:
`AINPUT_SOURCE_GAMEPAD` (`0x00000401`) and `AINPUT_SOURCE_JOYSTICK`
(`0x01000010`).

Script SHA-256 values:

```text
f3b0708568b733a257c2cf391227e8e6949f6aa56c684d13a9aac47fcd4ceba1  scripts/check-android-physical-device.sh
d7be203060a06c1c9b1f50e26e36e174ad949e08358989d7da2a78693430a4c5  scripts/test-android-physical-device-preflight.sh
```

## Live host classification

Command:

```sh
./scripts/check-android-physical-device.sh
```

Result (expected with no hardware attached):

```text
ERROR: expected exactly one ready ADB target (ready=0 unavailable=0); no device serial was printed
```

Classification: **Pass for deterministic, privacy-safe physical-device
preflight tooling; not run for physical Android acceptance.** The physical
session must still confirm the app's SDL controller connection, a complete
race/results/save/relaunch sequence, pause/resume, surface recreation, audible
audio, tactile rumble, and acceptable performance. No APK/AAB or private data
was published.
