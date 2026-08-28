# G6 PPC/AArch64 semantics — in-progress gate evidence

Date: 2026-08-28

Host: Apple M2, macOS arm64; x86_64 under Rosetta

Compiler: AppleClang 21.0.0.21000101

WiiCompiled: `1912292c804ff9b1b79938de89369ec4496f9fff`

Dolphin source oracle: locked revision from `dependencies.lock.json`

Commands: `./scripts/test-ppc-semantics.sh`; `./scripts/test-g6-real-dol-surface.sh`

Observed results:

- arm64 Release: 250,202 checks, state hash `0x8947f7ff3d2e35f4`;
- x86_64/Rosetta Release: identical check count and raw-result state hash;
- arm64 ASan/UBSan: Pass;
- compiled Dolphin fres/frsqrte oracle: byte-identical to the checked corpus;
- immutable pinned translator suite: 570 passed; KartPad FPSCR-lowering patch suite: 577 passed, 0 failed, 0 skipped;
- actual translated DOL microfixture on both architectures: integer `65534`, `fadds` `0x40700000`, `ps_add` `0x4080000040000000`, divide-by-zero `0x7f800000`, canonical invalid-add NaN, enabled-VE destinations preserved for invalid add/conversion/`fmadds`, `fctiwz`/`fctiw` words 2/3, final stateful FPSCR `0xe7911183`, checked guest memory Pass;
- supplied user-owned PAL `main.dol`: SHA-256 `80d18895b39c63bd80f457398bfcbb91b7d16ac116a41a88967e954080155b05`, exactly matching WiiCompiled's project pin;
- real-title translation: 10,836 functions emitted from entry `0x800060A4`, unsupported instructions disabled, with the bundled 29,792-entry map used for boundaries;
- real-title surface compile: all 10,836 emitted C++ units pass AppleClang strict-FP syntax compilation against KartPad's portable shim;
- generated semantic DOL SHA-256: `2a8ebd817cb6e3dd6e9759117fe961d3f77c06725d95c4ab7cd29744e1eb9e17`;
- exact emitted C++ SHA-256: `47d60ee844d692e2329961f3de21ed9d527cefcac501ea2637e1637ab21d2a4f`;
- reproducible WiiCompiled FPSCR patch SHA-256: `da7dce9e085777f89e4ca991e6f72647548b64611ca055c6cc3edcae8ec85413`.

Classification: **In progress**, not Pass. Basic/fused scalar invalid-subcause, conversion, summary, FPRF, and enabled-write behavior is now translated and runtime-proven. Estimate/paired exception state, translated host-callback execution, and NI persistence across scheduler boundaries remain required, so G6 stays the lowest unmet goal.
