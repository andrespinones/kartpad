# Android A4 touch accessibility checkpoint

Date: 2026-09-04

## Scope

This checkpoint makes the custom Canvas touch overlay visible and operable to
Android accessibility services. It closes the emulator accessibility-node gap;
physical-device screen-reader, touch, and haptic acceptance remain open.

## Implementation

- The overlay supplies an `AccessibilityNodeProvider` with one virtual child for
  every visible classic control: move and camera sticks, A/B/X/Y/Z, Start, L/R,
  and all four D-pad directions. Hidden controls and controller-hidden overlays
  are excluded, while hidden controls remain selectable in layout-editing mode.
- Each node has its own semantic class, spoken label, parent and screen bounds,
  focus handling, hover events, and content-change notifications.
- Button accessibility clicks pulse the same native controller masks as touch.
  Both sticks expose separate up/down/left/right custom actions and return to
  neutral after a bounded pulse.
- A exposes a dedicated Lock/Unlock acceleration action. Its node reports
  `Acceleration locked` while active, and the visual control uses the same cyan
  locked state as a one-second physical hold. A normal accessibility click while
  locked unlocks before issuing the short A pulse.

## Emulator evidence

- The exact dual Original + Retro APK was installed over the existing app on the
  standalone API 36 ARM64 emulator and reached the Original Mario Kart title.
- A live `uiautomator` hierarchy contained 14 distinct control nodes plus the
  existing Menu button. Every control had its expected label and nonempty
  2400x1080 screen bounds. Buttons were clickable; the two stick nodes were
  focusable, non-clickable `SeekBar` nodes with directional custom actions.
- A temporary UI Automator test resolved the `A button` virtual node and invoked
  its custom action through `AccessibilityNodeInfo.performAction`, not a screen
  coordinate. The action returned success, the node's state description became
  `Acceleration locked`, A visibly turned cyan, and the guest continued with A
  held. A physical tap then restored the unlocked green state.
- TalkBack was temporarily enabled to inspect the live service configuration.
  Its first-run notification request was denied, then the service and global
  accessibility setting were restored to their original disabled state. The
  temporary on-device test jar was removed.
- Before and after install/testing, `main.dol`, RKSYS, and the Mii database kept
  their exact hashes:
  - `80d18895b39c63bd80f457398bfcbb91b7d16ac116a41a88967e954080155b05`
  - `708c7a040e0cfe6cd815690e63f46d1678f17899bce0e786f7480030830f1d13`
  - `6212cbf744e28d8e0687c9e8a7d8b22343ef37291b8dc5c031f04f1c45e5b3b7`

## Verification

- Exact local-only APK SHA-256:
  `35ca72fab4c2c3737f373b25e6374daa7edfc13607d23afeaa8091e09b8c3fdf`.
- Kotlin compilation and Android lint: pass.
- Strict APK/package/privacy audit: pass.
- Forty-nine Android/iOS source contract tests: pass.
- UI Automator virtual-node discovery and direct A-lock custom action: pass.
- Repository whitespace check: pass.

No APK, AAB, game data, save, Mii database, log, test jar, or screenshot was
published.
