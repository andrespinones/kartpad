# Android A4 menu hierarchy reachability

Date: 2026-09-05

## Outcome

A new source-only emulator gate opens the real Android three-dot menu and then
independently traverses each submenu. It prevents a row that exists in source
but is missing or unreachable in the rendered `PopupMenu` from being counted
as parity.

The gate requires:

- eight top-level rows: KartPad, Switch Game Version, Multiplayer, FPS,
  Controls, Display, Game Data & Saves, and Report a Problem;
- five Controls rows: player setup, button mapping, touch settings, motion
  steering, and the explicit Wii Remote + Nunchuk platform boundary;
- two Display rows: aspect ratio and render resolution; and
- six Game Data & Saves rows: disc import, extracted-folder import, removal,
  Retro Rewind, saves, and Miis.

## Emulator evidence

The visible API 36 Pixel Tablet and Pixel 6 both passed the complete real-menu
traversal:

`Android menu parity passed: lane=<lane> top=8 controls=5 display=2 data=6`

This is 21 reachable rows across the consolidated hierarchy. The fixture is
gated out of translated game-runtime builds and uses no private data.

## Classification

**Pass for rendered menu hierarchy reachability on the canonical emulator
phone/tablet lanes.** The gate does not claim that physical-device dialogs,
external Android pickers, controllers, or haptics have been accepted.
