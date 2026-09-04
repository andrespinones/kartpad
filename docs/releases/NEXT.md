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
- [x] Merge and verify the complete release source on `main`.
- [x] Rebuild exact merged source as iOS 0.4.3 build 17 and tvOS build 6.
- [x] Package each IPA twice deterministically and compare bytes.
- [x] Audit exact IPAs and embedded provenance/notices.
- [x] Tag the audited source and publish both IPAs plus `SHA256SUMS`.
- [x] Download hosted assets, byte-compare, checksum-verify, and re-audit.
- [x] Verify remote `main` and the dereferenced tag.

Published source: `2075cacbadbc6053e8fedf6179ab525003bac181`.
iPhone/iPad executable SHA-256:
`a1095e26d931768549c00213b5604f88506814c1b3badfa5f6c55a5072075b26`.
iPhone/iPad IPA SHA-256:
`a8cfe67b068064a9379a88b99e5e15e9fb982b0ef079aac64622e6f4efea8f4d`.
Experimental tvOS executable SHA-256:
`a365640bedfd81c779cd98fae9de443c1c81f42f02c19633479ecf77eaafd760`.
Experimental tvOS IPA SHA-256:
`878f27afc6900c43e07cb3330f3fa811d0cdd074cbc2f14a7e11f99e574cff31`.
