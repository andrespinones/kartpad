#pragma once

#include <cstdint>

struct KartPadMobileClassicInputSnapshot {
  std::uint32_t buttons = 0;
  float leftStickX = 0.0f;
  float leftStickY = 0.0f;
  int connected = 0;
};

struct KartPadMobileRuntimeSettings {
  int aspectRatioMode = 0;
  float resolutionScale = 1.0f;
  int showFps = 0;
};

extern "C" {

// Holds the iOS launch in a native import flow until a complete, validated
// private RMCP01 data tree is available. Existing valid data returns directly.
bool KartPadMobileEnsureGameDataAvailable();

// Called after Aurora has created its SDL/UIKit Metal window.
void KartPadMobileRuntimeHostInstall(void *sdlWindow);
void KartPadMobileRuntimeHostUninstall();

// Reads the persisted settings owned by the exact SunPad shell before Aurora
// creates the mobile render surface. Aspect modes match SunPadSettings:
// 0 = original 4:3, 1 = fixed 16:9, 2 = experimental surface fill.
bool KartPadMobileReadRuntimeSettings(KartPadMobileRuntimeSettings *settings);

// Consumes the exact SunPad mixer's latched state and maps it to the Mario Kart
// Classic Controller ABI. Returns false until the UIKit host is installed.
bool KartPadMobileReadClassicInput(KartPadMobileClassicInputSnapshot *snapshot);

// Reads touch plus the first physical controller for player zero, or the
// independently assigned physical controller for players one through three.
bool KartPadMobileReadClassicInputForPlayer(
    unsigned int player, KartPadMobileClassicInputSnapshot *snapshot);

}
