# G5 portable guest-scheduler evidence

Date: 2026-08-28

Command: `./scripts/test-guest-scheduler.sh`

Host: arm64 macOS, AppleClang 21.0.0, deployment target 14.0.

## Selected strategy

Explicit cooperative guest scheduler/state machine. Translated steps return a typed yield/sleep/wait/join/exit action. No arbitrary host stack frame is preserved, no deprecated fiber API is used, and no custom ARM64 context switch is required. Every guest thread owns a complete `GuestCpuContext`. The scheduler releases its mutex before invoking a guest step, VI callback, or nested host callback.

## Results

- Release suite: Pass.
- ASan/UBSan suite: Pass with no finding.
- Million-operation fixture: Pass twice.
- Deterministic state hash: `0x7287563387fb1677` on both independent runs.
- Operations per fixture: 1,000,000 exactly.
- Four equal-priority guest contexts: 250,000 operations each.
- VI cadence: 10,000 callbacks exactly at one per 100 operations.

## Covered contracts

- Create suspended, resume/start, priority selection, yield, suspend, sleep, logical alarm wake, queue wait/send, join, cancel, exit, and reap.
- Simultaneous alarm wakeups preserve guest priority.
- Nested host callback can inspect the scheduler, proving no scheduler lock is held across a guest step.
- 10,000 create/exit/reap cycles leave zero thread records.
- Idle with only a queue waiter returns immediately instead of busy-spinning.
- Background/foreground suspension.
- Shutdown while waiting and shutdown initiated from a running guest step; no state becomes runnable afterward.
- GPR, PC/LR, CR, FPSCR, all FP bit patterns (including a NaN payload), and a 128-byte SIMD snapshot persist across switches.
- Snapshot ordering and per-thread names provide bounded watchdog/logging diagnostics.

Physical iOS background lifecycle remains a later device row. Integration with WiiCompiled's OS HLE and translated call boundaries begins at G6; this G5 result proves the scheduler contract and deterministic backend itself.
