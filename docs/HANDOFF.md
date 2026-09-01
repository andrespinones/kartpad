# KartPad handoff

## Current state

KartPad `v0.3.0-preview.2` is published from
`9240b44cf37ff474bfc527a5f430c05c226f685d`. The hosted unsigned iPhone/iPad
IPA is app 0.3.0 build 9 and has SHA-256
`18c9549656aef815e57552d63e1cfec79bcd69cd9de622e4b5a1e026404c6f36`.
The hosted artifact matches the local audited candidate byte-for-byte.

Preview 2 adds the missing iOS open-in-place declaration, prepares the
Files-visible KartPad directory before first launch, and makes A's one-second
hold a real lock that releases on the next tap. The full device build, app
audit, deterministic packaging, hosted checksum, and fresh hosted re-audit
pass. Issues #1 and #2 remain open for reporter confirmation on their exact
iPads and file providers.

The preview offers Original Mario Kart Wii or optional Retro Rewind 6.12.4.
A physical iPad completed the official pack download, verification,
installation, launch, and a playable single-player match. General physical
execution is accepted on iPad and iPhone. Retro WFC remains unavailable during
external service maintenance; live public online play is not claimed and does
not block offline Retro Rewind support.

## Next executable work

1. Continue representative performance and frame-pacing work without changing
   the accepted 0.3.0 release baseline.
2. Complete the remaining three- and four-player, touch, motion, controller,
   audio, thermal, lifecycle, and long-soak rows in `docs/PRD.md`.
3. When Retro WFC returns, retest production login, matchmaking, a complete
   race, results, reconnect, and physical-device online play.
4. Follow `docs/UPSTREAM_UPDATES.md` whenever WiiCompiled or Retro Rewind
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
