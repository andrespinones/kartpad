# G7 Aurora/Dawn Metal host frame

Status: **host-frame acceptance evidence**. This does not yet claim translated GX geometry or a game frame, so G7 remains in progress.

- Target: native arm64 macOS on Apple M2, macOS 26.5.
- Renderer path: pinned Aurora `aurora::gx` -> Dawn `v20260603.191052` -> Metal -> SDL3 Cocoa surface.
- Dawn Darwin arm64 archive SHA-256: `084ffd2ef500d614e443e3d494738272134628867bad3270d67ee8b0fb5f0838`.
- Requested GX clear: RGBA `#123456ff`.
- GPU readback: Aurora frame capture at frame 2, 1164x960 Retina surface.
- BMP SHA-256: `8881f050f2df9a16ce38565f8a33830fdf649a5d00268322699a7cd06e218596`.
- Corner pixels: exact BGRA `56 34 12 ff` at the first and final captured pixels.
- Reproduction: `./scripts/test-g7-aurora-host-frame.sh`.

The test selects `BACKEND_METAL`, rejects any other backend, uses Aurora's own asynchronous frame/presentation workers, captures the renderer's present-source texture through Dawn, and fails if the capture is empty, dimensionless, or has the wrong corner color.

![Aurora/Dawn Metal #123456 host-frame capture](g7-aurora-host-frame.png)
