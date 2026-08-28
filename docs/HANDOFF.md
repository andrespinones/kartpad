# KartPad handoff

## Current state

G0 is at its repository-safety/checkpoint gate. The approved PRD and execution loop were read completely, the repository and host were inventoried, no Simulator is booted, and the evidence/safety scaffolding exists. The WBFS is a verified read-only `RMCP01` revision 0 input. WiiCompiled is pinned at the required commit/tree with push disabled.

## Next executable step

1. Run `./scripts/check-repo-safety.sh` and `git diff --check`.
2. Create and push the first reviewed GitHub checkpoint.
3. Inspect WiiCompiled's required source surface and licenses.
4. Pin the remaining required reference repositories without exceeding safe host storage.

## Known constraints

The host had about 21 GiB free at session start. Recheck before large dependency fetches or builds. Do not boot more than one Simulator and do not commit the WBFS, extracted/generated game data, local SunPad checkout, signing data, saves, or captures.
