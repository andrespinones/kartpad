# G6 PPC/AArch64 semantics — pass evidence

Date: 2026-08-28

Host: Apple M2, macOS arm64; x86_64 under Rosetta

Compiler: AppleClang 21.0.0.21000101

WiiCompiled: `1912292c804ff9b1b79938de89369ec4496f9fff`

Dolphin source oracle: locked revision from `dependencies.lock.json`

Commands: `./scripts/test-ppc-semantics.sh`; `./scripts/test-g6-real-dol-surface.sh`

Observed results:

- arm64 Release: 250,227 checks, state hash `0xccd5757c4c0643d4`;
- x86_64/Rosetta Release: identical check count and raw-result state hash;
- arm64 ASan/UBSan: Pass;
- compiled Dolphin fres/frsqrte oracle: byte-identical to the checked corpus;
- immutable pinned translator suite: 570 passed; KartPad FPSCR-lowering patch suite: 579 passed, 0 failed, 0 skipped;
- actual translated DOL microfixture on both architectures: all prior assertions plus VE-enabled paired invalid add that still writes both canonical-NaN lanes and records VXISI, final stateful FPSCR `0xe7991393`, checked guest memory Pass;
- supplied user-owned PAL `main.dol`: SHA-256 `80d18895b39c63bd80f457398bfcbb91b7d16ac116a41a88967e954080155b05`, exactly matching WiiCompiled's project pin;
- real-title translation: 10,836 functions emitted from entry `0x800060A4`, unsupported instructions disabled, with the bundled 29,792-entry map used for boundaries;
- real-title surface compile: all 10,836 emitted C++ units pass AppleClang strict-FP syntax compilation against KartPad's portable shim;
- translated scheduler bridge: Release and ASan/UBSan Pass; NI, VE/ZE, VXISI/ZX, FPR destination suppression, and the active CPU context persist across a real scheduler yield and nested host callback;
- translated-frame dispatcher: automatic `CpuContextScope` build verification Pass, so translated entry points no longer rely on callers to establish thread-local CPU state manually;
- generated semantic DOL SHA-256: `0aa3669f4d3e526d7cd34f2996909bbcfaa3c3edf42a43c809087d6043063813`;
- exact emitted C++ SHA-256: `c28aab690132e176f465380fada73a4bd8dea5ad152e2217d5a3c86d64adc1e9`;
- reproducible WiiCompiled FPSCR patch SHA-256: `20e4b5e07dfc576a5311535eac8ff549b6d767465dca06f6261a948d6243f3a9`.

Classification: **Pass**. Integer, scalar FP, paired-single/GQR, conversion, estimate, flag, ABI, translated execution, scheduler persistence, sanitizer, and full title-surface checks have zero unexplained mismatches. Any later reproducible game/ghost divergence attributable to ARM64 semantics reopens G6.
