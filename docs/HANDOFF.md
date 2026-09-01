# KartPad handoff

## Current state

KartPad `v0.3.0-preview.1` is published from
`142a56f326fb62a5caa615315fd2ec3e6d8800d0`. The hosted unsigned iPhone/iPad
IPA is app 0.3.0 build 8 and has SHA-256
`66c873ea48c966f9c1eba850da2d8d0368696909b6b6416bed05c2a4b0d4de5e`.
The hosted artifact matches the local audited candidate byte-for-byte.

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
