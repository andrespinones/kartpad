# Android A4 touch-overlay input

## Falsifiable subgoal

Render KartPad's accepted phone control geometry over the complete Android
dual runtime, then use Android touchscreen events to advance Retro Rewind with
both A and D-pad input on the API 36 ARM64 emulator.

This is an emulator touch/JNI/guest-input integration gate. It is not a
physical-finger ergonomics, latency, haptics, accessibility, layout editing,
controller handoff, tablet, or physical-device acceptance result.

## Implementation

- `KartPadOverlayView` owns a transparent Canvas overlay with stable
  pointer-ID ownership for multitouch, the left and C sticks, A/B/X/Y/Z,
  Start, L/R, and grouped D-pad controls.
- A narrow JNI bridge publishes normalized axes and Classic button bits to a
  mutex-protected native state. Rising button edges remain latched for one
  guest sample so a short Android tap cannot disappear between KPAD polls.
- The Android KPAD patch merges touch with channel-zero physical-controller
  state while leaving other controller channels unchanged. Pause, focus loss,
  detach, and cancellation clear held touch state.
- The source-only fixture keeps the gameplay overlay hidden. Game-runtime
  builds enable it through the generated `GAME_RUNTIME` flag.
- The Android game builder now derives both preparation product and native
  target from the selected translated shard graph. A dual graph prepares
  `dual` and builds `KartPadDual`; a base-only graph prepares `base` and builds
  `WiiCompiled`.

## Failure found by simulator execution

The first A4 APK had been prepared from the default base-only private graph
while the launcher still offered an already-installed Retro Rewind choice.
Selecting Retro therefore failed with `selected profile is not linked:
retro_rewind`; the exception path then exposed a secondary pre-initialization
ImGui shutdown assertion. The failure happened before touch input ran.

The redundant base compile was stopped. A fresh build used the already-
validated Retro Rewind self-build graph, whose manifest declares Retro shards,
and Gradle explicitly configured `buildCMakeDebug[arm64-v8a][KartPadDual]`.

## Emulator evidence

- Removed a stale `wm size 1280x720` override. The AVD reports physical
  `1080x2400`, rotation 1, and a real logical/application frame of
  `2400x1080`; the production chooser visibly fills that wide surface.
- The audited dual APK is 119,090,830 bytes with SHA-256
  `0d39e63d7650d06e548e0099e2c102d7a08d4db2a54d05bcda8366a934ef268c`.
- Retro Rewind reached its title with the complete overlay visible. The
  ignored screenshot SHA-256 is
  `bfe80193d49bf6a234d65e9f80b639bfffd1f0ae7a67791d84bf5f76a283fd96`.
- An `adb shell input tap` at the visible green A control advanced from
  `Press the A Button` to Select License. Its ignored screenshot SHA-256 is
  `6b70191eebac4990472880f24fafec315e9b383bd28d3035ffbc916a5a9baf38`.
- A second touchscreen tap on the visible D-pad Right control moved selection
  from the existing KartPad license to the upper-right NEW slot. Its ignored
  screenshot SHA-256 is
  `7fa74b44ebd7dec8011d656aef35a4e3cddf9d150f43ccb291699b76d9aa9fbb`.
- The same process PID remained alive and logcat contained no fatal,
  `UnsatisfiedLinkError`, or profile-selection failure after both inputs.

## Classification

**Pass for the first Android A4 emulator touch slice: correct native landscape
geometry, visible full control set, JNI/KPAD A input, and JNI/KPAD D-pad input
on the complete dual Retro runtime.**

Still open: right-stick guest behavior, one-second acceleration lock and
haptics, persistent editing/opacity/size/hide, controller hide/restore,
virtual accessibility nodes, screenshot goldens, tablet layout, physical
touch ergonomics/latency, motion steering, and physical-device acceptance. No
APK, AAB, screenshot, private graph, save, or game data was published.
