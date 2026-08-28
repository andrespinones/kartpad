# G6 PPC/AArch64 semantics — partial gate evidence

Date: 2026-08-28

Host: Apple M2, macOS arm64; x86_64 under Rosetta

Compiler: AppleClang 21.0.0.21000101

WiiCompiled: `1912292c804ff9b1b79938de89369ec4496f9fff`

Dolphin source oracle: locked revision from `dependencies.lock.json`

Command: `./scripts/test-ppc-semantics.sh`

Observed results:

- arm64 Release: 250,080 checks, state hash `0xca5a9534a8da687b`;
- x86_64/Rosetta Release: identical check count and raw-result state hash;
- arm64 ASan/UBSan: Pass;
- compiled Dolphin fres/frsqrte oracle: byte-identical to the checked corpus;
- pinned translator suite: 570 passed, 0 failed, 0 skipped;
- actual translated DOL microfixture on both architectures: integer `65534`, `fadds` `0x40700000`, checked guest memory Pass;
- generated semantic DOL SHA-256: `34479605681947d2fdc77cac203655d1772358f722c1117b632a3c4411e28510`;
- exact emitted C++ SHA-256: `ed6518cc8cb7720cf63b41d6979e04df85b77bc0ee0154921e8dfbb585a56f2d`.

Classification: **In progress**, not Pass. This establishes a portable differential/oracle harness and a real translated scalar path. It does not yet cover the complete helper surface used by Mario Kart Wii, so G6 remains the lowest unmet goal.
