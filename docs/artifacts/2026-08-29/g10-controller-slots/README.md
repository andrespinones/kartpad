# G10 four keyboard-backed controller slots

Status: **Pass for PRD row 31.** P1–P4 assignment, reconnect, and held-state clearing pass in the native retail controller UI.

## Implementation

- Extended the existing Classic-controller keyboard bridge from channel 0 to four independent WPAD/KPAD channels.
- P1 remains always connected with the established Return/Backspace/arrows/WASD mapping. `U` and `M` provide held gameplay A/accelerate and B/reverse aliases without changing the short menu-safe Return/Backspace pulses.
- Pressing `2`, `3`, or `4` connects P2, P3, or P4 and supplies that channel's Plus edge; each channel then has independent A/B/directional/stick bindings.
- Pressing `7`, `8`, or `9` disconnects P2, P3, or P4. Disconnect clears pending, previous-core, and previous-Classic button state before WPAD reports no controller.
- WPAD probe, data-format, info, and LED paths now reflect per-channel connection state. KPAD regular and unified reports read the matching channel instead of rejecting channels 1–3.
- Keyboard stick input uses the full normalized range so split-screen players can recover and steer at race speed.

## Observed result

- The retail four-player Register Controllers screen showed four distinct Classic controllers assigned to the yellow/P1, blue/P2, red/P3, and green/P4 slots.
- An A edge was sent to P3 immediately before disconnect. The game raised the red/P3 `Communications with the controller have been interrupted` dialog.
- Reconnecting P3 with its own Plus/A bindings restored all four assignments. After waiting beyond the synthetic key-hold interval, the screen remained stable and no stale action fired.
- Earlier in the same build, P2 independently selected Luigi and Standard Kart M and accelerated/steered in live two-player split-screen Luigi Circuit.

## Evidence

- `p1-p4-registered.jpeg` — four assigned controller slots.
- `p3-disconnected.jpeg` — correct P3 interruption dialog.
- `p3-reconnected-cleared.jpeg` — restored four-slot state after held-state expiry.

The reproducible implementation is in `patches/wiicompiled-apple-runtime.patch`; the patch dry-runs against the pinned runtime and the signed arm64 product rebuilds successfully.
