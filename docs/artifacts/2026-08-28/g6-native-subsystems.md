# G6 native Apple subsystem smoke

Date: 2026-08-28

Command: `./scripts/test-native-subsystems.sh`

Target: arm64 macOS, deployment target 14.0, AppleClang 21.0.0, RelWithDebInfo.

Environment: `MTL_DEBUG_LAYER=1` (Metal API Validation enabled).

## Result

```text
Metal API Validation Enabled
metalDevice=Apple M2 clearReadback=pass
coreAudioSampleRate=48000 channels=8 init=pass
gameControllers=0 discovery=pass
storageAtomicWrite=pass
dns=pass loopbackTcp=pass
KartPad native Apple subsystem smoke passed
```

The Metal fixture created the system device/queue, cleared a shared RGBA8 render target, waited for command completion, and verified all 64 pixels. The audio fixture created Apple's default output component, queried a valid stream format, and disposed it cleanly without playing user-audible audio. GameController initialized its discovery path and correctly represented the current zero-controller state. Storage used KartPad's durable atomic replacement. Networking resolved `localhost`, bound/listened/connected/accepted on IPv4 loopback, and verified a payload byte-for-byte.

This proves native host adapter initialization and synthetic behavior. It does not claim a Dawn/Aurora app surface, audible audio quality, a physical controller, external networking, or translated rendering; those remain later gates.
