# KartPad v0.4.0-preview.1 release rollup

Updated: 2026-09-03

This is the living validation record for the first Apple TV hardware-bring-up
preview. User-facing notes are in
[`v0.4.0-preview.1.md`](v0.4.0-preview.1.md).

## Included changes

- Independent native arm64 tvOS 17 `KartPadDual` target with Original and Retro
  Rewind selection, focus-driven setup, Extended Gamepad input, private staging,
  durable saves, rebuildable caches, backup, and bounded diagnostics.
- Original three-layer KartPad tvOS icon and Top Shelf artwork, with no Wii
  banner or user-supplied asset in source or package.
- Existing iPhone/iPad behavior advances to app 0.4.0 build 13 without claiming
  new physical acceptance.

## Accepted baseline

The preceding signed iPad candidate was installed in place over
`dev.kartpad.app`. Its Application Support/NAND tree matched byte-for-byte
before and after installation, and earlier hands-on checks accepted Retro
Rewind 6.12.4, Original Mario Kart Wii, ordinary controller input, and the
repaired three-dot menu through exit/reopen and mode changes.

The new tvOS target compiles and passes bundle, Mach-O platform, system-only
dependency, linked-contract, asset-catalog, privacy, signing-residue, and
private-data audits. That is build evidence, not physical execution evidence.

## External acceptance still required

- Install the exact tvOS candidate on physical Apple TV hardware.
- Prove missing-data recovery, private staging, controller input, one Original
  race, Retro Rewind download/install and one race, relaunch, sleep/wake, save
  durability, and backup/restore using `docs/TVOS-TESTING.md`.
- Keep Mii, direct macOS Wii Remote/Nunchuk, and Issue #1 reporter acceptance
  open under their existing boundaries.

Build success is not treated as Apple TV, external Mii, Wii hardware, or
Files-provider acceptance. Reports must use bounded diagnostics and must not
include game images, extracted content, saves, complete app containers, signing
material, credentials, or device identifiers.

## Release gates

- [x] Merge and verify the complete source on `main`.
- [x] Rebuild exact merged source as iOS 0.4.0 build 13 and tvOS 0.4.0 build 1.
- [x] Pass full tests, source/safety checks, patch verification, app audits, and
      Objective-C++ analysis.
- [x] Package each IPA twice deterministically and compare bytes.
- [x] Audit exact IPAs and embedded provenance/notices.
- [x] Tag the audited source and publish both IPAs plus `SHA256SUMS`.
- [x] Download hosted assets, byte-compare, checksum-verify, and re-audit.
- [x] Verify remote `main` and the dereferenced tag, then request Apple TV tests.

- Published source: `4d32dfac683966ea1cb4f72963deffbe936404da`
- iPhone/iPad IPA SHA-256:
  `5b959d7a6abba43db3d557bbba3dc3a1ab913650f0717cdf8600afa06fcb32c1`
- tvOS IPA SHA-256:
  `78dcdf28c947330d480fcc789f0b81b95bafe94497c56f9c26bb6249c5362df1`
- PR #7 closure:
  `https://github.com/chrissotraidis/kartpad/pull/7#issuecomment-5518667728`
