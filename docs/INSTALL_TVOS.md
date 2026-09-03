# Install the KartPad Apple TV preview

KartPad `v0.4.0-preview.2` includes an unsigned ARM64 tvOS IPA for hardware
bring-up. It has passed compilation and package audits but has not run on the
maintainer's Apple TV hardware. Treat it as an experimental tester build, not
supported Apple TV functionality.

1. Download `KartPad-v0.4.0-preview.2-tvos-unsigned.ipa` and `SHA256SUMS` from
   the release and verify the checksum.
2. Re-sign the IPA with your own Apple development identity and bundle
   identifier, then install it on a paired Apple TV through Xcode or a
   compatible tvOS signing workflow.
3. Set `KARTPAD_TVOS_BUNDLE_IDENTIFIER` to the signed identifier before using
   any repository device script.
4. Stage your own extracted PAL `RMCP01`, revision-0 `DATA` directory with
   `scripts/stage-tvos-game-data.sh`.
5. Follow `docs/TVOS-TESTING.md` in order and stop at the first failure.

An Extended Gamepad is required for racing. The Siri Remote is supported only
for the native setup screens. The app does not include a disc image, extracted
Nintendo assets, Retro Rewind pack, saves, signing identity, provisioning
profile, or Wii banner artwork. KartPad downloads and hash-verifies the pinned
official Retro Rewind pack only after the tester selects that mode.

Update in place with the same signing identity and bundle identifier. Back up
Application Support before deleting the app or changing signing identities.
Never attach game data, Retro Rewind files, saves, signing material, device
identifiers, or a complete app container to a public report.
