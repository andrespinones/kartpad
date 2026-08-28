# G6 PPC/AArch64 semantics — in-progress gate evidence

Date: 2026-08-28

Host: Apple M2, macOS arm64; x86_64 under Rosetta

Compiler: AppleClang 21.0.0.21000101

WiiCompiled: `1912292c804ff9b1b79938de89369ec4496f9fff`

Dolphin source oracle: locked revision from `dependencies.lock.json`

Commands: `./scripts/test-ppc-semantics.sh`; `./scripts/test-g6-real-dol-surface.sh`

Observed results:

- arm64 Release: 250,197 checks, state hash `0x817dafe156e3268c`;
- x86_64/Rosetta Release: identical check count and raw-result state hash;
- arm64 ASan/UBSan: Pass;
- compiled Dolphin fres/frsqrte oracle: byte-identical to the checked corpus;
- immutable pinned translator suite: 570 passed; KartPad FPSCR-lowering patch suite: 573 passed, 0 failed, 0 skipped;
- actual translated DOL microfixture on both architectures: integer `65534`, `fadds` `0x40700000`, `ps_add` `0x4080000040000000`, divide-by-zero `0x7f800000`, canonical invalid-add NaN, enabled-VE destination preserved at `42.0`, `fctiwz`/`fctiw` words 2/3, enabled invalid conversion suppressed, final stateful FPSCR `0xe7811183`, checked guest memory Pass;
- supplied user-owned PAL `main.dol`: SHA-256 `80d18895b39c63bd80f457398bfcbb91b7d16ac116a41a88967e954080155b05`, exactly matching WiiCompiled's project pin;
- real-title translation: 10,836 functions emitted from entry `0x800060A4`, unsupported instructions disabled, with the bundled 29,792-entry map used for boundaries;
- real-title surface compile: all 10,836 emitted C++ units pass AppleClang strict-FP syntax compilation against KartPad's portable shim;
- generated semantic DOL SHA-256: `1d70c305874df6f4f5a808d8b4af31ce005923dc5d1f4bd5be6459fc15627d1d`;
- exact emitted C++ SHA-256: `f7723fd92c8136c02cbb03cb4707cebf6f044c574a6c63334f8277805cc6ba0b`;
- reproducible WiiCompiled FPSCR patch SHA-256: `e73572d587b4d1afcde8545a637050eb576fb3a0fc07fcbfc807b9589b7cef5d`.

Classification: **In progress**, not Pass. Basic scalar invalid-subcause, summary, FPRF, and enabled-write behavior is now translated and runtime-proven. Fused/conversion/estimate/paired exception state, translated host-callback execution, and NI persistence across scheduler boundaries remain required, so G6 stays the lowest unmet goal.
