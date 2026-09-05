package dev.kartpad.android

import android.app.Activity
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.StateListDrawable
import android.os.Bundle
import android.text.Spannable
import android.text.SpannableString
import android.text.style.AbsoluteSizeSpan
import android.text.style.ForegroundColorSpan
import android.text.style.StyleSpan
import android.util.Log
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.TextView
import java.util.concurrent.Executors

/** Production owner for choosing the immutable runtime profile before SDL starts. */
class KartPadLaunchActivity : Activity() {
    private lateinit var status: TextView
    private lateinit var original: Button
    private lateinit var retro: Button
    private lateinit var manageGameData: Button
    private lateinit var progress: ProgressBar
    private val validator = Executors.newSingleThreadExecutor()
    private var validationGeneration = 0
    private var retroInstalled = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(buildContent())
        original.setOnClickListener { launch("base") }
        retro.setOnClickListener {
            if (retroInstalled) {
                launch("retro_rewind")
            } else {
                startActivity(Intent(this, RetroRewindInstallActivity::class.java))
            }
        }
        manageGameData.setOnClickListener {
            startActivity(Intent(this, KartPadGameDataActivity::class.java))
        }
    }

    override fun onResume() {
        super.onResume()
        validateRetroRewind()
    }

    override fun onDestroy() {
        validationGeneration += 1
        validator.shutdownNow()
        super.onDestroy()
    }

    private fun validateRetroRewind() {
        val generation = ++validationGeneration
        val forceNotInstalled = BuildConfig.DEBUG &&
            intent.getBooleanExtra(EXTRA_DEBUG_RETRO_NOT_INSTALLED, false)
        retroInstalled = false
        showStatus("Checking game data and Retro Rewind ${RetroRewindRelease.VERSION}…")
        progress.visibility = View.VISIBLE
        original.isEnabled = false
        retro.isEnabled = false
        validator.execute {
            val removalError = KartPadGameDataStorage.applyScheduledRemoval(filesDir)
            val gameDataValid = removalError == null &&
                KartPadGameDataStorage.validationError(filesDir) == null
            val valid = !forceNotInstalled && runCatching {
                RetroRewindInstallStorage.recover(filesDir)
                RetroRewindInstallValidator.validate(
                    RetroRewindInstallStorage.installedRoot(filesDir)
                        .resolve(RetroRewindRelease.ROOT),
                    RetroRewindInstallValidator.productionContract(),
                ).isValid
            }.getOrDefault(false)
            runOnUiThread {
                if (generation != validationGeneration || isFinishing || isDestroyed) {
                    return@runOnUiThread
                }
                retroInstalled = valid
                progress.visibility = View.GONE
                original.isEnabled = gameDataValid
                retro.isEnabled = gameDataValid
                if (removalError != null) {
                    showStatus(removalError)
                } else if (!gameDataValid) {
                    showStatus("Import your RMCP01 disc image or extracted game data to race")
                } else if (valid) {
                    hideStatus("Original and Retro Rewind ${RetroRewindRelease.VERSION} are ready")
                    setModeText(
                        retro,
                        "Retro Rewind",
                        "Installed ${RetroRewindRelease.VERSION} • Extra content + Retro WFC",
                    )
                } else {
                    hideStatus("Original is ready; Retro Rewind is optional")
                    setModeText(
                        retro,
                        "Retro Rewind",
                        "Download ${RetroRewindRelease.VERSION} • Extra content + Retro WFC",
                    )
                }
                Log.i(LOG_TAG, "A3 mode chooser retro-installed=$valid")
            }
        }
    }

    private fun launch(profile: String) {
        Log.i(LOG_TAG, "A3 mode chooser selected=$profile")
        startActivity(
            Intent(this, KartPadActivity::class.java)
                .putExtra(KartPadActivity.EXTRA_RUNTIME_PROFILE, profile),
        )
        // The translated runtime is process-global and is not restartable in
        // place. Do not leave the chooser behind the SDL activity where Back
        // could imply that another profile can be selected in this process.
        finish()
    }

    private fun buildContent(): View {
        val density = resources.displayMetrics.density
        fun dp(value: Int) = (value * density + 0.5f).toInt()
        fun label(text: String, size: Float, color: Int): TextView = TextView(this).apply {
            this.text = text
            textSize = size
            setTextColor(color)
            gravity = Gravity.CENTER
        }
        fun layout(bottom: Int) = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT,
        ).apply { bottomMargin = bottom }

        fun roundedButton(normal: Int, pressed: Int): StateListDrawable = StateListDrawable().apply {
            fun fill(color: Int) = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(18).toFloat()
                setColor(color)
            }
            addState(intArrayOf(android.R.attr.state_pressed), fill(pressed))
            addState(intArrayOf(-android.R.attr.state_enabled), fill(Color.rgb(62, 62, 72)))
            addState(intArrayOf(), fill(normal))
        }
        fun styleModeButton(button: Button, color: Int, pressed: Int, icon: Int) {
            button.apply {
                isAllCaps = false
                gravity = Gravity.START or Gravity.CENTER_VERTICAL
                textAlignment = View.TEXT_ALIGNMENT_VIEW_START
                includeFontPadding = false
                minHeight = dp(88)
                minimumHeight = dp(88)
                setPadding(dp(28), dp(18), dp(28), dp(18))
                background = roundedButton(color, pressed)
                backgroundTintList = null
                setTextColor(Color.WHITE)
                elevation = 0f
                stateListAnimator = null
                compoundDrawablePadding = dp(12)
                val drawable = requireNotNull(getDrawable(icon)).mutate().apply {
                    setTint(Color.WHITE)
                    setBounds(0, 0, dp(30), dp(30))
                }
                setCompoundDrawablesRelative(drawable, null, null, null)
            }
        }

        val background = GradientDrawable(
            GradientDrawable.Orientation.TL_BR,
            intArrayOf(
                Color.rgb(6, 19, 38),
                Color.rgb(26, 14, 46),
                Color.rgb(46, 11, 20),
            ),
        )
        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(0, dp(12), 0, dp(12))
        }
        column.addView(ImageView(this).apply {
            setImageResource(android.R.drawable.ic_menu_compass)
            imageTintList = ColorStateList.valueOf(Color.rgb(255, 107, 46))
            contentDescription = "KartPad"
            scaleType = ImageView.ScaleType.CENTER_INSIDE
        }, LinearLayout.LayoutParams(dp(48), dp(48)).apply {
            gravity = Gravity.CENTER_HORIZONTAL
            bottomMargin = dp(2)
        })
        column.addView(label("KartPad", 34f, Color.WHITE).apply {
            setTypeface(typeface, Typeface.BOLD)
            includeFontPadding = false
        }, layout(dp(4)))
        column.addView(
            label("Choose your way to race", 20f, Color.argb(224, 255, 255, 255)).apply {
                setTypeface(typeface, Typeface.BOLD)
                includeFontPadding = false
            },
            layout(dp(8)),
        )
        column.addView(
            label(
                "Your own RMCP01 disc image or extracted game data is required before play.",
                16f,
                Color.argb(158, 255, 255, 255),
            ),
            layout(dp(24)),
        )
        original = Button(this).apply {
            id = R.id.kartpad_mode_original
            styleModeButton(
                this,
                Color.rgb(8, 125, 255),
                Color.rgb(4, 99, 214),
                android.R.drawable.ic_menu_directions,
            )
            setModeText(this, "Mario Kart Wii", "Original game")
        }
        retro = Button(this).apply {
            id = R.id.kartpad_mode_retro_rewind
            styleModeButton(
                this,
                Color.rgb(245, 56, 99),
                Color.rgb(207, 38, 78),
                android.R.drawable.ic_menu_revert,
            )
            setModeText(this, "Retro Rewind", "Checking installation…")
            isEnabled = false
        }
        val choices = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            addView(
                original,
                LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                    .apply { marginEnd = dp(9) },
            )
            addView(
                retro,
                LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                    .apply { marginStart = dp(9) },
            )
        }
        column.addView(choices, layout(dp(10)))
        manageGameData = Button(this).apply {
            id = R.id.kartpad_manage_game_data
            text = "Manage Game Data…"
            contentDescription = "Import, reimport, or remove private game data"
            isAllCaps = false
            textSize = 15f
            setTextColor(Color.argb(224, 255, 255, 255))
            backgroundTintList = ColorStateList.valueOf(Color.argb(52, 255, 255, 255))
            minHeight = dp(42)
            minimumHeight = dp(42)
            setPadding(dp(20), 0, dp(20), 0)
        }
        column.addView(
            manageGameData,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = dp(4)
            },
        )
        progress = ProgressBar(this).apply {
            isIndeterminate = true
        }
        column.addView(progress, LinearLayout.LayoutParams(dp(28), dp(28)).apply {
            gravity = Gravity.CENTER_HORIZONTAL
            bottomMargin = dp(2)
        })
        status = label(
            "Checking game data and Retro Rewind ${RetroRewindRelease.VERSION}…",
            13f,
            Color.argb(184, 255, 255, 255),
        )
        status.id = R.id.kartpad_mode_status
        status.accessibilityLiveRegion = View.ACCESSIBILITY_LIVE_REGION_POLITE
        column.addView(status, layout(0))

        val availableWidthDp = (resources.displayMetrics.widthPixels / density).toInt() - 64
        val contentWidth = dp(minOf(760, maxOf(320, availableWidthDp)))
        val scroll = ScrollView(this).apply {
            isFillViewport = true
            clipToPadding = false
            addView(column, FrameLayout.LayoutParams(
                contentWidth,
                FrameLayout.LayoutParams.WRAP_CONTENT,
                Gravity.CENTER,
            ))
        }
        return FrameLayout(this).apply {
            this.background = background
            setPadding(dp(32), 0, dp(32), 0)
            addView(scroll, FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            ))
        }
    }

    private fun setModeText(button: Button, title: String, subtitle: String) {
        val combined = "$title\n$subtitle"
        button.text = SpannableString(combined).apply {
            setSpan(StyleSpan(Typeface.BOLD), 0, title.length, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
            setSpan(AbsoluteSizeSpan(18, true), 0, title.length, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
            setSpan(
                AbsoluteSizeSpan(14, true),
                title.length + 1,
                combined.length,
                Spannable.SPAN_EXCLUSIVE_EXCLUSIVE,
            )
            setSpan(
                ForegroundColorSpan(Color.argb(205, 255, 255, 255)),
                title.length + 1,
                combined.length,
                Spannable.SPAN_EXCLUSIVE_EXCLUSIVE,
            )
        }
        button.contentDescription = "$title\n$subtitle"
    }

    private fun showStatus(message: String) {
        status.text = message
        status.visibility = View.VISIBLE
    }

    private fun hideStatus(accessibilityMessage: String) {
        status.text = accessibilityMessage
        status.visibility = View.GONE
        status.announceForAccessibility(accessibilityMessage)
    }

    companion object {
        private const val LOG_TAG = "KartPadLauncher"
        private const val EXTRA_DEBUG_RETRO_NOT_INSTALLED =
            "dev.kartpad.android.TEST_MODE_CHOOSER_RETRO_NOT_INSTALLED"
    }
}
