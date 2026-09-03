# KartPad release checklist

## tvOS experimental candidate

- [x] Publish the physically untested artifact only as an explicit hardware-
      bring-up preview and direct initial testing to a small Apple TV cohort
      using [`docs/TVOS-TESTING.md`](TVOS-TESTING.md) and the acceptance matrix
      in [`docs/TVOS.md`](TVOS.md).
- [x] Label that artifact experimental and unaccepted until tester evidence
      completes the physical Apple TV matrix.
- [ ] Prove Original and Retro Rewind gameplay separately with an Extended
      Gamepad; do not infer Retro WFC acceptance from offline play.
- [ ] Back up and rehearse restore of Application Support/NAND before asking a
      tester to risk saved progress.
- [ ] Re-audit the exact signed tester artifact for private game data, Retro
      Rewind content, derived game artwork, signing material, and local paths.

The exact 67-row matrix in `docs/PRD.md` remains the authority for full
engineering completion. A community preview may ship with narrower, explicit
limitations when its exact artifact passes every preview gate below.

## 0.4.0 stable candidate

- [x] Physical iPhone launches Retro Rewind 6.12.5 with existing data intact
- [x] Physical iPhone accepts per-control Hide/Show and the editor Back path
- [x] Untouched-iPhone default seeding preserves custom iPhone and iPad layouts
- [x] Full tests, source pins, repository safety, and SunPad snapshot pass
- [ ] Exact merged source produces iPhone/iPad build 15 and tvOS build 3
- [ ] Both IPAs package twice byte-identically and pass extraction audits
- [ ] Stable tag, hosted assets, checksums, and hosted re-audits match locally
- [ ] Remote `main` and dereferenced `v0.4.0` match the audited source

## 0.4.0 Preview 2 candidate

- [x] Official Retro Rewind 6.12.5 archive, code, XML, and upstream source pins
- [x] Fresh 6.12.5 translation graph passes strict function and patch gates
- [x] Kamek v2/v3 parser keeps file and command bounds validation
- [x] Universal iPhone/iPad menu refresh cannot restore the SunPad menu
- [x] Daily upstream-version check and deterministic profile updater
- [x] Exact merged source produces iPhone/iPad build 14 and tvOS build 2
- [x] Both IPAs package twice byte-identically and pass fresh extraction audits
- [x] Release tag, hosted assets, checksums, and hosted re-audits match locally
- [ ] Physical testers accept the 6.12.5 flow and the Apple TV matrix

Published source: `e9fa6058ee09fff0b16481ebe4a78d61cea69c87`.
iPhone/iPad IPA SHA-256:
`a796cd0e29bfd47d78afc50989a959803f9eff434252a3a455af85308b380fe6`.
tvOS IPA SHA-256:
`3f8f529a93cc3f1ddfe9e9b71171ba56ead5a49ae3598c449a42f00eed6c5a9a`.

## 0.4.0 Preview 1 candidate

- [x] Independent native `KartPadDual` tvOS implementation and full arm64 build
- [x] Original three-layer Apple TV icon and Top Shelf catalog compile and audit
- [x] Durable Application Support is separated from purgeable game/mod caches
- [x] Retro Rewind temporary-download lifetime is safe and its pack remains
      pinned, size checked, and SHA-256 verified
- [x] Tester-specific bundle identifiers work across build, audit, staging,
      backup, and diagnostic scripts
- [x] Exact merged source produces iPhone/iPad build 13 and tvOS build 1
- [x] Both IPAs package twice byte-identically and pass fresh extraction audits
- [x] Release tag, hosted assets, checksums, and hosted re-audits match locally
- [x] PR #7 receives an accurate closure response after the replacement lands

Published source: `4d32dfac683966ea1cb4f72963deffbe936404da`.
iPhone/iPad IPA SHA-256:
`5b959d7a6abba43db3d557bbba3dc3a1ab913650f0717cdf8600afa06fcb32c1`.
tvOS IPA SHA-256:
`78dcdf28c947330d480fcc789f0b81b95bafe94497c56f9c26bb6249c5362df1`.

## Published 0.3.0 preview

- [x] Exact source pins, notices, and reproducible dependency graph
- [x] Supported disc identity and private game-data boundary
- [x] Dual-mode Original / Retro Rewind graph and official version lock
- [x] iPhone/iPad ARM64 build, package, privacy, and signature-residue audits
- [x] Physical iPad Retro Rewind download, verification, installation, launch,
      and initial single-player gameplay
- [x] Deterministic IPA packaging and SHA-256 checksum
- [x] Embedded install guide, release notes, provenance, rights, and licenses
- [x] Hosted IPA downloaded, byte-compared, checksum-verified, and re-audited
- [x] Dereferenced release tag and hosted artifact provenance match the audited
      source commit

Published artifact: `v0.3.0-preview.3`, app 0.3.0 build 10, source
`452af2dde3d19508a5e6ced6c03deb0e24b8b509`, IPA SHA-256
`e839c115a97867949b16fa1c4a2a3472dce4eb3da6c69fff6f40c3eca2abbdcf`.

## Published 0.3.0 Preview 4

- [x] Experimental Mii database and Apple integration contracts pass
- [x] Experimental macOS Wii pairing compiles, links, packages, and carries
      Bluetooth permission
- [x] Pre-release iPad in-place install preserves the complete KartPad
      Application Support/NAND tree byte-for-byte and remains running
- [x] Exact merged-main app 0.3.0 build 11 passes the device-app audit
- [x] Two deterministic IPA packages match byte-for-byte
- [x] Exact IPA provenance, notices, privacy, and signature-residue audit pass
- [x] Hosted IPA and checksum match the local audited artifacts byte-for-byte
- [x] Dereferenced `v0.3.0-preview.4` tag matches the artifact source commit
- [x] Issue #5 receives the bounded external Mii and Wii hardware test request

Published artifact: `v0.3.0-preview.4`, app 0.3.0 build 11, source
`3e43c002d60378bd4975c4637a8e3a149f2d733e`, IPA SHA-256
`6bd4a3bd6a8582dd193093dda7471cecee2cafd7450f51ea59454329a1529b9e`.

## 0.3.0 Preview 5

- [x] Empty signed-container scan falls through directly to the Files picker
- [x] macOS source removes cursor auto-hide and restores the pointer for settings
- [x] Focused import, menu, Mii/Wii, and cursor contracts pass
- [x] Exact app 0.3.0 build 12 passes device build and package audit
- [x] Two deterministic IPA packages match byte-for-byte
- [x] Hosted IPA/checksum match and the downloaded IPA passes a fresh audit
- [x] Issue #1 and Issue #5 receive focused retest instructions

Published artifact: `v0.3.0-preview.5`, app 0.3.0 build 12, source
`8e57ac49c161ff576d6eff198ade2ee9b21f575e`, IPA SHA-256
`9b7b8c586ddd04b639dda5634e72e88dc91ccefb93762f1afde6e8006d274d14`.

## Full engineering-completion gates still open

- [ ] Stable representative performance and frame pacing across supported
      devices and tracks
- [ ] Complete three- and four-player result paths
- [ ] Required long-duration soak coverage
- [ ] Complete touch, motion, controller, audio, thermal, and lifecycle matrix
- [ ] Production Retro WFC and external-client acceptance after service recovery
- [ ] Clean fresh-checkout provisioning across every intended target
- [ ] No remaining P0/P1 defects and complete exact-candidate evidence index
