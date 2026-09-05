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

    def test_original_joycon_separation_is_opt_in_and_applied_before_sdl(self) -> None:
        shell = (REPO / "apple/macos/KartPadMacShell.mm").read_text()
        bridge = (REPO / "apple/macos/KartPadJoyCon2.mm").read_text()
        self.assertIn('initWithTitle:@"Original Joy-Con Pair as Two Players"', shell)
        self.assertIn("KartPadApplySeparateOriginalJoyConsPreference();", shell)
        # The HIDAPI hint must be applied during game-data preparation, before
        # Aurora initializes SDL's joystick subsystem, and again on toggle.
        prepare = shell.index("bool KartPadMacShellPrepareGameData(void)")
        self.assertGreater(shell.index("KartPadApplySeparateOriginalJoyConsPreference();", prepare), prepare)
        self.assertIn('SDL_SetHint(SDL_HINT_JOYSTICK_HIDAPI_COMBINE_JOY_CONS, separate ? "0" : "1")', bridge)

    def test_bridge_is_opt_in_and_uses_sdl_virtual_gamepads(self) -> None:
        bridge = (REPO / "apple/macos/KartPadJoyCon2.mm").read_text()
        self.assertIn('@"KartPadExperimentalJoyCon2Enabled"', bridge)
        self.assertIn("SDL_AttachVirtualJoystick(&desc)", bridge)
        self.assertIn("SDL_DetachVirtualJoystick(", bridge)
        self.assertIn("SDL_JOYSTICK_TYPE_GAMEPAD", bridge)
        # One virtual gamepad per Joy-Con 2: each device attaches itself and
        # there is no left/right merging step.
        self.assertIn("- (BOOL)attachToSDL", bridge)
        self.assertNotIn("hasBothSides", bridge)
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

    def test_rumble_is_exposed_through_the_sdl_virtual_gamepad(self) -> None:
        bridge = (REPO / "apple/macos/KartPadJoyCon2.mm").read_text()
        self.assertIn("desc.Rumble = KartPadJoyCon2Rumble", bridge)
        self.assertIn("289326CB-A471-485D-A8F4-240C14F18241", bridge)  # Joy-Con 2 (L) vibration
        self.assertIn("FA19B0FB-CD1F-46A7-84A1-BBB09E00C149", bridge)  # Joy-Con 2 (R) vibration
        self.assertIn("CC483F51-9258-427D-A939-630C31F72B05", bridge)  # Pro Controller 2 vibration
        # An active rumble is refreshed on a timer and ends with an explicit stop.
        self.assertIn("kRumbleRefreshInterval", bridge)
        self.assertIn("one explicit stop sample", bridge)

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
