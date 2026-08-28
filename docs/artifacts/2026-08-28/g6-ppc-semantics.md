# G6 PPC/AArch64 semantics — in-progress gate evidence

Date: 2026-08-28

Host: Apple M2, macOS arm64; x86_64 under Rosetta

Compiler: AppleClang 21.0.0.21000101

WiiCompiled: `1912292c804ff9b1b79938de89369ec4496f9fff`

Dolphin source oracle: locked revision from `dependencies.lock.json`

Commands: `./scripts/test-ppc-semantics.sh`; `./scripts/test-g6-real-dol-surface.sh`

Observed results:

- arm64 Release: 250,220 checks, state hash `0x5a58605df18e5d1e`;
- x86_64/Rosetta Release: identical check count and raw-result state hash;
- arm64 ASan/UBSan: Pass;
- compiled Dolphin fres/frsqrte oracle: byte-identical to the checked corpus;
- immutable pinned translator suite: 570 passed; KartPad FPSCR-lowering patch suite: 579 passed, 0 failed, 0 skipped;
- actual translated DOL microfixture on both architectures: all prior scalar/paired estimate and suppression assertions plus ordered/unordered scalar and paired qNaN comparisons, unordered CR fields 3–6, sticky ordered VXVC, unordered FPCC, final stateful FPSCR `0xe7981393`, checked guest memory Pass;
- supplied user-owned PAL `main.dol`: SHA-256 `80d18895b39c63bd80f457398bfcbb91b7d16ac116a41a88967e954080155b05`, exactly matching WiiCompiled's project pin;
- real-title translation: 10,836 functions emitted from entry `0x800060A4`, unsupported instructions disabled, with the bundled 29,792-entry map used for boundaries;
- real-title surface compile: all 10,836 emitted C++ units pass AppleClang strict-FP syntax compilation against KartPad's portable shim;
- generated semantic DOL SHA-256: `a8a5d8540b15221150567e9409101228edefafec5a7b5e59905e21d9c2270961`;
- exact emitted C++ SHA-256: `455e736de737d035807bfd23fb5dc05d3313f7000a29e4366d3ba6c1e0013163`;
- reproducible WiiCompiled FPSCR patch SHA-256: `20e4b5e07dfc576a5311535eac8ff549b6d767465dca06f6261a948d6243f3a9`.

Classification: **In progress**, not Pass. Basic/fused scalar invalid-subcause, conversion, estimates, and exact comparisons are translated and runtime-proven. Paired arithmetic/fused state, translated host-callback execution, and NI persistence across scheduler boundaries remain required, so G6 stays the lowest unmet goal.
