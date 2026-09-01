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

Published artifact: `v0.3.0-preview.1`, app 0.3.0 build 8, source
`142a56f326fb62a5caa615315fd2ec3e6d8800d0`, IPA SHA-256
`66c873ea48c966f9c1eba850da2d8d0368696909b6b6416bed05c2a4b0d4de5e`.

## Full engineering-completion gates still open

- [ ] Stable representative performance and frame pacing across supported
      devices and tracks
- [ ] Complete three- and four-player result paths
- [ ] Required long-duration soak coverage
- [ ] Complete touch, motion, controller, audio, thermal, and lifecycle matrix
- [ ] Production Retro WFC and external-client acceptance after service recovery
- [ ] Clean fresh-checkout provisioning across every intended target
- [ ] No remaining P0/P1 defects and complete exact-candidate evidence index
