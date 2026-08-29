# G10 Balloon Battle — Block Plaza representative match

Status: **Partial pass for PRD row 27.** The representative full match passes; the remaining nine retail arenas still need boot coverage.

## Configuration

- Final signed native arm64 KartPad product path, Metal renderer, normal launch with no diagnostic environment.
- Single Player → Battle → Balloon Battle.
- 6-v-6 teams, Mario, Standard Kart M, Manual drift.
- Wii arena: Block Plaza.
- Exactly one game instance; no Dolphin and no Simulator were running.

## Observed result

- Block Plaza loaded and rendered its arena intro.
- The full three-minute match ran to completion with 12 racers, team scoring, minimap updates, AI movement, item effects, ink, balloon loss, and kart movement/steering observed.
- Final score was red 9, blue 13; the player row appeared in the result table.
- The `Next Battle / Quit` result menu appeared, and Quit returned cleanly to Main Menu.
- Renderer labels observed during interaction/capture ranged from 43.2 to 60.0 FPS. This row proves functional completion, not G11 cadence; the lower samples remain performance evidence to measure under the dedicated deterministic G11 method.

## Evidence

- `teams.jpeg` — 6-v-6 team assignment.
- `block-plaza-selection.jpeg` — Block Plaza retail arena selection.
- `match-active.jpeg` — active 12-racer match with timer, score, balloons, and minimap.
- `movement-playtest.jpeg` — changed player position after acceleration/steering input.
- `results.jpeg` — completed match result table and 9–13 final score.
- `result-menu.jpeg` — `Next Battle / Quit` transition.
- `main-menu-return.jpeg` — clean return to Main Menu.

No private save, disc content, user path, or personal data is present in the evidence.

## Remaining row work

Boot Delfino Pier, Funky Stadium, Chain Chomp Roulette, Thwomp Desert, SNES Battle Course 4, GBA Battle Course 3, N64 Skyscraper, GCN Cookie Land, and DS Twilight House. A second full Block Plaza match is unnecessary unless a changed variable requires regression.
