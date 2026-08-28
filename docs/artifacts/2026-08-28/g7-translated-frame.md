# Provisional translated Metal frame evidence

This is useful G7 bring-up evidence, but **not G7 acceptance**: it uses a synthetic translated command fixture and direct Metal, not Dawn/Aurora, translated GX geometry, or a game frame.

- Pinned translator emitted `runtime/generated/g7/func_80001000.cpp` exactly from a no-game-data DOL.
- The translated function writes a checked-memory `KPDF` command at `0x80010000`.
- A real AppKit window and `CAMetalLayer` drawable rendered 256×192 RGBA `2458A8FF` with Metal API Validation enabled.
- Every BGRA output pixel matched; captured PNG SHA-256 is `fe16b70a0c012102b375cbd4d5d2fd9089b86cda93d3e5e08de86878030c31db`.
- Capture: `docs/artifacts/2026-08-28/g7-translated-frame.png`.

The first build failed under `-Werror` because a CoreGraphics enum was combined with an integer bitwise expression. Explicit `uint32_t` conversions resolved that compile-time type mismatch; the successful run followed after the code changed.
