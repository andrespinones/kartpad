# G10 items, AI, and collisions

Status: **Pass for PRD row 25.** Heavy 12-racer item fixtures complete correctly through results.

## Accepted native fixtures

- Balloon Battle, Block Plaza: complete three-minute 6-v-6 match with all 12 racers, active AI movement, item boxes/effects, Blooper ink, balloon loss, collisions, team score changes, minimap updates, result table, and Main Menu return. Evidence: `docs/artifacts/2026-08-29/g10-balloon-battle/`.
- Coin Runners, Block Plaza: two complete three-minute 6-v-6 matches with all 12 racers, coins, items, AI movement, collisions, changing team/individual totals, full results, and Main Menu return. Evidence: `docs/artifacts/2026-08-29/g10-coin-runners/`.
- Changed vehicle fixture: Bowser on Standard Bike L with Automatic drift completed another 12-racer Balloon Battle while receiving ink/item effects and colliding with arena geometry and racers. Evidence: `docs/artifacts/2026-08-29/g10-vehicle-character-drift/`.
- The earlier 100cc Luigi Circuit VS race also ran a full 12-racer item/AI session through standings and menu transition. Evidence: `docs/artifacts/2026-08-28/g9-race-save/`.

Across the independent fixtures, 12-racer AI, item load, collisions, effects, scoring/standings, finish/result logic, and clean mode exit all execute without a P0/P1 defect. This row reuses accepted changed-variable evidence and does not require another identical match.
