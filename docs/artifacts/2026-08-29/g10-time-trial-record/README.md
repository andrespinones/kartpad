# G10 Time Trial record lifecycle

Status: **Pass for PRD row 26.** The native macOS product recorded, saved, loaded, replayed, and authentically replaced a personal Time Trial ghost and record.

## Candidate and scope

- Target: Apple M2, native arm64, macOS 26.5, ad-hoc-signed `KartPadRuntime.app`.
- Executable SHA-256: `fa86a907ca2bebbc72eec1baf02cd83f3ceb816e584e33ed3dd23926ab945545`.
- Public Apple-runtime patch SHA-256: `c7aa6bdcdba3dd49bcfb325bbb0074d2a92ee9a6a4c208dbbc1edbb1aabc78be`.
- Product input: the user's read-only, validated PAL `RMCP01` revision-0 disc. No disc or save content is published here.
- Instance discipline: exactly one native KartPad process, no Dolphin, and no booted Simulator.

## Create, save, load, and replay

- Mode: Time Trials → Lightning Cup → SNES Mario Circuit 3.
- An exact regular Nintendo staff input completed at `01:38.880` as Mario, Standard Kart M, Manual. The retail result flow displayed `Saved ghost data for Player!`.
- Private trace SHA-256: `63d39c254ad103563da15a7edf9b7632151b95e7fb8ce3f8b8d1c0cb0a951302`. The strict state summary accepts race time `240..6166`, 5,927 consecutive racing samples, followed by finish stage 4.
- A fresh process loaded the `Player 01:38.880` card. `Watch Replay` consumed the complete stored personal stream, reached the finish/result flow, and then entered the retail automatic replay loop.

## Authentic replacement

Mario Kart Wii replaces its personal course ghost by beating the stored personal best; the retail Time Trial UI does not expose a standalone delete command for this ghost type. The separate Mario Kart Channel erase flow applies to downloaded ghosts. Row 26's delete/replace behavior is therefore covered through the authentic personal-best replacement path.

To make that path testable without changing the stored ghost stream, `scripts/create-slower-tt-record-fixture.py` produced an ignored private save copy whose only semantic change was the selected primary leaderboard timer (`09:59.999`), plus the required core CRC. The tool validates size, magic/version, license, personal-ghost presence, and CRC; refuses in-place or overwrite operation; and its self-test proves the stored ghost payload and every unrelated byte remain unchanged.

- The replacement race used only normal live keyboard input through the shipping controller bridge. It used real vehicle physics, checkpoints, lap counting, and the retail recorder; no RKG fixture environment was active.
- Mario, Standard Kart M, Automatic completed in `05:01.445`, with laps `01:22.722`, `02:01.919`, and `01:36.804`. The result again displayed `Saved ghost data for Player!`.
- Private replacement trace SHA-256: `6952a947f8c7ebb1ae42d3e9e8557a9c5c55c89501a718bc3f63458e922f6309`. The strict summary accepts race time `240..18308`, 18,069 consecutive racing samples, followed by finish stage 4.
- Final live RKSYS SHA-256: `ad79c24bc5eb0ba6bc8cd2836a55680621892b578a04ea49d8884a71a42c563a`.
- A second fresh process loaded the replaced `Player 05:01.445` card, proving durable replacement. Its bounded normal-load audio telemetry reached 49,152 checks and 18,873,984 submitted bytes with zero post-start empty observations and zero dropped blocks.

## Evidence

- `saved-ghost-result.png` — retail confirmation after the initial personal ghost save.
- `reloaded-record.png` — initial `Player 01:38.880` record after fresh launch.
- `replay-start.png`, `replay-live.png`, `replay-finish.png`, `replay-result.png`, and `replay-complete.png` — stored personal replay lifecycle.
- `replaced-record-result.png` — retail confirmation after the live `05:01.445` replacement; SHA-256 `ea6726a459eb48283dbfca3e9e81e0e70e52341eccda75a306fb7861a41ef529`.
- `reloaded-replaced-record.png` — fresh-process `Player 05:01.445` card; SHA-256 `c9bc572ce486c6e5ce938dffe31f0396112d0ab76f07c56b531eb3f2099f3c1b`.

## Rejected diagnostic attempts

- An expert staff stream diverged under the live-player path and was rejected.
- Both staff and personal streams started from a different grid origin when challenging an existing PB; neither was used as replacement evidence.
- A slow unguided live run overflowed the retail ghost recorder after more than six minutes and displayed `GHOST DATA CANNOT BE SAVED`; it was rejected.

These failures are retained only in ignored private traces. The accepted replacement is the later complete, live-input, normally recorded race described above.
