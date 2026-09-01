# Install the KartPad unsigned IPA

KartPad `v0.2.0-preview.2` is an unsigned ARM64 IPA for iPhone and iPad. It is a
free community preview, not an App Store or TestFlight build, and it will not
install until it is re-signed with your own Apple identity or compatible
personal sideloading tool.

1. Download `KartPad-v0.2.0-preview.2-unsigned.ipa` and `SHA256SUMS` from the
   [Preview 2 release](https://github.com/chrissotraidis/kartpad/releases/tag/v0.2.0-preview.2).
2. Verify the IPA with `shasum -a 256 -c SHA256SUMS` on a Mac.
3. Re-sign and install it with AltStore Classic plus AltServer or another
   compatible IPA-signing workflow. AltStore PAL cannot import arbitrary
   unsigned IPA files.
4. On first launch, choose your own legally obtained supported PAL `RMCP01`
   revision 0 WBFS/ISO through the native importer.

The IPA includes KartPad's ARM64 app and ahead-of-time translated executable
module. It does not include a Mario Kart Wii disc image, extracted courses,
textures, audio, saves, signing certificate, or provisioning profile. The app
still requires the supported user-supplied image because those non-executable
game files are imported privately on the device.

Updating in place with the same bundle identifier and signing identity is the
safest way to retain game data and saves. A clean uninstall can remove the app
container, so back up anything important before uninstalling or changing
signing identities.

The Personal IPA Builder remains available for developers and future verified
container or executable profiles. A locally generated personalized IPA is a
separate, unaudited artifact and is not the public release candidate.
