# KartPad release checklist

The exact 67-row matrix in `docs/PRD.md` remains the authority for full
engineering completion. A community preview may ship with narrower, explicit
limitations when its exact artifact passes every preview gate below.

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

## 0.3.0 Preview 5 candidate

- [ ] Empty signed-container scan falls through directly to the Files picker
- [ ] macOS source removes cursor auto-hide and restores the pointer for settings
- [ ] Focused import, menu, Mii/Wii, and cursor contracts pass
- [ ] Exact app 0.3.0 build 12 passes device build and package audit
- [ ] Two deterministic IPA packages match byte-for-byte
- [ ] Hosted IPA/checksum match and the downloaded IPA passes a fresh audit
- [ ] Issue #1 and Issue #5 receive focused retest instructions

## Full engineering-completion gates still open

- [ ] Stable representative performance and frame pacing across supported
      devices and tracks
- [ ] Complete three- and four-player result paths
- [ ] Required long-duration soak coverage
- [ ] Complete touch, motion, controller, audio, thermal, and lifecycle matrix
- [ ] Production Retro WFC and external-client acceptance after service recovery
- [ ] Clean fresh-checkout provisioning across every intended target
- [ ] No remaining P0/P1 defects and complete exact-candidate evidence index
