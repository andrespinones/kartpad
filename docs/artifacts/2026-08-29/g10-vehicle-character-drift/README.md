# G10 vehicles, characters, weights, and drift modes

Status: **Pass for PRD row 24.** Representative karts, bikes, weight classes, Manual drift, and Automatic drift run through native gameplay.

## Coverage

| Weight | Character | Vehicle | Drift | Native result |
|---|---|---|---|---|
| Light | Baby Mario | Bit Bike / Nanobike | Manual | Official N64 Mario Raceway staff replay completes bit-exact against Dolphin; evidence in `docs/artifacts/2026-08-28/g10-native-n64-mario/` |
| Medium | Mario | Standard Kart M | Manual | Complete Balloon Battle and Coin Runners matches, including movement, steering, items, results, and Main Menu return; evidence in `docs/artifacts/2026-08-29/g10-balloon-battle/` and `docs/artifacts/2026-08-29/g10-coin-runners/` |
| Heavy | Bowser | Standard Bike L | Automatic | Complete three-minute Balloon Battle with acceleration, steering, collisions, item/ink effects, AI, scoring, results, and Main Menu return |

The three representative configurations cover both vehicle families, all three weight classes, and both drift modes. The Bowser run used the final signed native arm64 product path with no diagnostic environment, exactly one game process, no Dolphin, and no booted Simulator.

## Heavy/Automatic evidence

- `bowser-bike-automatic-start.jpeg` — Bowser on Standard Bike L at the Block Plaza countdown.
- `bowser-bike-automatic-active.jpeg` — changed position during acceleration/steering with item effects and live scoring.
- `bowser-bike-automatic-results.jpeg` — completed 12-racer result table with Bowser and bike visible.

No private save, disc content, user path, or personal data is present in the evidence.
