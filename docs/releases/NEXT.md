# KartPad v0.4.0 release rollup

Updated: 2026-09-03

This is the living validation record for the second stable KartPad community
release. User-facing notes are in [`v0.4.0.md`](v0.4.0.md).

## Included changes

- Official Retro Rewind 6.12.5 archive, `Code.pul`, XML, and upstream source
  pins with a newly generated ahead-of-time translation graph.
- Kamek v2 and v3 parsing with strict outer-bound and command validation.
- Read-only daily upstream-version detection and a deterministic profile-update
  helper for future Retro Rewind releases.
- Universal iPhone/iPad three-dot-menu refresh repair: the menu remains titled
  KartPad and keeps the accepted consolidated hierarchy without the obsolete
  SunPad performance and 60 FPS experiments.
- Maintainer-tested compact defaults for untouched iPhones, per-control
  Hide/Show, grouped D-pad visibility, and a direct Back path from the editor.
- iPhone/iPad app 0.4.0 build 15 and tvOS app 0.4.0 build 3.

## Accepted baseline

The preceding signed iPad candidate preserved its complete Application Support
and NAND tree while passing Original Mario Kart Wii, Retro Rewind 6.12.4,
ordinary controller input, and the corrected three-dot menu. The stable 0.4.0
candidate then installed in place on the maintainer's iPhone and passed Retro
Rewind 6.12.5 launch, per-control hiding, and the editor's Back path while
retaining the existing app container, preferences, game data, and saves.

## External acceptance still required

- Install the exact tvOS candidate on physical Apple TV hardware and follow
  `docs/TVOS-TESTING.md` through private staging, controller input, Original and
  Retro Rewind races, relaunch, sleep/wake, and save durability.
- Keep public Retro WFC online compatibility separate until the external
  service and a live test are available.

## Release gates

- [x] Merge and verify the complete source on `main`.
- [x] Rebuild exact merged source as iOS 0.4.0 build 15 and tvOS build 3.
- [x] Pass full tests, source/safety checks, patch verification, app audits, and
      physical iPhone touch-editor acceptance.
- [x] Package each IPA twice deterministically and compare bytes.
- [x] Audit exact IPAs and embedded provenance/notices.
- [x] Tag the audited source and publish both IPAs plus `SHA256SUMS`.
- [x] Download hosted assets, byte-compare, checksum-verify, and re-audit.
- [x] Verify remote `main` and the dereferenced tag.

- Published source: `369159153bef0d045edf5cc1cf3b1b444b36a284`
- iPhone/iPad IPA SHA-256:
  `af80c2bc6fcabdb4eee84aed05254eccef76d7e6bbf83f2c7f21101168c665c8`
- tvOS IPA SHA-256:
  `9ee2a9b05bff56261d4d4986eca54840e98ade8ae0abd3ac623c1f2393dcf5cc`
