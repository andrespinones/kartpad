# G7 real Mario Kart Wii frame

Status: **Pass** on 2026-08-28.

KartPad's complete 10,264-function PAL shared translation was linked into the pinned WiiCompiled runtime and launched natively on an Apple M2. The runtime used Aurora, pinned Dawn `v20260603.191052`, and Metal; indexed the user-supplied disc extraction; initialized GX and VI; and rendered the real Mario Kart Wii wrist-strap safety screen at 60 FPS.

The macOS guest scheduler uses host `ucontext` fibers while retaining Wii `CpuContext` state per `OSThread`. A live process sample showed the main game loop in `EGG::AsyncDisplay::endRender → GXCopyDisp`, with a second guest fiber sleeping and resuming through VI retrace and `swapcontext`.

Evidence image: `mario-kart-wii-first-frame.jpeg`

- Dimensions: 854 × 512 pixels (854 × 480 game surface plus native title bar)
- SHA-256: `3228b6044cfc746e4bf86971f1445f412e5e8a6ff3029fa8b3b620d20be087b8`
- Visible content: Nintendo wrist-strap safety screen and Aurora FPS overlay reading 60.0
- Capture path: macOS app window captured through Computer Use after a Finder launch
- Simulator state: not running

Private game files, extracted disc content, NAND data, and generated translation products remain ignored and are not present in this artifact directory.
