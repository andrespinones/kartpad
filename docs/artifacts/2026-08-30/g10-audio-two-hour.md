# G10 two-hour representative audio-continuity run

Date: 2026-08-30

Classification: **Pass for long representative continuity and recovery; PRD row 33 remains in progress.** The run proves bounded queue behavior without sustained starvation across repeated complete gameplay segments. It does not prove subjective audio quality, and it is not the G11 eight-hour soak.

## Candidate and isolation

- Native arm64 executable SHA-256: `fa86a907ca2bebbc72eec1baf02cd83f3ceb816e584e33ed3dd23926ab945545`
- Exactly one KartPad process ran. No Dolphin/reference process or Simulator was active.
- The process remained visibly responsive at approximately 59–60 displayed FPS and was closed normally after 2:00:18.
- The RKSYS save remained byte-identical at SHA-256 `ad79c24bc5eb0ba6bc8cd2836a55680621892b578a04ea49d8884a71a42c563a`.
- No new crash report appeared.

## Guest-state evidence

The ignored state trace contains 425,142 samples and 23 race segments. Twenty-two segments complete the same normal personal-record replay with an exact monotonic race-time range of `240..18308`, or 18,069 samples per segment. The final segment was intentionally partial when the run ended.

- Private trace SHA-256: `a260d59371f7edb8bc295d723f4a74322e27ae4aa082800d7075fd9d93ae5ede`
- Private final-state screenshot SHA-256: `4733389bf328bc08a89df82237f6ec3af8faa3ac608f49bbd85a92111d158bbb`

This establishes continuing guest progression rather than inferring activity from process lifetime alone.

## Audio telemetry

The last observed cumulative sample reported:

- 2,408,448 queue checks
- 924,776,448 submitted bytes
- zero post-start empty-before-push observations
- 175 deliberately discarded stale blocks / 67,200 bytes
- maximum observed queue 15,316 bytes against the 15,360-byte bound
- final observed queue 8,900 bytes

The discarded bytes are approximately 0.0073% of submitted bytes. They prevent a clean-audio classification, but remained bounded and were not accompanied by sustained starvation. The telemetry stream did not emit an explicit final record, so these are the last observed cumulative counters rather than a claimed shutdown-final sample.

- Private console log SHA-256: `b59c1ad4c71fa09f3e2adc632b729097ade88f10e619c9ed18e7857dbeedc0de`

## Memory observation

A separate one-minute RSS sampler covers only the final 2,040 seconds (about 34 minutes), not the entire two-hour run. Across 35 samples it observed 227,040–263,600 KiB; the first and last samples were 257,984 and 262,000 KiB. This limited window shows no obvious runaway growth but is insufficient for the G11 leak or eight-hour-soak gate.

- Private RSS trace SHA-256: `de78383e1092ecbb9d5f233f3b56a07ab537ddb94e3134905aec06c1b8575792`

## Remaining acceptance

- Hands-on listening quality and latency remain human-only observations.
- PRD row 33 still needs its complete acceptance judgment across the already tested menu/race, pause/resume, output migration, and long-session subcases.
- PRD row 38 still requires a separate eight-hour exact-candidate soak with whole-run memory/performance coverage.
