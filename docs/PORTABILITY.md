# KartPad portability ledger

## Current status

WiiCompiled has not yet been fetched at its required pin, so this ledger does not claim a source-complete Windows dependency inventory.

| Area | Baseline assumption from PRD | Apple replacement / experiment | Status |
|---|---|---|---|
| Build graph | Windows/x86-64 and Windows libraries | Explicit Darwin/arm64 target capabilities | Pending source inspection |
| Guest memory | `VirtualAlloc2`, placeholder views, VEH | Darwin Mach VM experiment plus checked oracle | Pending |
| Scheduler | Windows fibers | Portable state machine or audited ARM64 context backend | Pending |
| Renderer | Aurora/Dawn Windows path | Dawn native Metal and `CAMetalLayer` | Pending |
| Audio | Windows host path | CoreAudio/cubeb or narrow Apple backend | Pending |
| Input | SDL/Windows plus four ports | SDL on macOS; GameController/touch on mobile | Pending |
| Networking | WinSock and Windows trust/interface APIs | BSD sockets and Apple-supported trust/path APIs | Pending |
