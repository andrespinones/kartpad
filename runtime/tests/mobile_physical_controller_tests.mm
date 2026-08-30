#include "../../apple/mobile/KartPadClassicInput.h"
#include "../../apple/mobile/KartPadPhysicalControllers.h"
#include "../../apple/third_party/sunpad/SunPadControllerSlots.h"

#include <cstdlib>
#include <iostream>
#include <stdexcept>

namespace {

void Require(const bool condition, const char* message) {
  if (!condition) throw std::runtime_error(message);
}

void TestExactSunPadSlotReconciliation() {
  constexpr uintptr_t first = 0x1001;
  constexpr uintptr_t second = 0x2001;
  constexpr uintptr_t returned = 0x1002;
  SunPadControllerSlots slots;
  auto result = slots.Reconcile({first, second});
  Require(result.assigned.size() == 2, "two controllers were not assigned");
  Require(slots.SlotFor(first) == 0 && slots.SlotFor(second) == 1,
          "initial player slots changed");
  result = slots.Reconcile({second});
  Require(result.removed.size() == 1 && result.removed[0].slot == 0,
          "disconnected player one was not removed");
  result = slots.Reconcile({second, returned});
  Require(slots.SlotFor(returned) == 0 && slots.SlotFor(second) == 1,
          "stable slots were not preserved after reconnect");
}

void TestControllerSampleMapping() {
  KartPadPhysicalControllerSample sample;
  sample.faceButtons = static_cast<SunPadPhysicalControllerButton>(
      SunPadPhysicalControllerButtonA | SunPadPhysicalControllerButtonB |
      SunPadPhysicalControllerButtonX | SunPadPhysicalControllerButtonY |
      SunPadPhysicalControllerButtonLeftShoulder);
  sample.menu = true;
  sample.dpadUp = true;
  sample.dpadRight = true;
  sample.rightShoulder = true;
  sample.leftX = -1.4f;
  sample.leftY = 0.5f;
  sample.rightX = 0.25f;
  sample.rightY = -0.75f;
  sample.leftTrigger = 0.5f;
  sample.rightTrigger = 0.25f;

  const SunPadInputState state = KartPadAdaptPhysicalControllerSample(
      sample, SunPadDefaultControllerButtonMapping());
  const uint16_t expectedButtons =
      SunPadButtonA | SunPadButtonB | SunPadButtonX | SunPadButtonY |
      SunPadButtonZ | SunPadButtonStart | SunPadButtonDpadUp |
      SunPadButtonDpadRight | SunPadButtonL | SunPadButtonR;
  Require(state.connected == 1, "controller connection was lost");
  Require(state.buttons == expectedButtons, "SunPad physical mapping changed");
  Require(state.stickX == -127 && state.stickY == 64,
          "left stick normalization changed");
  Require(state.cStickX == 32 && state.cStickY == -95,
          "right stick normalization changed");
  Require(state.triggerL == 128 && state.triggerR == 128,
          "trigger pressure mapping changed");

  const KartPadClassicInputState classic =
      kartpad::mobile::AdaptSunPadInput(state);
  Require(classic.connected, "Classic controller connection was lost");
  Require((classic.buttons & kartpad::mobile::kClassicButtonA) != 0,
          "physical A did not reach Classic A");
  Require((classic.buttons & kartpad::mobile::kClassicButtonR) != 0,
          "physical trigger did not reach Classic R");
  Require((classic.buttons & kartpad::mobile::kClassicButtonPlus) != 0,
          "physical Menu did not reach Classic Plus");
}

}  // namespace

int main() {
  @autoreleasepool {
    try {
      TestExactSunPadSlotReconciliation();
      TestControllerSampleMapping();
      std::cout << "KartPad mobile physical-controller bridge passed\n";
      return EXIT_SUCCESS;
    } catch (const std::exception& error) {
      std::cerr << "KartPad mobile physical-controller bridge failed: "
                << error.what() << '\n';
      return EXIT_FAILURE;
    }
  }
}
