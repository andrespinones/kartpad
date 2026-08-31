# KartPad online ledger and execution loop

Online multiplayer is mandatory, but it is not supported by the current Apple
build. The pinned WiiCompiled source contains a host-socket HLE and a distinct
Retro Rewind product. The current generated graph is base-only, and the pinned
non-Windows SSL path returns failure for handshake, read, and write.

No account, credential, public-service authorization, or production-service
compatibility is currently claimed. This loop uses the pinned authorized local
server first and never commits credentials, payloads, private keys, captures,
game data, translated code, or saves.

## Active goal loop

Work from the first incomplete goal. Every implementation step must have an
immediate local test and evidence before advancing.

1. **O1 — Apple transport:** implement and contract-test BSD socket, DNS, TLS,
   plaintext Retro-WFC routing, timeout, error, and cleanup behavior on macOS
   and the iOS Simulator.
2. **O2 — Online product:** add a fail-closed private workflow that consumes an
   explicitly supplied Retro Rewind folder and payload, translates the pinned
   `Code.pul`, emits nonzero Retro Rewind shards, and builds the separate
   `RetroRewind` executable without publishing generated inputs.
3. **O3 — Local server:** build the pinned WFC server and payload, provision a
   disposable local PostgreSQL database, disable only the documented local
   version gate, and expose deterministic start/stop/health commands.
4. **O4 — Single-client state machine:** prove DNS, payload/bootstrap, TLS or
   documented plaintext transition, profile/authentication, server login, and
   clean logout from one macOS client.
5. **O5 — Local race:** run two isolated macOS clients through matchmaking,
   room formation, voting, race start, live race state, results, and cleanup.
6. **O6 — Simulator client:** repeat the single-client flow on one iPad
   Simulator, including termination, relaunch, and network failure handling.
7. **O7 — Apple-to-Apple race:** complete the local race/results flow between
   macOS and the Simulator with separate client identities and storage roots.
8. **O8 — Resilience:** run local latency, jitter, loss, disconnect, server
   outage, reconnect, and resource-leak fixtures; never stress a public server.
9. **O9 — Claim gate:** only after the exact candidate passes the documented
   local matrix and any normal authorized external-service prerequisites may
   KartPad say online multiplayer is supported. Physical-device acceptance
   remains separate and is excluded from the present machine-only loop.

## Per-state iteration

For each protocol state: name the expected transition, read the pinned client
and server implementations, add the smallest deterministic fixture, run one
client, compare encoded state/timing/error mapping/cleanup, record sanitized
evidence, and continue. Two identical failures require a changed hypothesis or
instrumentation before a third attempt.

## Baseline on 31 August 2026

- Stable Apple runtime/menu work is on `main` at `7bb1ab4`.
- Base translation: 29,065 shared base functions.
- Retro Rewind translation: zero functions; target disabled.
- Native socket/DNS loopback smoke: passed previously.
- Apple SSL/TLS backend: incomplete.
- Local WFC server and Retro-WFC payload: pinned but not yet built locally.
