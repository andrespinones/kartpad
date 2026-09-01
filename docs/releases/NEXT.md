# KartPad v0.3.0-preview.4 release rollup

Updated: 2026-09-02

This is the living validation record for Preview 4. Immutable user-facing notes
are in [`v0.3.0-preview.4.md`](v0.3.0-preview.4.md).

## Included changes

- Experimental standard 74-byte `.mii` import, listing, staged removal, backup,
  and next-launch activation on Mac, iPhone, and iPad.
- Experimental direct Bluetooth pairing for original and Plus Wii Remotes on
  macOS, with SDL handoff and a Wii Remote/Nunchuk controller preset.
- Stable three-dot-menu appearance and lifecycle behavior, with clearer
  Controls and Display submenus.
- Bounded KartPad-folder import failures with signer/container guidance and a
  direct **Choose from Files…** fallback.

RetroAchievements remains researched and deferred in
[`docs/FUTURE-FEATURES.md`](../FUTURE-FEATURES.md).

## Accepted baseline

The preceding signed iPad candidate was installed in place over
`dev.kartpad.app`. The complete 5,745-file, 4.8-GB Application Support/NAND tree
matched byte-for-byte before and after installation. KartPad launched and
remained running. Earlier hands-on checks accepted Retro Rewind 6.12.4, Original
Mario Kart Wii, the existing license, ordinary controller input, and the
repaired three-dot menu through exit/reopen and mode changes.

The experimental Mii database logic passes format, header, CRC, duplicate,
capacity, list, removal, backup, staging, and atomic-activation tests. The
macOS Wii pairing path compiles, links, packages with Bluetooth permission, and
cleans up discovery and SDL state when its panel closes.

## External acceptance still required

- Import a real exported `.mii`, restart, select it through License Settings →
  Change Mii, and confirm its name and appearance.
- Pair an original or Plus Wii Remote on macOS, attach a Nunchuk, select the
  experimental preset, and test all race/menu inputs plus disconnect/reconnect.
- Retest **Import from KartPad Folder** in the Issue #1 reporter's exact
  Feather-signed container.

Build success is not treated as external Mii, Wii hardware, or Files-provider
acceptance. Reports must use KartPad's bounded diagnostics and must not include
game images, extracted content, saves, complete NAND/app containers, signing
material, credentials, or device identifiers.

## Release gates

- [ ] Commit and push the complete Preview 4 source to `main`.
- [ ] Rebuild the exact merged source as unsigned app 0.3.0 build 11.
- [ ] Pass focused contracts, source/safety checks, app audit, and patch checks.
- [ ] Package twice deterministically and compare the IPA bytes.
- [ ] Audit the exact IPA and its embedded provenance/notices.
- [ ] Tag the audited source and publish the IPA plus `SHA256SUMS`.
- [ ] Download the hosted assets anonymously, compare bytes, verify checksums,
      and re-audit the downloaded IPA.
- [ ] Verify remote `main` and the dereferenced tag, then request Issue #5
      reporter testing.
