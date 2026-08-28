# KartPad portability ledger

Updated: 2026-08-28

## G3 result

The first host boundary compiles and links natively for arm64 macOS. `kartpad_host` exposes only host-neutral C++ types and has separate Darwin/Windows source graphs for monotonic clocks, deadline sleeps, thread names, application directories, and atomic file replacement. The Darwin graph contains no Win32 library or `-march=x86-64` token. Its capability macros select Darwin, arm64, Metal, the base product, macOS, and checked guest memory explicitly.

Command: `./scripts/test-host-portability.sh`

Result: Pass — configure, compile/link, one CTest contract suite, zero failures, plus the forbidden-token graph audit. Evidence manifest: `docs/artifacts/2026-08-28/g3-host-portability-build-manifest.json`.

The unmodified Windows baseline remains isolated at WiiCompiled commit `1912292c804ff9b1b79938de89369ec4496f9fff`, tree `34f9deda094915e12f47316059911b28c6812964`. Its checkout is clean and push-disabled. KartPad's new Windows host-service sources keep the same public contracts, but an actual Windows compile remains a later comparison row and is not claimed here.

## Host contract ownership

| Dependency order | Baseline use | KartPad contract / Apple plan | State / owner |
|---|---|---|---|
| Build flags | Windows/LLVM-MinGW/x86-64 gate; unconditional Win32 libraries | Explicit `MKW_HOST_*`, architecture, renderer, product, Apple-target, and memory switches; generated manifest | G3 Pass — build system |
| Paths/logging/files | Win32 module/path/console/file attributes | `HostPaths`, durable `AtomicWriteFile`; diagnostic sink follows the same platform split | Paths/files Pass; logging integration G6 — platform |
| Clocks/threads | Win32 waitable timers, thread metadata | monotonic nanoseconds, deadline sleep, bounded thread naming | G3 Pass — platform |
| Guest memory | `VirtualAlloc2`, placeholder views, shared mappings, `VirtualProtect`, VEH | checked oracle plus Darwin Mach VM backend | G4 active — memory |
| Scheduler | Windows fibers | portable scheduler/context backend with ABI preservation stress | G5 — scheduler |
| Renderer/window | Aurora/Dawn Win32 surfaces, D3D/Vulkan defaults | Dawn Metal surface and Retina lifecycle | G6 — graphics |
| Audio/media | host audio path and Windows media ducking | CoreAudio-compatible narrow output and media/session adapter | G6 — audio |
| Input/raw adapter | SDL plus SetupAPI/WinUSB WUP-028 | SDL/GameController; separate macOS USB adapter backend or explicit limitation | G6/G10 — input |
| Networking/TLS | WinSock, Windows trust/interface APIs | BSD sockets, Network/Security framework adapters, local-server tests | G6/G12 — network |
| Packaging/crash UI | Win32 executable/DLL copying, DbgHelp, Windows dialogs | native app bundle, Apple crash/symbol paths, safe diagnostics | G13 — application |

## Source-complete upstream Windows inventory

Run `./scripts/list-upstream-windows-sources.sh` to reproduce the inventory. Third-party Crypto++ and pugixml matches are not forked here; their upstream platform branches stay dependency-owned and must compile through their public targets.

| Owner / plan | Exact first-party files containing Windows/build-ISA dependencies |
|---|---|
| Build system; capability split | `runtime/CMakeLists.txt`; `runtime/cmake/PublicProducts.cmake`; `aurora-main/CMakeLists.txt`; `aurora-main/extern/CMakeLists.txt`; `aurora-main/cmake/AuroraCopyRuntimeDLLs.cmake`; `AuroraDawnProvider.cmake`; `AuroraNodProvider.cmake`; `AuroraSDL3Provider.cmake`; `aurora_core.cmake` |
| G3/G6 platform/diagnostics | `runtime/src/main.cpp`; `runtime/src/system_bridge.cpp`; `runtime/src/host_cpu_baseline.cpp`; `runtime/src/memory.cpp`; `runtime/src/settings_overlay.cpp`; `runtime/include/runtime_config.h`; `runtime/include/aurora_events.h`; `runtime/src/hle/vi.cpp` |
| G4 memory | `runtime/src/guest_flat_memory.cpp`; `aurora-main/lib/dolphin/os/OSMemory.cpp` |
| G5 scheduler | `runtime/include/fiber_manager.h`; `runtime/src/fiber_manager.cpp`; `aurora-main/lib/dolphin/os/OSTime.cpp` |
| G6/G10 input/media | `runtime/src/wup028_adapter.cpp`; `runtime/src/music_attenuation.cpp` |
| G6/G12 networking | `runtime/include/hle/network_poll_contract.h`; `runtime/include/hle/network_deferred_contract.h`; `runtime/src/hle/net/network_internal.h`; `network_core.cpp`; `network_ssl.cpp` |
| G6/G9 storage | `runtime/src/hle/storage/nand_api.cpp`; `nand_async.cpp`; `nand_fs.cpp`; `nand_internal.h`; `nand_isfs.cpp`; `riivolution.cpp` |
| G6 Aurora/Metal/window | `aurora-main/lib/aurora.cpp`; `internal.hpp`; `logging.cpp`; `system_info.cpp`; `window.cpp`; `card/DolphinCardPath.cpp`; `dawn/BackendBinding.cpp`; `webgpu/gpu.cpp` |

No file in this inventory is treated as fixed merely because a non-Windows branch exists. Each moves to Pass only when its owning goal's contract and immediate Apple test pass.
