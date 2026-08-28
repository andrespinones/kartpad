# G6 PPC/AArch64 semantics — in-progress gate evidence

Date: 2026-08-28

Host: Apple M2, macOS arm64; x86_64 under Rosetta

Compiler: AppleClang 21.0.0.21000101

WiiCompiled: `1912292c804ff9b1b79938de89369ec4496f9fff`

Dolphin source oracle: locked revision from `dependencies.lock.json`

Commands: `./scripts/test-ppc-semantics.sh`; `./scripts/test-g6-real-dol-surface.sh`

Observed results:

- arm64 Release: 250,155 checks, state hash `0xb332d343c4e3dc81`;
- x86_64/Rosetta Release: identical check count and raw-result state hash;
- arm64 ASan/UBSan: Pass;
- compiled Dolphin fres/frsqrte oracle: byte-identical to the checked corpus;
- pinned translator suite: 570 passed, 0 failed, 0 skipped;
- actual translated DOL microfixture on both architectures: integer `65534`, `fadds` `0x40700000`, `ps_add` `0x4080000040000000`, divide-by-zero `0x7f800000`, final stateful FPSCR `0xa7000003`, checked guest memory Pass;
- supplied user-owned PAL `main.dol`: SHA-256 `80d18895b39c63bd80f457398bfcbb91b7d16ac116a41a88967e954080155b05`, exactly matching WiiCompiled's project pin;
- real-title translation: 10,836 functions emitted from entry `0x800060A4`, unsupported instructions disabled, with the bundled 29,792-entry map used for boundaries;
- real-title surface compile: all 10,836 emitted C++ units pass AppleClang strict-FP syntax compilation against KartPad's portable shim;
- generated semantic DOL SHA-256: `e7c68311a1f7b10712f85cea4b80477e0075f109904de3c2e5c7c1a7f8bdb61a`;
- exact emitted C++ SHA-256: `f02a3f5e9eea524247a99b8ff969dca3225e125d890c742072703cf2d6eed939`.

Classification: **In progress**, not Pass. The full emitted helper surface is now owned and compile-proven. Exact FPSCR invalid-subcause/enabled-exception behavior, translated host-callback execution, and NI persistence across scheduler boundaries remain required, so G6 stays the lowest unmet goal.
