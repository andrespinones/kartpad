# KartPad handoff

## Current state

The current working tree is the Preview 4 release candidate, app 0.3.0 build
11. It adds experimental cross-platform Mii import/management and experimental
macOS-only direct Wii Remote/Nunchuk pairing. The format, storage, staging,
backup, UI, build, package, entitlement, and cancel-path contracts pass; real
exported Mii rendering and physical Wii hardware remain reporter acceptance
gates. Continue the release record in `docs/releases/NEXT.md`.

The immediately preceding signed iPad candidate was installed in place and
preserved the complete 5,745-file, 4.8-GB KartPad Application Support/NAND tree
byte-for-byte. Hands-on testing accepted Retro Rewind, ordinary controller
input, the repaired and reorganized three-dot menu, exit/reopen lifecycle,
Original Mario Kart Wii, and the existing license.

KartPad `v0.3.0-preview.3` is published from
`452af2dde3d19508a5e6ced6c03deb0e24b8b509`. The hosted unsigned iPhone/iPad
IPA is app 0.3.0 build 10 and has SHA-256
`e839c115a97867949b16fa1c4a2a3472dce4eb3da6c69fff6f40c3eca2abbdcf`.
The hosted artifact matches the local audited candidate byte-for-byte.

Preview 3 asks Files providers for a local picker copy and scans app-folder
disc extensions before provider package/directory metadata. User files placed
in the KartPad folder are preserved; only temporary picker copies are removed.
The full device build, app audit, deterministic packaging, hosted checksum,
and fresh hosted re-audit pass. Issue #1 remains open for reporter confirmation
on the exact affected iPad and Files provider.

The preview offers Original Mario Kart Wii or optional Retro Rewind 6.12.4.
A physical iPad completed the official pack download, verification,
installation, launch, and a playable single-player match. General physical
execution is accepted on iPad and iPhone. Retro WFC remains unavailable during
external service maintenance; live public online play is not claimed and does
not block offline Retro Rewind support.

## Next executable work

1. Finish Preview 4 source, device, deterministic-package, hosted-download,
   and tag/main verification, then request Issue #5 reporter testing.
2. Continue representative performance and frame-pacing work without changing
   the accepted 0.3.0 release baseline.
3. Complete the remaining three- and four-player, touch, motion, controller,
   audio, thermal, lifecycle, and long-soak rows in `docs/PRD.md`.
4. When Retro WFC returns, retest production login, matchmaking, a complete
   race, results, reconnect, and physical-device online play.
5. Follow `docs/UPSTREAM_UPDATES.md` whenever WiiCompiled or Retro Rewind
   advances; never accept an unpinned pack or `Code.pul`.

## Operating constraints

- Preserve user game data, Retro Rewind content, saves, and signing state.
- Never commit or publish a disc image, extracted assets, translated source
  shards, saves, credentials, signing material, device identifiers, or private
  captures.
- Use no more than one Simulator at a time and close it after validation.
- Recheck available storage before rebuilding large dependency or translation
  graphs.
- Keep build proof, physical acceptance, public distribution, performance, and
  live-service online acceptance as separate claims.
