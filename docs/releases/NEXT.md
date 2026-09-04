# KartPad v0.4.3 release rollup

Updated: 2026-09-05

This is the living validation record for the KartPad 0.4.3 community
maintenance release. User-facing notes are in [`v0.4.3.md`](v0.4.3.md).

## Included changes

- Profile-aware dynamic dispatch for Retro Rewind cup and course names.
- Installed-version startup guard for viewport policy reapplication.
- Lower-latency iOS audio buffering and producer queue limits.
- An opt-in, default-off iPhone shake gesture for tricks and bike wheelies.
- A maintainer-owned repair keeping the patched Kamek translator tests aligned
  with the existing v2/v3 fixture names.
- iPhone/iPad app 0.4.3 build 17 and tvOS app 0.4.3 build 6.
- No Android changes.

## Acceptance and boundaries

The contributor tested the four fixes together on an iPhone 17 Pro. Maintainer
validation independently covered the merged translation output, complete test
suites, unsigned iPhoneOS build, and app audit. This evidence does not establish
older-device audio performance or physical acceptance of the exact public
artifacts. Existing game-data, settings, and save paths are unchanged.

The Apple TV package receives only the shared Retro Rewind dispatch correction.
Physical acceptance of the exact tvOS artifact remains open.

## Release gates

- [x] Review each external pull request at its exact head.
- [x] Merge accepted contributions individually with contributor attribution.
- [x] Validate the combined source, translator, native tests, and iPhoneOS app.
- [ ] Merge and verify the complete release source on `main`.
- [ ] Rebuild exact merged source as iOS 0.4.3 build 17 and tvOS build 6.
- [ ] Package each IPA twice deterministically and compare bytes.
- [ ] Audit exact IPAs and embedded provenance/notices.
- [ ] Tag the audited source and publish both IPAs plus `SHA256SUMS`.
- [ ] Download hosted assets, byte-compare, checksum-verify, and re-audit.
- [ ] Verify remote `main` and the dereferenced tag.
