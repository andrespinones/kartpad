# G11 bounded presentation telemetry checkpoint

Date: 2026-08-30  
Source: `2cfb7e161db8e3f4d69f658d163dcb8e3d242e6c`  
Goal: G11 instrumentation prerequisite; G11 remains open

## Change

Aurora's existing one-second presentation window now exposes p50, p95, p99,
and worst frame intervals in addition to average, p95, jitter, presented FPS,
and effective-motion FPS. KartPad emits one bounded content-free record every
300 successful presents with the timing window and queued/created pipeline
counts. The live FPS overlay shows the same four interval percentiles.

`scripts/summarize-present-telemetry.py` strictly parses the records, rejects
malformed lines, invalid percentile ordering, invalid timing values, and
non-monotonic present/created-pipeline counters, then emits a JSON session
summary. Its synthetic self-test passes.

The immutable Aurora checkout is never edited. Mac and mobile preparation copy
it into their ignored source graph and apply the tracked telemetry patch there.

## Build and packaging

The new full Mac source graph configured against all 29,065 translated base
functions. The first compile failed because a relative translation argument
made `build/generated` resolve below `build/` rather than the repository. The
preparation script now canonicalizes all three caller-supplied paths. After
reconfiguration, the missing data-section assembly entered the graph and the
complete runtime linked successfully.

- raw linked runtime SHA-256:
  `dcf19ac2f6bf68cdb38af7bc781b93e2d4d31af8b1b4ad25334aec12113367e7`
- packaged unsigned-runtime SHA-256:
  `5111cd9a356d559f459407823bb47fb048ea5c4679dce523864394c13caa6dea`
- exact-package bundle-content SHA-256:
  `dc6ecdca64df7a031fde00ab63472f0130674e8705bd27196483d6a0005615de`
- fingerprint source commit:
  `2cfb7e161db8e3f4d69f658d163dcb8e3d242e6c`

The signed local package passed the full macOS package audit.

## Runtime result

The exact package reached the retail title/attract path with the new live
percentile overlay. Its short retained-cache session produced three valid
telemetry windows:

| Metric | Result |
|---|---:|
| Minimum presented/effective FPS | 59.001 |
| Maximum p99 interval | 17.701 ms |
| Maximum worst interval | 32.808 ms |
| First queued/created pipelines | 1,223 / 217 |
| Last queued/created pipelines | 865 / 575 |

The private source log SHA-256 is
`36a93032514054365f680b4c70b89eb35341d93862385e50b33458d7a267a671`.
It remains outside Git because broader runtime logs contain private paths. The
session ended through the native Command-Q route, wrote `endedCleanly=yes`,
removed the active marker, and left no game or Simulator process running.

An earlier diagnostic run of the same linked binary, before the exact source
fingerprint was repackaged, observed a 110.184 ms worst interval and 54.569
minimum effective FPS while the background queue drained. That result is a
useful fail signal, not candidate acceptance.

## Classification

**Pass for bounded presentation/pipeline instrumentation, strict summary
parsing, full Mac compilation, exact package audit, live telemetry, and clean
shutdown. G11 remains open.** This was not a controlled cold-cache/warm-cache
pair, a representative race fixture, a CPU/GPU profile, or a soak. The next
step is a reversible cache experiment using the exact package and paired audio
telemetry.
