# G10 Coin Runners — all arenas and representative match

Status: **Pass for PRD row 28.** Every retail arena boots and the representative full match completes.

## Configuration

- Final signed native arm64 KartPad product path, Metal renderer, normal launch with no diagnostic environment.
- Single Player → Battle → Coin Runners.
- 6-v-6 teams, Mario, Standard Kart M, Manual drift.
- Representative full-match arena: Block Plaza.
- Exactly one game instance; no Dolphin and no booted Simulator.

## Observed result

- Block Plaza loaded and two complete three-minute matches ran with 12 racers, team coin totals, per-player coin totals, minimap updates, AI movement, items, coins, collisions, acceleration, and steering visible.
- The first completed run advanced through the default next-match path. The second was left input-free near the finish to capture the result table cleanly: red 40, blue 66, with all 12 individual totals present.
- The result flow reached the team outcome and returned cleanly to Main Menu.
- The other nine retail arenas each loaded into countdown or active match with the expected environment, Coin Runners HUD, player kart, coins, item boxes, and opponents visible.
- Each boot-only check exited through Pause → Quit and returned cleanly to Main Menu before the next arena was selected.

## Evidence

- `block-plaza-start.jpeg` — Block Plaza countdown and Coin Runners HUD.
- `block-plaza-active.jpeg` — active match, team totals, AI, coins, and minimap.
- `block-plaza-results.jpeg` — complete per-player result table.
- `block-plaza-next.jpeg` — post-match Next transition.
- `delfino-pier-boot.jpeg`, `funky-stadium-boot.jpeg`, `chain-chomp-roulette-boot.jpeg`, and `thwomp-desert-boot.jpeg` — remaining Wii arena boots.
- `snes-battle-course-4-boot.jpeg`, `gba-battle-course-3-boot.jpeg`, `n64-skyscraper-boot.jpeg`, `gcn-cookie-land-boot.jpeg`, and `ds-twilight-house-boot.jpeg` — all retro arena boots.
- `main-menu-return.jpeg` — clean return after the final arena check.

No private save, disc content, user path, or personal data is present in the evidence.

No further work remains for PRD row 28 unless a changed variable requires regression.
