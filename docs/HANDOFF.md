# KartPad handoff

## Current state

G0 and G1 pass. The WBFS is a verified read-only `RMCP01` revision 0 input. WiiCompiled and all required reference repositories are pinned with push disabled, and the full source/disc verifier passes. The pinned translator suite passes 570/570 on arm64. Original editable icon masters and opaque exports exist under `branding/`; target asset-catalog validation remains future work. G2 is active.

## Next executable step

1. Run repository safety and diff checks, then push the pin/test/icon checkpoint.
2. Capture the Dolphin baseline oracle without running it concurrently with KartPad.
3. Complete the Windows-only portability inventory and start host contract tests.

## Known constraints

The host had about 21 GiB free at session start. Recheck before large dependency fetches or builds. Do not boot more than one Simulator and do not commit the WBFS, extracted/generated game data, local SunPad checkout, signing data, saves, or captures.
