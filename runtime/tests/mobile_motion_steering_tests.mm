#include "../../apple/mobile/KartPadMotionSteering.h"

#include <cmath>
#include <cstdlib>
#include <iostream>
#include <stdexcept>

namespace {

void Require(bool condition, const char *message) {
  if (!condition) throw std::runtime_error(message);
}

void RequireNear(float actual, float expected, float tolerance,
                 const char *message) {
  Require(std::abs(actual - expected) <= tolerance, message);
}

void TestMotionMapping() {
  RequireNear(KartPadMotionSteeringValue(1.0, 1.0, 1.0f, NO), 0.0f, 0.0001f,
              "center did not map to neutral");
  RequireNear(KartPadMotionSteeringValue(1.03, 1.0, 1.0f, NO), 0.0f, 0.0001f,
              "dead zone was not retained");
  Require(KartPadMotionSteeringValue(1.35, 1.0, 1.0f, NO) > 0.4f,
          "positive tilt did not steer right");
  Require(KartPadMotionSteeringValue(0.65, 1.0, 1.0f, NO) < -0.4f,
          "negative tilt did not steer left");
  RequireNear(KartPadMotionSteeringValue(2.0, 1.0, 1.0f, NO), 1.0f, 0.0001f,
              "full lock did not clamp");
  RequireNear(KartPadMotionSteeringValue(1.35, 1.0, 1.0f, YES),
              -KartPadMotionSteeringValue(1.35, 1.0, 1.0f, NO), 0.0001f,
              "inversion changed magnitude");
  Require(KartPadMotionSteeringValue(-3.05, 3.05, 1.0f, NO) > 0.0f,
          "angle wrap crossed in the wrong direction");
  Require(KartPadMotionSteeringValue(1.25, 1.0, 2.0f, NO) >
              KartPadMotionSteeringValue(1.25, 1.0, 0.5f, NO),
          "sensitivity did not increase response");
  RequireNear(KartPadMotionSteeringValue(NAN, 0.0, 1.0f, NO), 0.0f, 0.0001f,
              "invalid sensor input was not neutral");
}

}  // namespace

int main() {
  @autoreleasepool {
    try {
      TestMotionMapping();
      std::cout << "KartPad mobile motion-steering mapping passed\n";
      return EXIT_SUCCESS;
    } catch (const std::exception &error) {
      std::cerr << "KartPad mobile motion-steering mapping failed: "
                << error.what() << '\n';
      return EXIT_FAILURE;
    }
  }
}
