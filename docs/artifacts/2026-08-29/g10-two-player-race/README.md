# G10 two-player race investigation

This directory records changed-variable diagnostics for PRD row 29. It is not a passing result-cycle claim.

## Proven

- Two independent local controller channels register through the retail UI.
- P1 Mario and P2 Luigi both accept sustained acceleration and steering during native two-player Luigi Circuit.
- The split-screen renderer, AI field, item traffic, HUDs, and 60 FPS presentation remain active with both channels in use.
- `active-both-inputs.jpeg` captures both player karts displaced from their grid positions after independent input.

## Still open

- Parking both players lets the AI field continue circulating but does not trigger the multiplayer result timeout. At least one local player must make race progress.
- A countdown-synchronized retail staff RKG fixture starts without interrupting either controller, but the Time Trial line diverges from a rear/outside VS grid position. It is diagnostic only.
- Reclassifying a local player as a retail CPU during scenario construction was tested at both sides of the menu-to-race copy. Both timings caused a reproducible scene-transition crash, so the experiment was completely removed and the stable signed runtime was rebuilt.

PRD row 29 remains open until a normal two-player race reaches standings/results and exits cleanly.
