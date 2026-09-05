package dev.kartpad.android

import android.app.AlertDialog
import android.os.Bundle
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.hardware.input.InputManager
import android.net.Uri
import android.system.Os
import android.util.Log
import android.view.Gravity
import android.view.InputDevice
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.PopupMenu
import android.widget.RelativeLayout
import android.widget.ScrollView
import android.widget.SeekBar
import android.widget.Switch
import android.widget.TextView
import java.io.ByteArrayInputStream
import java.io.File
import java.io.FileOutputStream
import java.nio.file.Files
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import kotlin.math.roundToInt
import org.libsdl.app.SDLActivity
import org.libsdl.app.SDLSurface

class KartPadActivity : SDLActivity() {
    private lateinit var kartPadOverlay: KartPadOverlayView
    private lateinit var menuButton: Button
    private lateinit var editorBar: LinearLayout
    private lateinit var editorLabel: TextView
    private lateinit var editorSize: SeekBar
    private lateinit var editorVisibility: Button
    private var updatingEditorControls = false
    private var runtimeProfile = "base"
    private lateinit var inputManager: InputManager
    private lateinit var motionSteering: KartPadMotionSteering
    private var inputListenerRegistered = false
    private val inputDeviceListener = object : InputManager.InputDeviceListener {
        override fun onInputDeviceAdded(deviceId: Int) = refreshControllerHandoff()
        override fun onInputDeviceRemoved(deviceId: Int) = refreshControllerHandoff()
        override fun onInputDeviceChanged(deviceId: Int) = refreshControllerHandoff()
    }

    override fun createSDLSurface(context: Context): SDLSurface = KartPadSurface(context)

    override fun onCreate(savedInstanceState: Bundle?) {
        if (BuildConfig.GAME_RUNTIME) {
            RetroRewindInstallStorage.recover(filesDir)
            KartPadMiiStorage.applyPending(filesDir)?.let { error ->
                Log.e(TAG, error)
            }
            KartPadRuntimeResources.install(this)
            Os.setenv("KARTPAD_ANDROID_FILES_DIR", filesDir.absolutePath, true)
            Os.setenv("KARTPAD_ANDROID_CACHE_DIR", cacheDir.absolutePath, true)
            configureRuntimeProfile()
            configureDebugRkgInput()
            configureDebugStateTrace()
        }
        super.onCreate(savedInstanceState)
        inputManager = getSystemService(InputManager::class.java)
        runDebugRetroRewindExtractionFixture()
        runDebugRetroRewindWorkerFixture()
        kartPadOverlay = KartPadOverlayView(this)
        motionSteering = KartPadMotionSteering(this) { value ->
            kartPadOverlay.post { kartPadOverlay.setMotionSteering(value) }
        }
        kartPadOverlay.visibility = if (BuildConfig.GAME_RUNTIME) {
            android.view.View.VISIBLE
        } else {
            android.view.View.GONE
        }
        mLayout.addView(
            kartPadOverlay,
            ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        if (BuildConfig.GAME_RUNTIME) {
            addMenuButton()
            addLayoutEditorBar()
            applyControllerMapping()
            applyDisplaySettings()
            kartPadOverlay.postDelayed({ applyDisplaySettings() }, 1_000L)
        }
        mLayout.bringChildToFront(kartPadOverlay)
        if (::menuButton.isInitialized) mLayout.bringChildToFront(menuButton)
        if (::editorBar.isInitialized) mLayout.bringChildToFront(editorBar)
        Log.i(TAG, "A0 SDLActivity shell created")
    }

    override fun onResume() {
        super.onResume()
        if (::inputManager.isInitialized && !inputListenerRegistered) {
            inputManager.registerInputDeviceListener(inputDeviceListener, null)
            inputListenerRegistered = true
        }
        refreshControllerHandoff()
        if (::motionSteering.isInitialized) motionSteering.start()
    }

    override fun onPause() {
        if (::editorBar.isInitialized && editorBar.visibility == View.VISIBLE) {
            finishLayoutEditing(returnToSettings = false)
        }
        if (::inputManager.isInitialized && inputListenerRegistered) {
            inputManager.unregisterInputDeviceListener(inputDeviceListener)
            inputListenerRegistered = false
        }
        if (::kartPadOverlay.isInitialized) {
            kartPadOverlay.clearTouchInput()
        }
        if (::motionSteering.isInitialized) motionSteering.stop()
        super.onPause()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        if (!hasFocus && ::kartPadOverlay.isInitialized) {
            kartPadOverlay.clearTouchInput()
        }
        super.onWindowFocusChanged(hasFocus)
    }

    private fun refreshControllerHandoff() {
        if (!BuildConfig.GAME_RUNTIME || !::kartPadOverlay.isInitialized ||
            !::inputManager.isInitialized
        ) return
        val controllerCount = inputManager.inputDeviceIds.count { deviceId ->
            inputManager.getInputDevice(deviceId)?.let(::isGameController) == true
        }
        if (controllerCount > 0) kartPadOverlay.clearTouchInput()
        kartPadOverlay.setControllerConnected(controllerCount > 0)
        kartPadOverlay.setHiddenForController(
            controllerCount > 0 && KartPadTouchSettings.hideOnController(this),
        )
        Log.i(TAG, "A4 controller handoff count=$controllerCount")
    }

    private fun addMenuButton() {
        menuButton = Button(this).apply {
            text = "⋯"
            textSize = 24f
            setTextColor(Color.WHITE)
            contentDescription = "Menu"
            gravity = Gravity.CENTER
            minWidth = 0
            minHeight = 0
            setPadding(0, 0, 0, dp(6))
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.argb(190, 20, 20, 20))
                setStroke(dp(1), Color.argb(100, 255, 255, 255))
            }
            setOnClickListener { showKartPadMenu() }
        }
        val params = RelativeLayout.LayoutParams(dp(44), dp(44)).apply {
            addRule(RelativeLayout.ALIGN_PARENT_END)
            addRule(RelativeLayout.ALIGN_PARENT_TOP)
            setMargins(0, dp(8), dp(12), 0)
        }
        mLayout.addView(menuButton, params)
    }

    private fun showKartPadMenu() {
        kartPadOverlay.clearTouchInput()
        PopupMenu(this, menuButton).apply {
            menu.add(0, MENU_TITLE, 0, "KartPad").isEnabled = false
            menu.add(0, MENU_SWITCH_GAME, 1, "Switch Game Version…")
            menu.add(0, MENU_MULTIPLAYER, 2, "Multiplayer…")
            menu.add(0, MENU_FPS, 3, "Show FPS Counter").apply {
                isCheckable = true
                isChecked = KartPadTouchSettings.showFps(this@KartPadActivity)
            }
            menu.addSubMenu(0, MENU_CONTROLS_GROUP, 4, "Controls").apply {
                add(0, MENU_CONTROLLER_MAPPING, 0, "Controller Button Mapping…")
                add(0, MENU_TOUCH_CONTROLS, 1, "Touch Control Settings…")
                add(0, MENU_MOTION_STEERING, 2, "Motion Steering…")
                add(0, MENU_WIIMOTE, 3, "Experimental Wii Remote + Nunchuk…")
            }
            menu.addSubMenu(0, MENU_DISPLAY_GROUP, 5, "Display").apply {
                add(0, MENU_ASPECT_RATIO, 0, "Aspect Ratio…")
                add(0, MENU_RENDER_RESOLUTION, 1, "Render Resolution…")
            }
            menu.addSubMenu(0, MENU_DATA_GROUP, 6, "Game Data & Saves").apply {
                add(0, MENU_GAME_DATA, 0, "Game Data Status…")
                add(0, MENU_RETRO_REWIND, 1, "Manage Retro Rewind…")
                add(0, MENU_MIIS, 2, "Manage Miis…")
            }
            menu.add(0, MENU_REPORT_PROBLEM, 7, "Report a Problem…")
            setOnMenuItemClickListener { item ->
                when (item.itemId) {
                    MENU_SWITCH_GAME -> confirmSwitchGameVersion()
                    MENU_MULTIPLAYER -> showMultiplayer()
                    MENU_FPS -> setShowFps(!item.isChecked)
                    MENU_CONTROLLER_MAPPING -> showControllerMapping()
                    MENU_TOUCH_CONTROLS -> showTouchControlSettings()
                    MENU_MOTION_STEERING -> showMotionSteering()
                    MENU_WIIMOTE -> showParityBoundary(
                        "Experimental Wii Remote + Nunchuk",
                        "Direct Wii Remote pairing is not available in this Android build. Android-supported Bluetooth and USB gamepads still work through the controller layer.",
                    )
                    MENU_ASPECT_RATIO -> showAspectRatioSettings()
                    MENU_RENDER_RESOLUTION -> showResolutionSettings()
                    MENU_GAME_DATA -> showGameDataStatus()
                    MENU_RETRO_REWIND -> startActivity(
                        Intent(this@KartPadActivity, RetroRewindInstallActivity::class.java),
                    )
                    MENU_MIIS -> showMiiManager()
                    MENU_REPORT_PROBLEM -> showReportProblem()
                    else -> return@setOnMenuItemClickListener false
                }
                true
            }
            show()
        }
    }

    private fun setShowFps(show: Boolean) {
        KartPadTouchSettings.setShowFps(this, show)
        applyDisplaySettings()
    }

    private fun confirmSwitchGameVersion() {
        AlertDialog.Builder(this)
            .setTitle("Switch Game Version")
            .setMessage(
                "KartPad must restart the game runtime before switching between Original Mario Kart Wii and Retro Rewind.",
            )
            .setPositiveButton("Restart to Selector") { _, _ -> restartToGameSelector() }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun restartToGameSelector() {
        kartPadOverlay.clearTouchInput()
        val chooser = Intent(this, KartPadLaunchActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        }
        startActivity(chooser)
        menuButton.postDelayed({ kotlin.system.exitProcess(0) }, SELECTOR_RESTART_DELAY_MS)
    }

    private fun applyDisplaySettings() {
        nativeApplyDisplaySettings(
            KartPadTouchSettings.showFps(this),
            KartPadTouchSettings.aspectMode(this),
            KartPadTouchSettings.resolutionScale(this),
        )
    }

    private fun showAspectRatioSettings() {
        val labels = arrayOf("4:3", "16:9", "Fill Screen")
        AlertDialog.Builder(this)
            .setTitle("Aspect Ratio")
            .setSingleChoiceItems(labels, KartPadTouchSettings.aspectMode(this)) { dialog, which ->
                KartPadTouchSettings.setAspectMode(this, which)
                applyDisplaySettings()
                dialog.dismiss()
            }
            .setNegativeButton("Back", null)
            .show()
    }

    private fun showResolutionSettings() {
        val labels = arrayOf("Native (1x)", "2x", "3x", "4x")
        val scales = floatArrayOf(1f, 2f, 3f, 4f)
        val selected = scales.indexOfFirst {
            kotlin.math.abs(it - KartPadTouchSettings.resolutionScale(this)) < 0.01f
        }.coerceAtLeast(0)
        AlertDialog.Builder(this)
            .setTitle("Render Resolution")
            .setSingleChoiceItems(labels, selected) { dialog, which ->
                KartPadTouchSettings.setResolutionScale(this, scales[which])
                applyDisplaySettings()
                dialog.dismiss()
            }
            .setNegativeButton("Back", null)
            .show()
    }

    private fun showMultiplayer() {
        val retro = runtimeProfile == "retro_rewind"
        val message = if (retro) {
            "Retro Rewind is active. Choose Nintendo WFC in the game for Retro WFC online play."
        } else {
            "Online multiplayer is available only through Retro Rewind. The original Mario Kart Wii online service is no longer available."
        }
        AlertDialog.Builder(this)
            .setTitle("Multiplayer")
            .setMessage(message)
            .apply {
                if (!retro) setPositiveButton("Set Up Retro Rewind") { _, _ ->
                    startActivity(Intent(this@KartPadActivity, RetroRewindInstallActivity::class.java))
                }
            }
            .setNegativeButton("Back", null)
            .show()
    }

    private fun showControllerMapping() {
        val controllers = inputManager.inputDeviceIds.toList().mapNotNull { id ->
            inputManager.getInputDevice(id)?.takeIf(::isGameController)?.name
        }
        val mapping = KartPadControllerMapping.load(this)
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(4), dp(24), dp(8))
        }
        content.addView(settingsLabel(if (controllers.isEmpty()) {
            "No extended controller is connected. You can review or reset the saved mapping; connect a controller to test it."
        } else {
            "Connected: ${controllers.joinToString()}. Only A, B, X, Y, and Z are remapped. Analog triggers, sticks, D-pad, Start, and the right shoulder stay direct."
        }))
        lateinit var dialog: AlertDialog
        KartPadControllerMapping.gameButtonNames.forEachIndexed { game, gameName ->
            content.addView(Button(this).apply {
                val physical = KartPadControllerMapping.physicalButtonNames[mapping[game]]
                text = "$gameName — $physical"
                contentDescription = "Game $gameName mapped to physical $physical"
                setOnClickListener {
                    dialog.dismiss()
                    showControllerMappingChoices(game)
                }
            })
        }
        content.addView(Button(this).apply {
            text = "Reset to Default"
            contentDescription = "Reset controller mapping to default"
            setOnClickListener {
                KartPadControllerMapping.reset(this@KartPadActivity)
                applyControllerMapping()
                dialog.dismiss()
                menuButton.post { showControllerMapping() }
            }
        })
        content.addView(Button(this).apply {
            text = "Done"
            contentDescription = "Close controller button mapping"
            setOnClickListener { dialog.dismiss() }
        })
        dialog = AlertDialog.Builder(this)
            .setTitle("Controller Button Mapping")
            .setView(ScrollView(this).apply { addView(content) })
            .create()
        dialog.show()
    }

    private fun showControllerMappingChoices(game: Int) {
        val gameName = KartPadControllerMapping.gameButtonNames[game]
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(4), dp(24), dp(8))
        }
        content.addView(settingsLabel(
            "Choose the physical controller button. If it is already assigned, the two assignments swap.",
        ))
        lateinit var dialog: AlertDialog
        KartPadControllerMapping.physicalButtonNames.forEachIndexed { physical, name ->
            content.addView(Button(this).apply {
                text = name
                contentDescription = "Map game $gameName to physical $name"
                setOnClickListener {
                    KartPadControllerMapping.assign(this@KartPadActivity, game, physical)
                    applyControllerMapping()
                    dialog.dismiss()
                    menuButton.post { showControllerMapping() }
                }
            })
        }
        content.addView(Button(this).apply {
            text = "Cancel"
            setOnClickListener {
                dialog.dismiss()
                menuButton.post { showControllerMapping() }
            }
        })
        dialog = AlertDialog.Builder(this)
            .setTitle(gameName)
            .setView(ScrollView(this).apply { addView(content) })
            .create()
        dialog.show()
    }

    private fun applyControllerMapping() {
        nativeApplyControllerMapping(KartPadControllerMapping.load(this))
    }

    private fun showMotionSteering() {
        val available = motionSteering.sensorAvailable
        val state = when {
            !available -> "Unavailable on this device"
            motionSteering.enabled -> "On"
            else -> "Off"
        }
        val actions = if (!available) {
            arrayOf("Continue Playing")
        } else if (motionSteering.enabled) {
            arrayOf(
                "Turn Off",
                "Recenter Now",
                if (motionSteering.inverted) "Use Standard Direction" else "Invert Direction",
                "Cycle Sensitivity",
                "Continue Playing",
            )
        } else {
            arrayOf(
                "Turn On & Recenter",
                if (motionSteering.inverted) "Use Standard Direction" else "Invert Direction",
                "Cycle Sensitivity",
                "Continue Playing",
            )
        }
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(4), dp(24), dp(8))
        }
        content.addView(settingsLabel(if (available) {
            "Tilt the device like a steering wheel. Current state: $state. " +
                "Sensitivity: ${motionSteering.sensitivity}x. Physical controllers take priority."
        } else {
            "Motion data is unavailable on this device or emulator. Touch and " +
                "physical-controller steering remain available."
        }))
        val dialog = AlertDialog.Builder(this)
            .setTitle("Motion Steering")
            .setView(ScrollView(this).apply { addView(content) })
            .create()
        actions.forEach { action ->
            content.addView(Button(this).apply {
                text = action
                contentDescription = action
                setOnClickListener {
                    dialog.dismiss()
                    when (action) {
                    "Turn Off" -> motionSteering.setEnabled(false)
                    "Recenter Now" -> motionSteering.recenter()
                    "Invert Direction" -> motionSteering.setInverted(true)
                    "Use Standard Direction" -> motionSteering.setInverted(false)
                    "Cycle Sensitivity" -> motionSteering.setSensitivity(
                        when (motionSteering.sensitivity) {
                            0.5f -> 1f
                            1f -> 2f
                            else -> 0.5f
                        },
                    )
                    "Turn On & Recenter" -> {
                        motionSteering.setEnabled(true)
                        motionSteering.recenter()
                    }
                    }
                    if (action != "Continue Playing") {
                        menuButton.post { showMotionSteering() }
                    }
                }
            })
        }
        dialog.show()
    }

    private fun showGameDataStatus() {
        val retroRoot = RetroRewindInstallStorage.installedRoot(filesDir)
            .resolve(RetroRewindRelease.ROOT)
        val retroReady = runCatching {
            RetroRewindInstallValidator.validate(
                retroRoot, RetroRewindInstallValidator.productionContract(),
            ).isValid
        }.getOrDefault(false)
        showParityBoundary(
            "Game Data & Saves",
            "Active game: ${if (runtimeProfile == "retro_rewind") "Retro Rewind" else "Original Mario Kart Wii"}\n" +
                "Retro Rewind ${RetroRewindRelease.VERSION}: ${if (retroReady) "Installed" else "Not installed"}\n\n" +
                "Android game-data import and save management are still being ported. This screen does not expose private file paths.",
        )
    }

    private fun showMiiManager() {
        kartPadOverlay.clearTouchInput()
        val database = runCatching { KartPadMiiStorage.readWorking(filesDir) }
            .getOrElse { error ->
                showParityBoundary(
                    "Manage Miis (Experimental)",
                    safeMiiError(error, "The Mii database could not be read."),
                )
                return
            }
        val records = runCatching { parseMiiRecords(nativeListMiis(database)) }
            .getOrElse { error ->
                showParityBoundary(
                    "Miis Could Not Be Read",
                    safeMiiError(error, "The Mii database failed validation."),
                )
                return
            }
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(4), dp(24), dp(8))
        }
        lateinit var dialog: AlertDialog
        val pending = if (KartPadMiiStorage.hasPending(filesDir)) {
            " Changes are staged for the next game restart."
        } else {
            ""
        }
        content.addView(settingsLabel(
            "${records.size} Mii${if (records.size == 1) "" else "s"} available.$pending",
        ))
        content.addView(Button(this).apply {
            text = "Import Mii…"
            contentDescription = "Import a standard Mii file"
            setOnClickListener {
                startActivityForResult(
                    Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "application/octet-stream"
                    },
                    REQUEST_IMPORT_MII,
                )
            }
        })
        content.addView(Button(this).apply {
            text = "Remove a Mii…"
            contentDescription = "Remove a Mii"
            isEnabled = records.isNotEmpty()
            setOnClickListener { showMiiRemoval(records) }
        })
        content.addView(Button(this).apply {
            text = "Create a Mii…"
            contentDescription = "Learn how to create a Mii"
            setOnClickListener {
                AlertDialog.Builder(this@KartPadActivity)
                    .setTitle("Create a Mii")
                    .setMessage(
                        "KartPad does not include the Wii Menu or Mii Channel, so it cannot create a new Mii. Create or export a standard 74-byte .mii file with a compatible tool, then import it here.",
                    )
                    .setNegativeButton("Back", null)
                    .show()
            }
        })
        content.addView(Button(this).apply {
            text = "Done"
            contentDescription = "Close Mii manager"
            setOnClickListener { dialog.dismiss() }
        })
        dialog = AlertDialog.Builder(this)
            .setTitle("Manage Miis (Experimental)")
            .setView(ScrollView(this).apply { addView(content) })
            .create()
        dialog.show()
    }

    private fun showMiiRemoval(records: List<MiiRecord>) {
        if (records.isEmpty()) return
        val labels = records.map { record ->
            if (record.creator == "Unknown") record.name
            else "${record.name} — creator ${record.creator}"
        }.toTypedArray()
        AlertDialog.Builder(this)
            .setTitle("Remove a Mii")
            .setItems(labels) { _, which -> confirmMiiRemoval(records[which]) }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun confirmMiiRemoval(record: MiiRecord) {
        AlertDialog.Builder(this)
            .setTitle("Remove ${record.name}?")
            .setMessage(
                "The removal will apply after restarting the game. KartPad retains a backup and always keeps at least one Mii.",
            )
            .setNegativeButton("Cancel", null)
            .setPositiveButton("Remove") { _, _ ->
                runCatching {
                    val working = KartPadMiiStorage.readWorking(filesDir)
                    KartPadMiiStorage.writePending(
                        filesDir, nativeRemoveMii(working, record.slot),
                    )
                }.onSuccess {
                    showMiiChangeReady("${record.name} will be removed.")
                }.onFailure { error ->
                    showParityBoundary(
                        "Mii Could Not Be Removed",
                        safeMiiError(error, "The Mii removal could not be staged."),
                    )
                }
            }
            .show()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_IMPORT_MII || resultCode != RESULT_OK) return
        val uri = data?.data ?: return
        runCatching {
            val mii = readMiiDocument(uri)
            val working = KartPadMiiStorage.readWorking(filesDir)
            KartPadMiiStorage.writePending(
                filesDir, nativeImportMii(working, mii),
            )
        }.onSuccess {
            showMiiChangeReady("The selected Mii will be imported.")
        }.onFailure { error ->
            showParityBoundary(
                "Mii Import Failed",
                safeMiiError(error, "The selected Mii could not be imported."),
            )
        }
    }

    private fun readMiiDocument(uri: Uri): ByteArray {
        val input = contentResolver.openInputStream(uri)
            ?: error("The selected Mii file could not be opened.")
        input.use { stream ->
            val buffer = ByteArray(MII_FILE_BYTES + 1)
            var count = 0
            while (count < buffer.size) {
                val read = stream.read(buffer, count, buffer.size - count)
                if (read < 0) break
                count += read
            }
            require(count == MII_FILE_BYTES) {
                "A Mii file must contain exactly $MII_FILE_BYTES bytes."
            }
            return buffer.copyOf(MII_FILE_BYTES)
        }
    }

    private fun showMiiChangeReady(message: String) {
        AlertDialog.Builder(this)
            .setTitle("Mii Change Scheduled")
            .setMessage("$message The current database will be backed up automatically.")
            .setPositiveButton("Restart Now") { _, _ -> restartToGameSelector() }
            .setNegativeButton("Later", null)
            .show()
    }

    private fun parseMiiRecords(values: Array<String>): List<MiiRecord> {
        require(values.size % 3 == 0) { "The native Mii list is malformed." }
        return values.asList().chunked(3).map { valuesForRecord ->
            MiiRecord(
                slot = valuesForRecord[0].toInt(),
                name = valuesForRecord[1],
                creator = valuesForRecord[2],
            )
        }
    }

    private fun safeMiiError(error: Throwable, fallback: String): String =
        if (error is IllegalArgumentException && !error.message.isNullOrBlank()) {
            error.message!!
        } else {
            fallback
        }

    private fun showReportProblem() {
        val report = buildString {
            appendLine("KartPad Android diagnostic report")
            appendLine("Version: ${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})")
            appendLine("Android: ${android.os.Build.VERSION.RELEASE} (API ${android.os.Build.VERSION.SDK_INT})")
            appendLine("Device: ${android.os.Build.MANUFACTURER} ${android.os.Build.MODEL}")
            appendLine("Runtime profile: $runtimeProfile")
            appendLine("Retro Rewind release: ${RetroRewindRelease.VERSION}")
            appendLine()
            appendLine("What went wrong:")
        }
        AlertDialog.Builder(this)
            .setTitle("Report a Problem")
            .setMessage("KartPad can share a bounded technical summary. It excludes game data, saves, credentials, controller inputs, and local file paths.")
            .setPositiveButton("Share Report…") { _, _ ->
                startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_SUBJECT, "KartPad Android problem")
                    putExtra(Intent.EXTRA_TEXT, report)
                }, "Share KartPad report"))
            }
            .setNeutralButton("Report on GitHub") { _, _ ->
                startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(
                    "https://github.com/chrissotraidis/kartpad/issues/new?template=bug_report.yml",
                )))
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun showParityBoundary(title: String, message: String) {
        AlertDialog.Builder(this)
            .setTitle(title)
            .setMessage(message)
            .setNegativeButton("Back", null)
            .show()
    }

    @Suppress("SetTextI18n")
    private fun showTouchControlSettings() {
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(8), dp(24), dp(8))
        }
        val opacityLabel = settingsLabel("")
        val opacity = SeekBar(this).apply {
            max = 75
            progress = (KartPadTouchSettings.opacity(this@KartPadActivity) * 100f)
                .roundToInt() - 25
            contentDescription = "Control opacity"
        }
        fun refreshOpacityLabel() {
            opacityLabel.text = "Opacity: ${opacity.progress + 25}%"
        }
        refreshOpacityLabel()
        opacity.setOnSeekBarChangeListener(simpleSeekListener {
            KartPadTouchSettings.setOpacity(this, (opacity.progress + 25) / 100f)
            kartPadOverlay.reloadPresentationSettings()
            refreshOpacityLabel()
        })

        val sizeLabel = settingsLabel("")
        val size = SeekBar(this).apply {
            max = 65
            progress = (KartPadTouchSettings.size(this@KartPadActivity) * 100f)
                .roundToInt() - 70
            contentDescription = "All control sizes"
        }
        fun refreshSizeLabel() {
            sizeLabel.text = "All sizes: ${size.progress + 70}%"
        }
        refreshSizeLabel()
        size.setOnSeekBarChangeListener(simpleSeekListener {
            KartPadTouchSettings.setSize(this, (size.progress + 70) / 100f)
            kartPadOverlay.reloadPresentationSettings()
            refreshSizeLabel()
        })

        val hide = Switch(this).apply {
            text = "Hide on controller"
            setTextColor(Color.WHITE)
            isChecked = KartPadTouchSettings.hideOnController(this@KartPadActivity)
            contentDescription = "Hide touch controls when controller connected"
            setOnCheckedChangeListener { _, checked ->
                KartPadTouchSettings.setHideOnController(this@KartPadActivity, checked)
                refreshControllerHandoff()
            }
        }
        val modernCStick = Switch(this).apply {
            text = "Modern C-stick L/R"
            setTextColor(Color.WHITE)
            isChecked = KartPadTouchSettings.modernCStickHorizontal(this@KartPadActivity)
            contentDescription = "Reverse C-stick horizontal direction"
            setOnCheckedChangeListener { _, checked ->
                KartPadTouchSettings.setModernCStickHorizontal(
                    this@KartPadActivity, checked,
                )
                kartPadOverlay.reloadPresentationSettings()
            }
        }
        val moveControls = Button(this).apply {
            text = "Move controls"
            contentDescription = "Edit touch control layout"
        }
        val reset = Button(this).apply {
            text = "Reset This Device Layout"
            contentDescription = "Reset touch control layout"
            setOnClickListener {
                AlertDialog.Builder(this@KartPadActivity)
                    .setTitle("Reset Touch Control Layout?")
                    .setMessage(
                        "All control positions and sizes return to their defaults.",
                    )
                    .setNegativeButton("Cancel", null)
                    .setPositiveButton("Reset") { _, _ ->
                        opacity.progress = 57
                        size.progress = 30
                        hide.isChecked = true
                        modernCStick.isChecked = false
                        kartPadOverlay.resetLayoutSettings()
                        refreshControllerHandoff()
                    }
                    .show()
            }
        }
        content.addView(opacityLabel)
        content.addView(opacity)
        content.addView(sizeLabel)
        content.addView(size)
        content.addView(hide)
        content.addView(modernCStick)
        content.addView(moveControls)
        content.addView(reset)
        val scroll = ScrollView(this).apply { addView(content) }
        val dialog = AlertDialog.Builder(this)
            .setTitle("Touch Control Settings")
            .setView(scroll)
            .setNegativeButton("Done", null)
            .setOnDismissListener { kartPadOverlay.clearTouchInput() }
            .create()
        moveControls.setOnClickListener {
            dialog.dismiss()
            beginLayoutEditing()
        }
        dialog.show()
    }

    private fun addLayoutEditorBar() {
        editorLabel = settingsLabel("Tap or drag a control")
        editorSize = SeekBar(this).apply {
            max = 115
            progress = 40
            isEnabled = false
            contentDescription = "Selected control size"
            setOnSeekBarChangeListener(simpleSeekListener {
                if (!updatingEditorControls) {
                    kartPadOverlay.setSelectedControlSize((progress + 60) / 100f)
                }
            })
        }
        editorVisibility = Button(this).apply {
            text = "Hide"
            isEnabled = false
            contentDescription = "Hide selected control"
            setOnClickListener { kartPadOverlay.toggleSelectedControlVisibility() }
        }
        val back = Button(this).apply {
            text = "Back"
            contentDescription = "Back to Touch Control Settings"
            setOnClickListener { finishLayoutEditing(returnToSettings = true) }
        }
        editorBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(10), dp(6), dp(10), dp(6))
            background = GradientDrawable().apply {
                cornerRadius = dp(14).toFloat()
                setColor(Color.argb(245, 14, 14, 14))
                setStroke(dp(2), Color.rgb(255, 199, 51))
            }
            visibility = View.GONE
            addView(back, LinearLayout.LayoutParams(dp(100), dp(52)))
            addView(editorLabel, LinearLayout.LayoutParams(dp(250), dp(52)))
            addView(editorSize, LinearLayout.LayoutParams(dp(340), dp(52)))
            addView(editorVisibility, LinearLayout.LayoutParams(dp(110), dp(52)))
        }
        val params = RelativeLayout.LayoutParams(
            RelativeLayout.LayoutParams.WRAP_CONTENT,
            RelativeLayout.LayoutParams.WRAP_CONTENT,
        ).apply {
            addRule(RelativeLayout.ALIGN_PARENT_BOTTOM)
            addRule(RelativeLayout.CENTER_HORIZONTAL)
            setMargins(0, 0, 0, dp(12))
        }
        mLayout.addView(editorBar, params)
        kartPadOverlay.onEditSelectionChanged = { identifier, scale, hidden ->
            updatingEditorControls = true
            val selected = identifier != null
            editorLabel.text = identifier?.let { "$it size" } ?: "Tap or drag a control"
            editorSize.isEnabled = selected
            editorSize.progress = (scale * 100f).roundToInt() - 60
            editorVisibility.isEnabled = selected
            editorVisibility.text = if (hidden) "Show" else "Hide"
            editorVisibility.contentDescription = if (hidden) {
                "Show selected control"
            } else {
                "Hide selected control"
            }
            updatingEditorControls = false
        }
    }

    private fun beginLayoutEditing() {
        menuButton.visibility = View.GONE
        editorBar.visibility = View.VISIBLE
        mLayout.bringChildToFront(kartPadOverlay)
        mLayout.bringChildToFront(editorBar)
        kartPadOverlay.beginLayoutEditing()
    }

    private fun finishLayoutEditing(returnToSettings: Boolean) {
        kartPadOverlay.endLayoutEditing()
        editorBar.visibility = View.GONE
        menuButton.visibility = View.VISIBLE
        mLayout.bringChildToFront(menuButton)
        refreshControllerHandoff()
        if (returnToSettings) showTouchControlSettings()
    }

    private fun settingsLabel(value: String) = TextView(this).apply {
        text = value
        textSize = 16f
        setTextColor(Color.WHITE)
        setPadding(0, dp(10), 0, 0)
    }

    private fun simpleSeekListener(onChanged: () -> Unit) =
        object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                if (fromUser) onChanged()
            }
            override fun onStartTrackingTouch(seekBar: SeekBar?) = Unit
            override fun onStopTrackingTouch(seekBar: SeekBar?) = Unit
        }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).roundToInt()

    private fun isGameController(device: InputDevice): Boolean {
        val sources = device.sources
        return sources and InputDevice.SOURCE_GAMEPAD == InputDevice.SOURCE_GAMEPAD ||
            sources and InputDevice.SOURCE_JOYSTICK == InputDevice.SOURCE_JOYSTICK
    }

    private fun configureRuntimeProfile() {
        val debugRequested = if (BuildConfig.DEBUG) {
            intent.getStringExtra(DEBUG_EXTRA_RUNTIME_PROFILE)
        } else {
            null
        }
        val requested = debugRequested ?: intent.getStringExtra(EXTRA_RUNTIME_PROFILE) ?: "base"
        runtimeProfile = requested

        when (requested) {
            "base" -> {
                Os.setenv("KARTPAD_RUNTIME_PROFILE", requested, true)
                Log.i(TAG, "A3 runtime profile requested=base")
            }
            "retro_rewind" -> {
                val installed = RetroRewindInstallValidator.validate(
                    RetroRewindInstallStorage.installedRoot(filesDir)
                        .resolve(RetroRewindRelease.ROOT),
                    RetroRewindInstallValidator.productionContract(),
                )
                check(installed.isValid) {
                    "Retro Rewind launch requires a validated installed pack"
                }
                Os.setenv("KARTPAD_RUNTIME_PROFILE", requested, true)
                Log.i(TAG, "A3 runtime profile requested=retro_rewind installed=valid")
            }
            else -> error("Unsupported runtime profile")
        }
    }

    private fun configureDebugRkgInput() {
        if (!BuildConfig.DEBUG) return

        val fixture = File(filesDir, DEBUG_RKG_RELATIVE_PATH)
        val header = ByteArray(RKG_MAGIC.size)
        val valid = fixture.isFile &&
            fixture.length() in MIN_RKG_BYTES..MAX_RKG_BYTES &&
            runCatching {
                fixture.inputStream().use { input ->
                    input.read(header) == header.size && header.contentEquals(RKG_MAGIC)
                }
            }.getOrDefault(false)

        if (valid) {
            val keyboardSteer = File(filesDir, DEBUG_RKG_KEYBOARD_STEER_RELATIVE_PATH).isFile
            Os.setenv("KARTPAD_RKG_INPUT_V2", fixture.absolutePath, true)
            Os.setenv("KARTPAD_RKG_AUTOSTART_V2", "1", true)
            Os.setenv("KARTPAD_RKG_FORCE_METADATA_V2", "1", true)
            Os.setenv("KARTPAD_PRECISE_MENU_PULSE_V2", "1", true)
            if (keyboardSteer) {
                Os.setenv("KARTPAD_RKG_KEYBOARD_STEER_V2", "1", true)
                Os.setenv("KARTPAD_FULL_SYNTHETIC_STICK_V2", "1", true)
            } else {
                Os.unsetenv("KARTPAD_RKG_KEYBOARD_STEER_V2")
                Os.unsetenv("KARTPAD_FULL_SYNTHETIC_STICK_V2")
            }
            Log.i(TAG, "Debug app-private RKG input enabled; keyboard steer=$keyboardSteer")
        } else {
            Os.unsetenv("KARTPAD_RKG_INPUT_V2")
            Os.unsetenv("KARTPAD_RKG_AUTOSTART_V2")
            Os.unsetenv("KARTPAD_RKG_FORCE_METADATA_V2")
            Os.unsetenv("KARTPAD_PRECISE_MENU_PULSE_V2")
            Os.unsetenv("KARTPAD_RKG_KEYBOARD_STEER_V2")
            Os.unsetenv("KARTPAD_FULL_SYNTHETIC_STICK_V2")
        }
    }

    private fun configureDebugStateTrace() {
        if (!BuildConfig.DEBUG) return

        val marker = File(filesDir, DEBUG_STATE_TRACE_MARKER_RELATIVE_PATH)
        if (marker.isFile) {
            val output = File(filesDir, DEBUG_STATE_TRACE_RELATIVE_PATH)
            output.parentFile?.mkdirs()
            Os.setenv("KARTPAD_STATE_TRACE", output.absolutePath, true)
            Log.i(TAG, "Debug app-private state trace enabled")
        } else {
            Os.unsetenv("KARTPAD_STATE_TRACE")
        }
    }

    private fun runDebugRetroRewindExtractionFixture() {
        if (!BuildConfig.DEBUG || BuildConfig.GAME_RUNTIME ||
            !intent.getBooleanExtra(DEBUG_EXTRA_RETRO_REWIND_EXTRACTION, false)
        ) {
            return
        }
        val temporary = File(cacheDir, "RetroRewindExtractionFixture-${System.nanoTime()}")
        try {
            val staging = File(temporary, "stage")
            check(staging.mkdirs())
            val archive = File(temporary, "fixture.zip")
            ZipOutputStream(FileOutputStream(archive)).use { zip ->
                zip.putNextEntry(ZipEntry("${RetroRewindRelease.ROOT}/"))
                zip.closeEntry()
                zip.putNextEntry(ZipEntry("${RetroRewindRelease.ROOT}/version.txt"))
                zip.write("${RetroRewindRelease.VERSION}\n".toByteArray(Charsets.UTF_8))
                zip.closeEntry()
            }
            val result = RetroRewindArchiveExtractor.extract(
                archive.toPath(),
                staging.toPath(),
                { false },
                { _, _ -> },
            )
            val extracted = File(staging, "${RetroRewindRelease.ROOT}/version.txt")
                .readText(Charsets.UTF_8)
            check(result.isComplete() && result.selectedEntries == 2L &&
                result.selectedBytes == extracted.toByteArray(Charsets.UTF_8).size.toLong() &&
                result.extractedBytes == result.selectedBytes &&
                extracted == "${RetroRewindRelease.VERSION}\n")
            Log.i(TAG, "A3 JNI archive extraction passed entries=2 bytes=${result.extractedBytes}")
        } catch (error: Exception) {
            Log.e(TAG, "A3 JNI archive extraction failed", error)
        } finally {
            temporary.deleteRecursively()
        }
    }

    private fun runDebugRetroRewindWorkerFixture() {
        if (!BuildConfig.DEBUG || BuildConfig.GAME_RUNTIME) {
            return
        }
        when {
            intent.getBooleanExtra(DEBUG_EXTRA_RETRO_REWIND_WORKER, false) -> {
                runDebugRetroRewindResumeFixture()
                RetroRewindInstallWork.enqueueDebugFixture(this)
                RetroRewindInstallWork.enqueueDebugFixture(this)
                Log.i(TAG, "A3 durable worker fixture enqueued twice with KEEP")
            }
        }
    }

    private fun runDebugRetroRewindResumeFixture() {
        val content = "resume-fixture-content".toByteArray(Charsets.UTF_8)
        val resumeOffset = 7
        val partial = Files.createTempFile(cacheDir.toPath(), "resume-fixture-", ".part")
        try {
            Files.write(partial, content.copyOf(resumeOffset))
            val result = RetroRewindArchiveDownload.transferResuming(
                ByteArrayInputStream(content, resumeOffset, content.size - resumeOffset),
                partial,
                content.size.toLong(),
                DEBUG_RESUME_FIXTURE_SHA256,
                resumeOffset.toLong(),
                { false },
                { _, _ -> },
            )
            check(result == RetroRewindArchiveDownload.Error.NONE)
            check(Files.readAllBytes(partial).contentEquals(content))
            Log.i(
                TAG,
                "A3 resumable transfer passed prefix=$resumeOffset total=${content.size}",
            )
        } catch (error: Exception) {
            Log.e(TAG, "A3 resumable transfer failed", error)
        } finally {
            Files.deleteIfExists(partial)
        }
    }

    private external fun nativeApplyDisplaySettings(
        showFps: Boolean, aspectMode: Int, resolutionScale: Float,
    )

    private external fun nativeApplyControllerMapping(mapping: IntArray)

    private external fun nativeListMiis(database: ByteArray): Array<String>
    private external fun nativeImportMii(database: ByteArray, mii: ByteArray): ByteArray
    private external fun nativeRemoveMii(database: ByteArray, slot: Int): ByteArray

    companion object {
        private const val MENU_TITLE = 99
        private const val MENU_SWITCH_GAME = 100
        private const val MENU_MULTIPLAYER = 101
        private const val MENU_FPS = 102
        private const val MENU_CONTROLLER_MAPPING = 103
        private const val MENU_TOUCH_CONTROLS = 104
        private const val MENU_MOTION_STEERING = 105
        private const val MENU_WIIMOTE = 106
        private const val MENU_ASPECT_RATIO = 107
        private const val MENU_RENDER_RESOLUTION = 108
        private const val MENU_GAME_DATA = 109
        private const val MENU_RETRO_REWIND = 110
        private const val MENU_MIIS = 111
        private const val MENU_REPORT_PROBLEM = 112
        private const val MENU_CONTROLS_GROUP = 113
        private const val MENU_DISPLAY_GROUP = 114
        private const val MENU_DATA_GROUP = 115
        private const val SELECTOR_RESTART_DELAY_MS = 250L
        private const val REQUEST_IMPORT_MII = 4_301
        private const val MII_FILE_BYTES = 74
        const val EXTRA_RUNTIME_PROFILE = "dev.kartpad.android.RUNTIME_PROFILE"
        private const val TAG = "KartPadFixture"
        private const val DEBUG_RKG_RELATIVE_PATH = "KartPad/Diagnostics/TestInput.rkg"
        private const val DEBUG_RKG_KEYBOARD_STEER_RELATIVE_PATH =
            "KartPad/Diagnostics/TestInput.keyboard-steer"
        private const val DEBUG_STATE_TRACE_MARKER_RELATIVE_PATH =
            "KartPad/Diagnostics/StateTrace.enable"
        private const val DEBUG_STATE_TRACE_RELATIVE_PATH =
            "KartPad/Diagnostics/StateTrace.csv"
        private const val DEBUG_EXTRA_RETRO_REWIND_EXTRACTION =
            "dev.kartpad.android.TEST_RETRO_REWIND_EXTRACTION"
        private const val DEBUG_EXTRA_RETRO_REWIND_WORKER =
            "dev.kartpad.android.TEST_RETRO_REWIND_WORKER"
        private const val DEBUG_EXTRA_RUNTIME_PROFILE =
            "dev.kartpad.android.TEST_RUNTIME_PROFILE"
        private const val DEBUG_RESUME_FIXTURE_SHA256 =
            "cb9d5fc3b83611af65032f73119285de4e97d4b2b9f7b2e9567443635358483a"
        private const val MIN_RKG_BYTES = 0x90L
        private const val MAX_RKG_BYTES = 1024L * 1024L
        private val RKG_MAGIC = byteArrayOf('R'.code.toByte(), 'K'.code.toByte(), 'G'.code.toByte(), 'D'.code.toByte())
    }

    private data class MiiRecord(val slot: Int, val name: String, val creator: String)
}
