# G6 PPC/AArch64 semantics — partial gate evidence

Date: 2026-08-28

Host: Apple M2, macOS arm64; x86_64 under Rosetta

Compiler: AppleClang 21.0.0.21000101

WiiCompiled: `1912292c804ff9b1b79938de89369ec4496f9fff`

Dolphin source oracle: locked revision from `dependencies.lock.json`

Command: `./scripts/test-ppc-semantics.sh`

Observed results:

- arm64 Release: 250,155 checks, state hash `0xb332d343c4e3dc81`;
- x86_64/Rosetta Release: identical check count and raw-result state hash;
- arm64 ASan/UBSan: Pass;
- compiled Dolphin fres/frsqrte oracle: byte-identical to the checked corpus;
- pinned translator suite: 570 passed, 0 failed, 0 skipped;
- actual translated DOL microfixture on both architectures: integer `65534`, `fadds` `0x40700000`, `ps_add` `0x4080000040000000`, divide-by-zero `0x7f800000`, FPSCR `0x84000000`, checked guest memory Pass;
- generated semantic DOL SHA-256: `e7c68311a1f7b10712f85cea4b80477e0075f109904de3c2e5c7c1a7f8bdb61a`;
- exact emitted C++ SHA-256: `f02a3f5e9eea524247a99b8ff969dca3225e125d890c742072703cf2d6eed939`.

Classification: **In progress**, not Pass. This establishes a portable differential/oracle harness and a real translated scalar path. It does not yet cover the complete helper surface used by Mario Kart Wii, so G6 remains the lowest unmet goal.
