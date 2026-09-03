import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / "apple/ios/KartPadRuntimeOverlayHost.mm"


class IOSTouchLayoutContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = RUNTIME.read_text()

    def test_captured_layout_is_seeded_only_for_untouched_iphones(self) -> None:
        seed = self.source.split(
            "void KartPadSeedPhoneTouchLayoutDefaults(BOOL force) {", 1
        )[1].split("NSSet<NSString *> *KartPadHiddenTouchControls()", 1)[0]
        self.assertIn("UIUserInterfaceIdiomPhone", seed)
        self.assertIn('dictionaryForKey:@"SunPadControlOrigins"] == nil', seed)
        self.assertIn("0.93580568318565682", seed)
        self.assertIn("0.8208055524263117", seed)
        self.assertIn("0.12563888892222205", seed)
        self.assertIn("0.055472222222222207", seed)
        self.assertIn("0.84591666666666665", seed)
        self.assertIn("0.084500001609325415", seed)
        self.assertIn("0.7827200293540955", seed)
        self.assertIn("0.6000000238418579", seed)

    def test_existing_custom_layouts_and_ipad_defaults_are_preserved(self) -> None:
        self.assertIn("KartPadSeedPhoneTouchLayoutDefaults(NO);", self.source)
        self.assertIn(
            "UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPhone",
            self.source,
        )
        self.assertIn(
            'if (force || [defaults dictionaryForKey:@"SunPadControlOrigins"] == nil)',
            self.source,
        )

    def test_editor_can_hide_and_restore_individual_controls(self) -> None:
        self.assertIn('@"KartPadHiddenTouchControls"', self.source)
        self.assertIn('@"ExperimentalDPad"', self.source)
        self.assertIn('@"Hide selected touch control"', self.source)
        self.assertIn('@"Show selected touch control"', self.source)
        self.assertIn("control.hidden = !editing;", self.source)
        self.assertIn("control.userInteractionEnabled = editing;", self.source)
        self.assertIn("BOOL showing = [hidden containsObject:identifier];", self.source)
        self.assertIn("control.alpha = 1.0;", self.source)

    def test_back_returns_to_touch_settings_and_reset_restores_phone_defaults(self) -> None:
        finish = self.source.split("- (void)kartPadFinishLayoutEditing {", 1)[1].split(
            "- (void)endLayoutEditing {", 1
        )[0]
        self.assertIn("[super finishLayoutEditing];", finish)
        self.assertIn("[self toggleSettingsPanel];", finish)
        self.assertIn('[done setTitle:@"Back"', self.source)
        reset = self.source.split("- (void)resetLayout {", 1)[1].split(
            "- (void)toggleSettingsPanel {", 1
        )[0]
        self.assertIn("[super resetLayout];", reset)
        self.assertIn("removeObjectForKey:kKartPadHiddenTouchControlsKey", reset)
        self.assertIn("KartPadSeedPhoneTouchLayoutDefaults(YES);", reset)


if __name__ == "__main__":
    unittest.main()
