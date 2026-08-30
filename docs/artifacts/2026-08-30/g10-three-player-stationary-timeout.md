# G10 three-player stationary timeout experiment

Date: 2026-08-30  
Classification: inconclusive for PRD row 30; tactic rejected

## Question

Can a normal three-player VS race reach the retail DNF/standings transition
without synthetic driving if the nine CPU racers finish while the three local
players remain stationary?

## Controlled run

- Exact audited source package: `2cfb7e1`, bundle-content SHA-256
  `dc6ecdca64df7a031fde00ab63472f0130674e8705bd27196483d6a0005615de`.
- One KartPad process; no Dolphin and no booted Simulator.
- Registered three independent keyboard-backed Classic-controller channels.
- Selected Mario/P1, Luigi/P2, and Yoshi/P3 with distinct standard karts,
  automatic drift, 100cc solo VS, and Luigi Circuit.
- No race-driving fixture or private ghost input was enabled. All three local
  racers remained at the start while the normal CPU field raced.

The four retail panes rendered continuously. Once live gameplay began, the
mode held its expected 30 Hz cadence for approximately 310 seconds: typical
windows were 29.94–30.10 effective FPS with p50 around 33.2–33.6 ms and p99
around 33.9–35.4 ms. The CPU field repeatedly circulated, but no FINISH, DNF
countdown, results, or standings transition occurred while every local player
remained unfinished.

Audio telemetry rose from zero to 29 dropped blocks / 11,136 bytes during the
live three-player interval. The final submitted-byte count was 69,194,496 and
the maximum observed queue depth was 15,236 of 15,360 bytes. This is a bounded
fail signal, not subjective audio acceptance.

The private console log SHA-256 is
`5205ad2a116886151d9bb2c25e381cc571a266abc7a584c45d598399e86b4028`.
KartPad returned through the normal pause/quit flow and Command-Q, recorded
`endedCleanly=yes`, and preserved `rksys.dat` byte-for-byte at SHA-256
`ad79c24bc5eb0ba6bc8cd2836a55680621892b578a04ea49d8884a71a42c563a`.

## Decision

The stationary-player shortcut is falsified and must not be repeated
unchanged. Normal three-/four-player standings evidence still requires at
least one local player to complete the race, followed by the retail timeout for
the remaining slots. Sustained physical input or a separately proven normal
input-driving method is therefore a genuine hands-on prerequisite. The
observed three-player audio drops also remain open for G10/G11.

