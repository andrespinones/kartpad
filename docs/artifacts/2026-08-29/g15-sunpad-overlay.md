# G15 exact SunPad overlay baseline and Mario Kart input boundary

## Direct source snapshot

The user-supplied SunPad checkout at commit
`e43f0ea6b797e5110787171957c9dc3c6213269c` is the authoritative mobile UI
source. KartPad now retains a byte-identical snapshot of:

- `SunPadGameOverlay.h/.mm`;
- `SunPadInputState.h`;
- `SunPadInputMixer.h/.mm`; and
- `SunPadSettings.h/.mm`.

`scripts/verify-sunpad-overlay-snapshot.sh` compares every file byte-for-byte
against the pinned local reference, verifies the reference commit, and compares
the GPLv3 license text. The verifier passes. Snapshot hashes and provenance are
recorded in `apple/third_party/sunpad/UPSTREAM.md`.

This preserves the actual 40-point circular ellipsis menu, UIKit `UIMenu`,
sticks, buttons, trigger, grouped D-pad, safe-area math, distinct iPhone/iPad
normalized layouts, persisted edit/resize/reset behavior, opacity, controller
handoff, edge-latched multitouch mixer, and held-input clearing. It is not a
visual reimplementation.

## Mario Kart Wii adaptation boundary

KartPad does not change the copied component to impersonate a different control
surface. `apple/mobile/KartPadClassicInput.mm` converts the component's
GameCube-shaped normalized state to the exact Classic Controller bit ABI already
used by the macOS runtime.

The mapping follows Nintendo's *Mario Kart Wii Instruction Booklet*, Controls,
page 4 (linked from Nintendo's Wii Manuals support page):

| Copied control | Classic input | Mario Kart Wii action |
|---|---|---|
| Move stick | Left stick | Steer/select |
| A | A | Accelerate/confirm |
| B | B | Drift, brake/reverse/hop, cancel |
| R | R | Alternate drift, brake/reverse/hop |
| L | L | Use/hold item |
| X | X | Look backward |
| Z | ZR | Alternate look backward |
| START | Plus | Pause |
| D-pad | D-pad | Tricks and wheelies |
| Y | Y | Preserved physical input |
| Camera stick | Right stick | Preserved physical input |

The host Objective-C++ contract test proves every individual mapping, the full
simultaneous mask, both analog sticks, and connection state. It passes under the
arm64 macOS toolchain. This is source-level boundary evidence only; it does not
claim Simulator gameplay or touch ergonomics acceptance.
