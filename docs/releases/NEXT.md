# KartPad v0.4.0-preview.2 release rollup

Updated: 2026-09-03

This is the living validation record for the Retro Rewind 6.12.5 and universal
menu repair preview. User-facing notes are in
[`v0.4.0-preview.2.md`](v0.4.0-preview.2.md).

## Included changes

- Official Retro Rewind 6.12.5 archive, `Code.pul`, XML, and upstream source
  pins with a newly generated ahead-of-time translation graph.
- Kamek v2 and v3 parsing with strict outer-bound and command validation.
- Read-only daily upstream-version detection and a deterministic profile-update
  helper for future Retro Rewind releases.
- Universal iPhone/iPad three-dot-menu refresh repair: the menu remains titled
  KartPad and keeps the accepted consolidated hierarchy without the obsolete
  SunPad performance and 60 FPS experiments.
- iPhone/iPad app 0.4.0 build 14 and tvOS app 0.4.0 build 2.

## Accepted baseline

The preceding signed iPad candidate was installed in place over
`dev.kartpad.app`. Its Application Support/NAND tree matched byte-for-byte
before and after installation, and hands-on checks accepted Retro Rewind
6.12.4, Original Mario Kart Wii, ordinary controller input, and the repaired
three-dot menu through exit/reopen and mode changes.

Preview 2's 6.12.5 translation, fresh platform builds, and package audits are
release gates. They do not by themselves establish physical 6.12.5 gameplay or
Apple TV acceptance.

## External acceptance still required

- Install the exact iPhone/iPad candidate in place, verify the three-dot menu,
  install Retro Rewind 6.12.5, and complete a race without losing existing
  saves or settings.
- Install the exact tvOS candidate on physical Apple TV hardware and follow
  `docs/TVOS-TESTING.md` through private staging, controller input, Original and
  Retro Rewind races, relaunch, sleep/wake, and save durability.
- Keep public Retro WFC online compatibility separate until the external
  service and a live test are available.

## Release gates

- [ ] Merge and verify the complete source on `main`.
- [ ] Rebuild exact merged source as iOS 0.4.0 build 14 and tvOS 0.4.0 build 2.
- [ ] Pass full tests, source/safety checks, patch verification, app audits, and
      Objective-C++ analysis.
- [ ] Package each IPA twice deterministically and compare bytes.
- [ ] Audit exact IPAs and embedded provenance/notices.
- [ ] Tag the audited source and publish both IPAs plus `SHA256SUMS`.
- [ ] Download hosted assets, byte-compare, checksum-verify, and re-audit.
- [ ] Verify remote `main` and the dereferenced tag, then request device tests.

Published source and artifact hashes are recorded here only after the hosted
assets pass the same checks as the local candidates.
