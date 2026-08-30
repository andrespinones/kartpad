# Simulator Metal compiler crash classification

The user-supplied KartPad crash report records an iOS Simulator incident at
`2026-08-30 05:34:43 -0500`, after a `05:32:52` launch. The crashed executable
has arm64 UUID `69F94E4A-0116-3B5C-B351-25A9DD657317`.

Classification: **pre-mitigation occurrence of the known parallel Simulator
Metal compiler-scheduler failure; not evidence against the current candidate.**

Evidence in the supplied report:

- `EXC_BAD_ACCESS (SIGSEGV)` occurs in `pthread_getschedparam` beneath
  `MTLCompilerScheduler::assignQosToRequest`.
- Threads 9 through 14 are six concurrent Aurora `pipeline_worker()` threads.
- Those workers are creating Dawn Metal render pipelines while the main/frame
  paths wait for rendering work.

The report therefore independently corroborates the failure signature already
captured during the rejected first full-import attempt. Its launch and crash
both precede the Simulator-only worker patch at `06:02:11 -0500` and the latest
Xcode candidate at `06:56:32 -0500`. The latest candidate has arm64 UUID
`797CCC1D-A1FA-38E5-A36B-27255FC186EE` and SHA-256
`9a6cd90f15a4174369445a65875aa27627efa717e94a28bff37f1845104e3019`, so it
is not the binary represented by the report.

KartPad's reproducible Aurora patch returns one compiler worker only when
`TARGET_OS_SIMULATOR` is true and bounds background-worker telemetry to the
same count. Physical iOS and macOS retain Aurora's normal hardware-derived
policy. The repaired Simulator candidate subsequently completed two full-size
imports, a cold retail launch, the injected rollback test, true first-launch
import, interrupted recovery, and scheduled-removal regressions while reporting
one priority/one background worker, without recurrence.

The full crash report is intentionally not copied into the repository. It is a
diagnostic input, may contain host metadata, and is unnecessary to reproduce or
verify the source-level mitigation.
