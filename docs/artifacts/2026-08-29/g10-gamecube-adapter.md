# G10 GameCube adapter limitation

Status: **Pass for PRD row 32 by explicit limitation.**

The current native macOS product does **not** support the official Nintendo WUP-028 USB GameCube adapter. The Darwin build deliberately selects `src/apple/wup028_adapter_stub.cpp`; its discovery/read/rumble functions report no connected adapter and leave all game-port assignments at `-1`. No raw USB device is opened and no adapter capability is advertised.

This is an explicit platform limitation, not a silently failing supported path. Ordinary SDL/GameController devices remain mandatory under the separate controller-slot rows; this evidence does not claim those rows.

Relevant public implementation surfaces:

- `patches/wiicompiled-apple-runtime.patch` selects the Apple stub for Darwin builds.
- `docs/PORTABILITY.md` records the separate macOS USB backend or explicit-limitation requirement.
- `docs/PRD.md` makes raw GameCube-adapter USB platform/permission dependent and accepts an explicit limitation for row 32.

Future WUP-028 support must replace the stub with a tested macOS USB backend, expose connected ports and errors in diagnostics, verify rumble, and run physical-adapter evidence before the limitation is removed.
