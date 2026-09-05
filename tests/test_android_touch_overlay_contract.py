from __future__ import annotations

import unittest
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]


class AndroidTouchOverlayContractTests(unittest.TestCase):
    def test_overlay_exposes_complete_classic_control_set(self) -> None:
        source = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadOverlayView.kt").read_text()
        for control in (
            '"move"', '"c"', '"A"', '"B"', '"X"', '"Y"', '"Z"',
            '"Start"', '"L"', '"R"', '"DpadUp"', '"DpadDown"',
            '"DpadLeft"', '"DpadRight"',
        ):
            self.assertIn(control, source)
        self.assertIn("pointerOwners", source)
        self.assertIn("nativePublishTouchState", source)

    def test_lifecycle_clears_touch_state(self) -> None:
        activity = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadActivity.kt").read_text()
        self.assertIn("override fun onPause()", activity)
        self.assertIn("override fun onWindowFocusChanged(hasFocus: Boolean)", activity)
        self.assertGreaterEqual(activity.count("kartPadOverlay.clearTouchInput()"), 2)

    def test_one_second_gas_lock_has_visual_haptic_and_accessibility_state(self) -> None:
        source = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadOverlayView.kt").read_text()
        self.assertIn("GAS_LOCK_DELAY_MS = 1_000L", source)
        self.assertIn("gasLocked = true", source)
        self.assertIn("LOCKED_GAS_COLOR", source)
        self.assertIn("HapticFeedbackConstants.VIRTUAL_KEY", source)
        self.assertIn("isHapticFeedbackEnabled = true", source)
        self.assertIn('"Acceleration locked"', source)
        self.assertIn("if (gasLocked) BUTTON_A else 0", source)
        self.assertIn("gasLocked = false", source)

    def test_canvas_controls_are_accessible_and_operable_as_virtual_nodes(self) -> None:
        source = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadOverlayView.kt").read_text()
        self.assertIn("TouchAccessibilityNodeProvider", source)
        self.assertIn("override fun getAccessibilityNodeProvider()", source)
        self.assertIn("visibleAccessibilityControls()", source)
        self.assertIn("info.addChild(this, id)", source)
        self.assertIn('"Move stick"', source)
        self.assertIn('"Camera stick"', source)
        self.assertIn('"D-pad up"', source)
        self.assertIn("pulseAccessibilityButton(control)", source)
        self.assertIn("pulseAccessibilityStick(control, action)", source)
        self.assertIn('"Lock acceleration"', source)
        self.assertIn('"Unlock acceleration"', source)
        self.assertIn("ACTION_TOGGLE_GAS_LOCK", source)
        self.assertIn("TYPE_VIEW_ACCESSIBILITY_FOCUSED", source)

    def test_r_is_the_same_compact_digital_pill_as_l(self) -> None:
        source = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadOverlayView.kt").read_text()
        self.assertIn('button("L", "L", BUTTON_L, 94f, 46f', source)
        self.assertIn('button("R", "R", BUTTON_R, 94f, 46f', source)
        self.assertIn("const val BUTTON_R = 0x00000200", source)

    def test_controller_handoff_clears_hides_and_restores_touch(self) -> None:
        activity = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadActivity.kt").read_text()
        overlay = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadOverlayView.kt").read_text()
        self.assertIn("InputManager.InputDeviceListener", activity)
        self.assertIn("InputDevice.SOURCE_GAMEPAD", activity)
        self.assertIn("InputDevice.SOURCE_JOYSTICK", activity)
        self.assertIn("registerInputDeviceListener", activity)
        self.assertIn("unregisterInputDeviceListener", activity)
        self.assertIn("kartPadOverlay.setHiddenForController(", activity)
        self.assertIn("controllerCount > 0 && KartPadTouchSettings.hideOnController(this)", activity)
        self.assertIn("fun setHiddenForController(hidden: Boolean)", overlay)
        self.assertIn("clearTouchInput()", overlay)
        self.assertIn("visibility = INVISIBLE", overlay)
        self.assertIn("visibility = VISIBLE", overlay)

    def test_touch_presentation_settings_match_ios_ranges_and_defaults(self) -> None:
        settings = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadTouchSettings.kt").read_text()
        overlay = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadOverlayView.kt").read_text()
        activity = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadActivity.kt").read_text()
        self.assertIn("DEFAULT_OPACITY = 0.82f", settings)
        self.assertIn("MIN_OPACITY = 0.25f", settings)
        self.assertIn("MAX_OPACITY = 1.0f", settings)
        self.assertIn("MIN_SIZE = 0.70f", settings)
        self.assertIn("MAX_SIZE = 1.35f", settings)
        self.assertIn("MIN_CONTROL_SIZE = 0.60f", settings)
        self.assertIn("MAX_CONTROL_SIZE = 1.75f", settings)
        self.assertIn("getBoolean(HIDE_ON_CONTROLLER, true)", settings)
        self.assertIn("modernCStickHorizontal", settings)
        self.assertIn("HIDDEN_CONTROLS", settings)
        self.assertIn("ORIGIN_X_PREFIX", settings)
        self.assertIn("controlSizeScale = KartPadTouchSettings.size(context)", overlay)
        self.assertIn("else -> controlOpacity", overlay)
        self.assertIn("alpha * 255f", overlay)
        self.assertIn('if (control.id.startsWith("Dpad")) "Dpad"', overlay)
        self.assertIn("fun setSelectedControlSize", overlay)
        self.assertIn("fun toggleSelectedControlVisibility", overlay)
        self.assertIn("if (modernCStickHorizontal) -rightX else rightX", overlay)
        self.assertIn('add(0, MENU_TOUCH_CONTROLS, 2, "Touch Control Settings…")', activity)
        self.assertIn('.setTitle("Touch Control Settings")', activity)
        self.assertIn('text = "Reset This Device Layout"', activity)
        self.assertIn('text = "Move controls"', activity)
        self.assertIn('text = "Modern C-stick L/R"', activity)
        self.assertIn('val renderScales = floatArrayOf(1f, 2f, 3f, 4f)', activity)
        self.assertIn('contentDescription = "Render resolution"', activity)
        self.assertIn("KartPadTouchSettings.setResolutionScale(this, scale)", activity)
        self.assertIn("val leftColumn = LinearLayout(this).apply", activity)
        self.assertIn("val rightColumn = LinearLayout(this).apply", activity)
        self.assertIn('text = "Back"', activity)
        self.assertIn("finishLayoutEditing(returnToSettings = true)", activity)
        self.assertIn("KartPadTouchSettings.hideOnController(this)", activity)
        reset_body = settings[settings.index("fun resetTouchControls"):]
        self.assertNotIn("key == HIDE_ON_CONTROLLER", reset_body)
        self.assertNotIn("key == MODERN_C_STICK", reset_body)

    def test_android_menu_preserves_kartpad_hierarchy_and_live_display_actions(self) -> None:
        activity = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadActivity.kt").read_text()
        native = (REPO / "android/app/src/main/cpp/kartpad_runtime_settings_jni.cpp").read_text()
        for title in (
            '"KartPad"', '"Switch Game Version…"', '"Multiplayer…"',
            '"Show FPS Counter"', '"Controls"', '"Display"',
            '"Game Data & Saves"', '"Controller Player Setup…"',
            '"Controller Button Mapping…"',
            '"Touch Control Settings…"', '"Motion Steering…"',
            '"Experimental Wii Remote + Nunchuk…"', '"Aspect Ratio…"',
            '"Render Resolution…"', '"Manage Retro Rewind…"', '"Manage Miis…"',
            '"Import or Reimport Wii Disc Image…"',
            '"Import from Extracted Folder…"', '"Remove Stored Game Data…"',
            '"Manage Saves…"',
            '"Report a Problem…"',
        ):
            self.assertIn(title, activity)
        self.assertNotIn("SunPad", activity)
        self.assertIn("nativeApplyDisplaySettings", activity)
        self.assertIn("restartToGameSelector", activity)
        self.assertIn("startActivity(chooser)", activity)
        self.assertIn("kotlin.system.exitProcess(0)", activity)
        manifest = (REPO / "android/app/src/main/AndroidManifest.xml").read_text()
        self.assertIn('android:process=":launcher"', manifest)
        self.assertIn('hint = "What went wrong?"', activity)
        self.assertIn('hint = "Area and what you were doing (optional)"', activity)
        self.assertIn('hint = "Every time, sometimes, once, or not sure?"', activity)
        self.assertIn('appendQueryParameter("report-id", id)', activity)
        self.assertIn('appendQueryParameter("summary", problem.text.toString().trim())', activity)
        runtime_patch = (REPO / "patches/wiicompiled-android-runtime-settings.patch").read_text()
        self.assertIn("PublishDisplaySettings", native)
        self.assertNotIn("AuroraGetSurfaceSize", native)
        self.assertIn("ConsumeDisplaySettings", runtime_patch)
        self.assertIn("ConfigureMkwMobileAspectMode", runtime_patch)
        self.assertIn("VISetFrameBufferScale", runtime_patch)

    def test_android_exposes_persistent_one_to_four_player_controller_setup(self) -> None:
        activity = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadActivity.kt").read_text()
        native = (REPO / "android/app/src/main/cpp/kartpad_controller_slots_jni.cpp").read_text()
        fixture = (REPO / "android/app/src/main/cpp/kartpad_controller_slots_fixture_jni.cpp").read_text()
        patch = (REPO / "patches/aurora-android-gamepad-assignment.patch").read_text()
        prepare = (REPO / "scripts/prepare-android-game-runtime.sh").read_text()
        self.assertIn("for (player in 0 until 4)", activity)
        self.assertIn('"Player ${player + 1}', activity)
        self.assertIn("nativeControllerDevices()", activity)
        self.assertIn("nativeAssignControllerPlayer", activity)
        self.assertIn("nativeClearControllerPlayer", activity)
        self.assertIn("list_standard_gamepads", native)
        self.assertIn("assign_standard_gamepad", native)
        self.assertIn("clear_standard_gamepad_player", native)
        self.assertIn('"KartPad Virtual One"', fixture)
        self.assertIn("g_players[index] = -1", fixture)
        self.assertIn("DEBUG_EXTRA_CONTROLLER_SETUP", activity)
        self.assertIn(
            "g_portPreferences[player].identity = controller_identity(selected)", patch,
        )
        self.assertIn("assign_player_index(controller, -1)", patch)
        self.assertIn("aurora-android-gamepad-assignment.patch", prepare)

    def test_z_has_clear_vertical_spacing_from_x(self) -> None:
        source = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadOverlayView.kt").read_text()
        self.assertIn('0.969f, 0.410f, Color.argb(240, 97, 46, 148)', source)

    def test_touch_overlay_preserves_ipad_default_geometry_on_tablets(self) -> None:
        source = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadOverlayView.kt").read_text()
        activity = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadActivity.kt").read_text()
        self.assertIn("smallestScreenWidthDp >= 600", source)
        self.assertIn('"move" -> PointF(172f, 172f)', source)
        self.assertIn('"R" -> PointF(280f, 62f)', source)
        self.assertIn('"Start" -> PointF(116f, 62f)', source)
        self.assertIn('"move" -> PointF(0.13103953f, 0.79058945f)', source)
        self.assertIn('"Z" -> PointF(0.8275988f, 0.721303f)', source)
        self.assertIn('else -> PointF(0.26866764f, 0.79472595f)', source)
        self.assertIn("DEBUG_EXTRA_TOUCH_OVERLAY", activity)
        self.assertIn("BuildConfig.GAME_RUNTIME || debugTouchOverlay", activity)

    def test_motion_steering_matches_ios_curve_and_merges_with_touch(self) -> None:
        motion = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadMotionSteering.kt").read_text()
        activity = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadActivity.kt").read_text()
        overlay = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadOverlayView.kt").read_text()
        settings = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadTouchSettings.kt").read_text()
        self.assertIn("Sensor.TYPE_GRAVITY", motion)
        self.assertIn("Sensor.TYPE_ACCELEROMETER", motion)
        self.assertIn("private const val DEAD_ZONE = 0.045", motion)
        self.assertIn("val fullLock = 0.70 / boundedSensitivity", motion)
        self.assertIn("sensitivity.coerceIn(0.5f, 2f)", motion)
        self.assertIn("fun recenter()", motion)
        self.assertIn("showMotionSteering()", activity)
        self.assertIn('"Turn On & Recenter"', activity)
        self.assertIn('"Cycle Sensitivity"', activity)
        self.assertIn("motion_steering_enabled", settings)
        self.assertIn("fun setMotionSteering(value: Float)", overlay)
        self.assertIn("abs(leftX) >= abs(motionSteeringX)", overlay)
        self.assertIn("setControllerConnected(controllerCount > 0)", activity)

    def test_controller_mapping_is_persisted_swapped_and_applied_natively(self) -> None:
        activity = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadActivity.kt").read_text()
        store = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadControllerMapping.kt").read_text()
        native = (REPO / "runtime/include/kartpad/android/controller_mapping.hpp").read_text()
        patch = (REPO / "patches/wiicompiled-android-controller-mapping.patch").read_text()
        self.assertIn('arrayOf("A", "B", "X", "Y", "Z")', store)
        self.assertIn('"Left Shoulder"', store)
        self.assertIn("mapping.indexOf(physical)", store)
        self.assertIn("mapping[other] = previous", store)
        self.assertIn("showControllerMappingChoices(game)", activity)
        self.assertIn('text = "Reset to Default"', activity)
        self.assertIn("nativeApplyControllerMapping", activity)
        self.assertIn("IsValidControllerButtonMapping", native)
        self.assertIn("ApplyControllerButtonMapping", patch)
        gamepad = (REPO / "runtime/include/kartpad/android/gamepad_contract.h").read_text()
        fixture = (REPO / "android/app/src/main/cpp/fixture_main.cpp").read_text()
        self.assertIn("map(kGamepadLeftShoulder, kClassicZr)", gamepad)
        self.assertIn("output.buttons |= kClassicL", gamepad)
        expected = fixture.split("constexpr uint32_t kExpectedButtons =", 1)[1].split(";", 1)[0]
        self.assertIn("kClassicZr", expected)
        self.assertNotIn("kClassicZl", expected)

    def test_mii_manager_stages_validated_changes_for_restart(self) -> None:
        activity = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadActivity.kt").read_text()
        storage = (REPO / "android/app/src/main/java/dev/kartpad/android/KartPadMiiStorage.kt").read_text()
        native = (REPO / "android/app/src/main/cpp/kartpad_mii_jni.cpp").read_text()
        cmake = (REPO / "android/app/src/main/cpp/CMakeLists.txt").read_text()
        self.assertIn("KartPadMiiStorage.applyPending(filesDir)", activity)
        self.assertLess(
            activity.index("KartPadMiiStorage.applyPending(filesDir)"),
            activity.index("super.onCreate(savedInstanceState)"),
        )
        self.assertIn("showMiiManager()", activity)
        self.assertIn("Intent.ACTION_OPEN_DOCUMENT", activity)
        self.assertIn("nativeImportMii", activity)
        self.assertIn("nativeRemoveMii", activity)
        self.assertIn("AtomicFile", storage)
        self.assertIn("MiiBackups", storage)
        self.assertIn("stored == crc", storage)
        self.assertIn("kartpad::mii::ImportMii", native)
        self.assertIn("kartpad::mii::RemoveMii", native)
        self.assertIn("kartpad_mii_jni.cpp", cmake)

    def test_runtime_preparation_applies_touch_bridge(self) -> None:
        script = (REPO / "scripts/prepare-android-game-runtime.sh").read_text()
        self.assertIn("wiicompiled-android-touch-input.patch", script)

    def test_touch_c_stick_reaches_both_guest_status_formats(self) -> None:
        patch = (REPO / "patches/wiicompiled-android-touch-input.patch").read_text()
        self.assertIn("statusPtr + 0x74, touchInput.right_stick_x", patch)
        self.assertIn("statusPtr + 0x78, touchInput.right_stick_y", patch)
        self.assertIn("statusPtr + 0x30, static_cast<uint16_t>(rightStickX)", patch)
        self.assertIn("statusPtr + 0x32, static_cast<uint16_t>(rightStickY)", patch)
        patch = (REPO / "patches/wiicompiled-android-touch-input.patch").read_text()
        self.assertIn('"kartpad/android/touch_input.h"', patch)
        self.assertIn("ConsumeTouchInput()", patch)
        self.assertIn("CoreButtonsForClassic(touchInput.buttons)", patch)

    def test_game_build_selects_dual_preparation_for_a_dual_graph(self) -> None:
        script = (REPO / "scripts/build-android-game-app.sh").read_text()
        self.assertIn('runtime_product="base"', script)
        self.assertIn('runtime_product="dual"', script)
        self.assertIn('"$runtime_build" "$runtime_product"', script)
        self.assertIn('native_target="KartPadDual"', script)


if __name__ == "__main__":
    unittest.main()
