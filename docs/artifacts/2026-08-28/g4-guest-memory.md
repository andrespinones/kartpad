# G4 checked guest-memory evidence

Date: 2026-08-28

Command: `./scripts/test-guest-memory.sh`

Host: arm64 macOS, AppleClang 21.0.0, deployment target 14.0.

## Result

- Release checked-memory suite: Pass.
- Debug AddressSanitizer + UndefinedBehaviorSanitizer suite: Pass; no sanitizer finding.
- Non-destructive Darwin Mach VM probe: Pass.
- Preferred reservation: `0x0000100000000000`, size 4 GiB plus guard; available on this run.
- Base-relative reservation/protect/deallocate lifecycle: Pass twice.

## Covered contracts

- Sparse representation of the complete 32-bit guest domain.
- Unsigned and signed 8/16/32/64-bit scalars.
- Every address alignment modulo scalar width.
- Big-endian byte layout and unaligned round trips.
- Cross-page legal access and region/domain-end failures.
- Shared-backing MEM1-style alias coherence in both directions.
- Overlap rejection and zero-filled deterministic initialization.
- Recoverable MMIO/EFB-style read/write dispatch.
- Executable-range write detection, including a straddled write.
- Fault context with translated function, guest PC/LR, and register dump.
- Four-thread ordered access fixture.
- 100,000 deterministic randomized 64-bit operations plus retained-state verification.
- Reset, teardown, zero-fill, and second launch.
- Guest microprogram fixture that fetches, writes, branches, calls a host function, and halts.

## Selection

The checked/table backend is the selected G4 correctness path and remains the diagnostic oracle. The preferred Mach VM range is feasible on this host, but the optimized flat backend is not accepted until shared aliases, page protections, supported fault classification/resume, and checked-oracle differential tests are implemented. No destructive fixed mapping flag was used; `VM_FLAGS_FIXED` was used without `VM_FLAGS_OVERWRITE`, so an occupied range would return `KERN_NO_SPACE`.
