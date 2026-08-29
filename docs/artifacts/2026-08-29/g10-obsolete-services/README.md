# G10 obsolete Nintendo service paths

Status: **Pass for the offline G10 graceful-failure requirement.** This is not G12 online-service acceptance.

The sole native arm64 KartPad process exercised both retail entry points without Dolphin or a booted Simulator:

- Nintendo WFC (1P) presented its original disclosure and privacy warning instead of silently sending data. Choosing **Do Not Allow**, then affirming that privacy-safe choice, returned cleanly to Main Menu with the explicit warning that WFC play would be unavailable.
- Mario Kart Channel opened its retail Friends/Ghost Data/Rankings/Competitions shell. Time Trial Rankings opened the local course/ranking map without a hang, crash, or forced network dependency.
- The process closed normally. Its private log contains the retail DWC initialization banner and no error, exception, panic, or failed-service record.
- The live RKSYS SHA-256 remained `f09f809cb13bedb6959cf05aeb550fe7c19db2ea74fcc3cf61665d5b0b7b90ec`, byte-identical to the documented all-cups fixture. The privacy-safe traversal did not corrupt or unexpectedly rewrite the save.

The run intentionally did not consent to transmitting Mii, nickname, records, or ghost data to an obsolete public endpoint. External-service interoperability belongs to the separately gated G12 local-server/external-service workflow.

## Evidence

- `wfc-disclosure.png` — bounded original data-sharing disclosure.
- `wfc-private-refusal-confirmation.png` — explicit recoverable no-sharing choice.
- `wfc-clean-main-menu-return.png` — clean Main Menu return.
- `channel-menu.png` — Mario Kart Channel shell.
- `channel-local-ranking-map.png` — local Time Trial ranking map.
- Private state-trace SHA-256: `02eb3c43f1d10302301472ae38dadf976c568297aac639a4da28f6123c4fc186`.
- Private console-log SHA-256: `71269bd71150c5016ac5d5a252dba92acf9cf59d15340fcb52aeed2f5d5a2e6f`.

The log recorded 1,327 audio-queue drops under the heavily loaded GUI-capture session and is explicitly rejected from audio or performance acceptance.
