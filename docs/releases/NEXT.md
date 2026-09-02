# KartPad v0.3.0-preview.5 release rollup

Updated: 2026-09-02

This is the living validation record for Preview 5. User-facing notes are in
[`v0.3.0-preview.5.md`](v0.3.0-preview.5.md).

## Included changes

- Empty signed-container scans now open the working Files picker immediately;
  the secondary action is named **Import from This Installation's Folder…**.
- The native macOS runtime no longer hides the cursor after five idle seconds,
  and opening its F10/controller settings explicitly restores the pointer.
- Preview 4's experimental Mii management and macOS-only direct Wii
  Remote/Nunchuk pairing remain available without broadening their claims.

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
- Retest **Import from This Installation's Folder…** in the Issue #1 reporter's exact
  Feather-signed container.

Build success is not treated as external Mii, Wii hardware, or Files-provider
acceptance. Reports must use KartPad's bounded diagnostics and must not include
game images, extracted content, saves, complete NAND/app containers, signing
material, credentials, or device identifiers.

## Release gates

- [x] Commit and push the complete Preview 5 source to `main`.
- [x] Rebuild the exact merged source as unsigned app 0.3.0 build 12.
- [x] Pass focused contracts, source/safety checks, app audit, and patch checks.
- [x] Package twice deterministically and compare the IPA bytes.
- [x] Audit the exact IPA and its embedded provenance/notices.
- [x] Tag the audited source and publish the IPA plus `SHA256SUMS`.
- [x] Download the hosted assets, compare bytes, verify checksums, and re-audit.
- [x] Verify remote `main` and the dereferenced tag, then request reporter tests.

- Published source: `8e57ac49c161ff576d6eff198ade2ee9b21f575e`
- Hosted IPA SHA-256:
  `9b7b8c586ddd04b639dda5634e72e88dc91ccefb93762f1afde6e8006d274d14`
- Issue #1 retest request:
  `https://github.com/chrissotraidis/kartpad/issues/1#issuecomment-5508572886`
- Issue #5 retest request:
  `https://github.com/chrissotraidis/kartpad/issues/5#issuecomment-5508573157`
