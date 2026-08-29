# G10 private all-cups test fixture

Date: 2026-08-29

This is a reproducible test precondition for PRD row 22, not progression evidence
for row 23. No save payload is published.

- Source: the user's own ignored `Player` RKSYS save, copied before mutation and
  retained privately. Source/backup SHA-256:
  `4c7b8d596bbef8160ddc24255539321d39c07996c1ade0fd2aa6f90c999a6cf6`.
- Generator: `scripts/create-all-cups-test-fixture.py`. It requires a distinct
  output path, rejects an existing output, validates exact RKSYS size,
  `RKSD`/`0006` and selected `RKPD` magic, verifies the stored core CRC-32, and
  changes only the selected license's documented GP completion word plus the
  core CRC-32.
- Source authority: the pinned, push-disabled RR/Pulsar decomp headers describe
  `RKSYS::Binary`, the 0x8CC0-byte `RKPD`, its completion flags, and the four
  license slots. Standard CRC-32 over bytes `0..0x27ffb` independently matched
  the live save's stored `0x2e858d83` checksum before implementation.
- Changed license-0 completion word: `0x00000000` → `0xffffc000`. The retained
  fixture SHA-256 is
  `f09f809cb13bedb6959cf05aeb550fe7c19db2ea74fcc3cf61665d5b0b7b90ec`.
- Negative tests: corrupt input is rejected; in-place mutation is rejected;
  existing output is rejected. The data-free self-test passes.
- Retail validation: the fixture loaded the existing `Player` license without
  recovery or recreation, displayed all eight cup icons, and exposed all four
  Lightning Cup Time Trial tracks. The subsequent exact SNES Mario Circuit 3
  replay completed successfully.

The original save remains recoverable and byte-identical. Representative
Grand Prix completion and honest unlock progression remain separately open and
cannot be satisfied by this fixture.
