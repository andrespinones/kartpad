import pathlib
import unittest


REPO = pathlib.Path(__file__).resolve().parents[1]


class ExperimentalJoyCon2ContractTests(unittest.TestCase):
    def test_macos_menu_exposes_joycon2_controls(self) -> None:
        shell = (REPO / "apple/macos/KartPadMacShell.mm").read_text()
        self.assertIn('#import "KartPadJoyCon2.h"', shell)
        self.assertIn('initWithTitle:@"Experimental Joy-Con 2 (Switch 2)"', shell)
        self.assertIn('initWithTitle:@"Connect Joy-Con 2…"', shell)
        self.assertIn("KartPadApplyExperimentalJoyCon2Preference();", shell)
        # The bridge attaches SDL virtual gamepads, so it must start after the
        # menu install block runs on the main run loop, not during game-data
        # preparation before Aurora initializes SDL.
        install = shell.index("void KartPadMacShellInstall(void)")
        self.assertGreater(shell.index("KartPadApplyExperimentalJoyCon2Preference();", install), install)

    def test_bridge_is_opt_in_and_uses_sdl_virtual_gamepads(self) -> None:
        bridge = (REPO / "apple/macos/KartPadJoyCon2.mm").read_text()
        self.assertIn('@"KartPadExperimentalJoyCon2Enabled"', bridge)
        self.assertIn("SDL_AttachVirtualJoystick(&desc)", bridge)
        self.assertIn("SDL_DetachVirtualJoystick(", bridge)
        self.assertIn("SDL_JOYSTICK_TYPE_GAMEPAD", bridge)
        # One virtual gamepad per Joy-Con 2: no left/right merging.
        self.assertNotIn("combine", bridge.lower())
        # Known Switch 2 identities from public reverse engineering.
        self.assertIn("0x2066", bridge)
        self.assertIn("0x2067", bridge)
        self.assertIn("AB7DE9BE-89FE-49AD-828F-118F09DF7FD2", bridge)

    def test_packaging_links_corebluetooth_and_declares_usage(self) -> None:
        package = (REPO / "scripts/package-macos-runtime.sh").read_text()
        entitlements = (REPO / "apple/macos/KartPad.entitlements").read_text()
        self.assertIn("NSBluetoothAlwaysUsageDescription", package)
        self.assertIn("Joy-Con 2", package)
        self.assertIn("com.apple.security.device.bluetooth", entitlements)
        for patch in (
            "wiicompiled-macos-shell.patch",
            "wiicompiled-retro-apple-product.patch",
            "wiicompiled-dual-product-target.patch",
        ):
            text = (REPO / "patches" / patch).read_text()
            self.assertIn('"-framework CoreBluetooth"', text, patch)
        shell_patch = (REPO / "patches/wiicompiled-macos-shell.patch").read_text()
        self.assertIn("KartPadJoyCon2.mm", shell_patch)

    def test_runtime_preparation_applies_sideways_preset(self) -> None:
        preset = REPO / "patches/wiicompiled-experimental-joycon2-preset.patch"
        self.assertTrue(preset.exists())
        text = preset.read_text()
        self.assertIn("kJoyCon2SidewaysPreset", text)
        self.assertIn('"Joy-Con 2 Sideways (Experimental)"', text)
        prepare = (REPO / "scripts/prepare-g7-game-runtime.sh").read_text()
        self.assertIn(preset.name, prepare)
        self.assertLess(prepare.index("wiicompiled-experimental-wiimote-preset.patch"),
                        prepare.index(preset.name))


if __name__ == "__main__":
    unittest.main()
