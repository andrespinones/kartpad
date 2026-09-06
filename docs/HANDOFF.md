# KartPad handoff

## Current state

KartPad `v0.4.4` is published as the latest stable community release from
`3b857f9ae2b7933c6eb4f8f8f61a07df6b455624`. The iPhone/iPad app 0.4.4 build
18 IPA has SHA-256
`5d2428abe9e4e0a7736912669c05fe8b40d3d5b34fcf85d05f3d31f336c6ed11`;
the experimental tvOS app 0.4.4 build 7 IPA has SHA-256
`b508d45fc4426190e7c25c6f57c31ec838f71f02a666feb07b06ca379a976f66`.
Both exact-source builds and two independent packages per platform pass. Fresh
anonymous hosted downloads match the local bytes, checksums, provenance, and
audits. The release advances the verified pack and AOT graph to Retro Rewind
6.12.7. It also makes the daily watcher open one deduplicated compatibility
issue and adds a resumable one-command profile updater. Retro WFC service
recovery is verified; exact 0.4.4 production gameplay and physical-device
acceptance remain open. Apple TV remains experimental.

The Issue #17 reporter accepted the exact public `v0.4.1` tvOS storage hotfix on
an Apple TV 4K (3rd generation) running tvOS 26.5/26.6. Config writes no longer
raise error 513, both profiles launch, NAND/save and settings changes survive a
normal relaunch, and the cache-root backup script succeeds. This resolves the
reported storage defect without establishing the still-open 0.4.3, A12,
sleep/wake, restore, multi-controller, purge-recovery, or sustained-performance
gates.

The `codex/iphone-touch-layout-editor` candidate captures the maintainer's
current physical-iPhone control positions as the default for untouched iPhone
installs only. Existing custom layouts and every iPad layout remain unchanged.
The editor lets a user hide or restore individual controls, treats the four
D-pad directions as one control, and returns to Touch Control Settings through
an explicit **Back** action. The D-pad remains present by default because it
drives tricks and wheelies. Source contracts, the pinned SunPad snapshot, a
fresh unsigned device build, app audit, signed in-place installation, launch,
and before/after save and preference checks pass. The maintainer then accepted
Retro Rewind launch, per-control hiding, and the editor's Back path on the
physical iPhone. These results clear the iPhone gate for the stable 0.4.0
release; physical Apple TV acceptance remains open.

KartPad `v0.4.0-preview.2` is published from
`e9fa6058ee09fff0b16481ebe4a78d61cea69c87`. It updates both Apple-platform
artifacts for Retro Rewind 6.12.5, repairs the universal iPhone/iPad three-dot
menu refresh, and adds a daily upstream-version watcher plus deterministic
profile updater. Its separate unsigned iPhone/iPad and tvOS IPAs were each
packaged twice byte-identically, and the freshly downloaded hosted artifacts
match and re-audit. Their SHA-256 values are respectively
`a796cd0e29bfd47d78afc50989a959803f9eff434252a3a455af85308b380fe6`
and `3f8f529a93cc3f1ddfe9e9b71171ba56ead5a49ae3598c449a42f00eed6c5a9a`.
The signed iPhone build 14 was installed in place, launched, and preserved the
pre-install configuration, identity, preferences, NAND, and saves byte-for-
byte. Physical 6.12.5 gameplay and Apple TV remain external acceptance gates.

KartPad `v0.3.0-preview.5` is published from
`8e57ac49c161ff576d6eff198ade2ee9b21f575e`. Its unsigned app 0.3.0 build 12
IPA has SHA-256
`9b7b8c586ddd04b639dda5634e72e88dc91ccefb93762f1afde6e8006d274d14`.
It makes an empty signed-container import scan open the normal Files picker
immediately and removes the native macOS runtime's five-second cursor auto-hide.
Exact-merge macOS and physical-iOS builds passed; both deterministic packages
and the freshly downloaded hosted artifact matched and audited cleanly.

KartPad `v0.3.0-preview.4` is published from
`3e43c002d60378bd4975c4637a8e3a149f2d733e`. Its unsigned app 0.3.0 build 11
IPA has SHA-256
`6bd4a3bd6a8582dd193093dda7471cecee2cafd7450f51ea59454329a1529b9e`.
Two local packages and the freshly downloaded hosted artifact are
byte-identical and pass checksum, ZIP, app, privacy, provenance,
signing-residue, and private-data audits. Remote main and the dereferenced tag
match the audited source commit.

Preview 4 adds experimental cross-platform Mii import/management and
experimental macOS-only direct Wii Remote/Nunchuk pairing. The format, storage,
staging, backup, UI, build, package, entitlement, and cancel-path contracts
pass. Issue #5 has the targeted tester request at
`https://github.com/chrissotraidis/kartpad/issues/5#issuecomment-5502139406` and
remains open for real exported Mii and physical Wii hardware results.

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

The preview offers Original Mario Kart Wii or optional Retro Rewind 6.12.5.
The preceding 6.12.4 build completed physical iPad pack download, verification,
installation, launch, and a playable single-player match. General physical
execution is accepted on iPad and iPhone. Retro WFC service recovery is now
verified, but live public online play is not claimed for the exact 0.4.4
artifact until its production and physical-device gates pass.

## Next executable work

1. Begin Android A0 on the authorized second machine using
   `docs/ANDROID-GOAL-LOOP.md`: bootstrap pinned tools and prove the source-only
   ARM64 SDL/JNI/Vulkan fixture before private game integration.
2. Collect a physical Apple TV report against the exact `v0.4.4` asset using
   `docs/TVOS-TESTING.md`.
3. Await the Issue #1 Feather-signed iPad import retest and the Issue #5 MacBook
   Air cursor/settings retest requested against Preview 5.
4. Keep Mii and physical Wii Remote/Nunchuk acceptance open until the Issue #5
   reporter can reach the settings and returns real hardware results.
5. Continue representative performance and frame-pacing work without changing
   the accepted 0.3.0 release baseline.
6. Complete the remaining three- and four-player, touch, motion, controller,
   audio, thermal, lifecycle, and long-soak rows in `docs/PRD.md`.
7. Retest production login, matchmaking, a complete race, results, reconnect,
   and physical-device online play against the recovered Retro WFC service.
8. Follow `docs/UPSTREAM_UPDATES.md` whenever WiiCompiled or Retro Rewind
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
