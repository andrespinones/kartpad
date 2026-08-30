#pragma once

#include <cstdint>

struct KartPadMobileClassicInputSnapshot {
  std::uint32_t buttons = 0;
  float leftStickX = 0.0f;
  float leftStickY = 0.0f;
  int connected = 0;
};

extern "C" {

// Called after Aurora has created its SDL/UIKit Metal window.
void KartPadMobileRuntimeHostInstall(void *sdlWindow);
void KartPadMobileRuntimeHostUninstall();

// Consumes the exact SunPad mixer's latched state and maps it to the Mario Kart
// Classic Controller ABI. Returns false until the UIKit host is installed.
bool KartPadMobileReadClassicInput(KartPadMobileClassicInputSnapshot *snapshot);

}
