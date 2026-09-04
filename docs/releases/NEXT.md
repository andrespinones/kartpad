# KartPad v0.4.2 release rollup

Updated: 2026-09-04

This is the living validation record for the KartPad 0.4.2 maintenance release.
User-facing notes are in [`v0.4.2.md`](v0.4.2.md).

## Included changes

- The complete stable 0.4.0 iPhone/iPad feature set and Retro Rewind 6.12.5
  graph.
- The 0.4.1 tvOS cache-root storage correction.
- Guest `SCGetAspectRatio` state synchronized with the existing mobile host
  aspect selection.
- A generic tvOS AArch64 compiler baseline with RCpc explicitly disabled.
- Build-time verification of the required Clang forwarding sequence and a
  final-binary audit rejecting RCpc load instructions.
- iPhone/iPad app 0.4.2 build 16 and tvOS app 0.4.2 build 5.

## Accepted baseline

The stable 0.4.0 candidate installed in place on the maintainer's iPhone and
passed Retro Rewind 6.12.5 launch, per-control hiding, and the editor's Back
path while retaining the existing app container, preferences, game data, and
saves. Version 0.4.2 does not alter those host paths.

## External acceptance still required

- Install the exact tvOS candidate on physical Apple TV hardware and follow
  `docs/TVOS-TESTING.md` through private staging, controller input, Original and
  Retro Rewind races, relaunch, sleep/wake, and save durability.
- Keep public Retro WFC online compatibility separate until the external
  service and a live test are available.

## Release gates

- [x] Merge and verify the complete release source on `main`.
- [x] Rebuild exact merged source as iOS 0.4.2 build 16 and tvOS build 5.
- [x] Pass full tests, source/safety checks, patch verification, and app audits.
- [x] Package each IPA twice deterministically and compare bytes.
- [x] Audit exact IPAs and embedded provenance/notices.
- [x] Tag the audited source and publish both IPAs plus `SHA256SUMS`.
- [x] Download hosted assets, byte-compare, checksum-verify, and re-audit.
- [x] Verify remote `main` and the dereferenced tag.

Published source: `776a2a6a0e367b6d06f627c983f5da4a565ea104`.
iPhone/iPad IPA SHA-256:
`4c498de9a858bf9d59e6f082ebbe7a34e64935831601dc0981de42be8a8d473e`.
Experimental tvOS IPA SHA-256:
`0802f7e572da3df9b8daf5b09b45717584fad33c07d8be4ba5c6d8fadceaab3f`.

Physical acceptance of the exact tvOS release remains open and is required
before any A12 compatibility or supported Apple TV claim.
