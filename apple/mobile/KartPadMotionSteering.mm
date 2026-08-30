#import "KartPadMotionSteering.h"

#import "SunPadDiagnostics.h"

#import <CoreMotion/CoreMotion.h>
#import <TargetConditionals.h>

#include <algorithm>
#include <atomic>
#include <cmath>
#include <limits>

namespace {

NSString *const kEnabledKey = @"KartPadMotionSteeringEnabled";
NSString *const kInvertedKey = @"KartPadMotionSteeringInverted";
NSString *const kSensitivityKey = @"KartPadMotionSteeringSensitivity";

double WrappedAngle(double value) {
  while (value > M_PI) value -= 2.0 * M_PI;
  while (value < -M_PI) value += 2.0 * M_PI;
  return value;
}

}  // namespace

float KartPadMotionSteeringValue(const double angle, const double center,
                                 const float sensitivity,
                                 const BOOL inverted) noexcept {
  if (!std::isfinite(angle) || !std::isfinite(center)) return 0.0f;
  const float boundedSensitivity = std::clamp(sensitivity, 0.5f, 2.0f);
  const double delta = WrappedAngle(angle - center);
  constexpr double kDeadZone = 0.045;
  const double fullLock = 0.70 / boundedSensitivity;
  const double magnitude = std::abs(delta);
  if (magnitude <= kDeadZone) return 0.0f;
  double value = std::copysign(
      std::min(1.0, (magnitude - kDeadZone) / (fullLock - kDeadZone)), delta);
  if (inverted) value = -value;
  return static_cast<float>(value);
}

@implementation KartPadMotionSteering {
#if TARGET_OS_IOS
  CMMotionManager *_motionManager;
  NSOperationQueue *_motionQueue;
#endif
  std::atomic<double> _lastAngle;
  std::atomic<double> _centerAngle;
  std::atomic<float> _steering;
  std::atomic_bool _calibrated;
}

+ (instancetype)sharedSteering {
  static KartPadMotionSteering *steering = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    steering = [[KartPadMotionSteering alloc] init];
  });
  return steering;
}

- (instancetype)init {
  self = [super init];
  if (self != nil) {
#if TARGET_OS_IOS
    _motionManager = [[CMMotionManager alloc] init];
    _motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
    _motionQueue = [[NSOperationQueue alloc] init];
    _motionQueue.name = @"dev.kartpad.motion-steering";
    _motionQueue.maxConcurrentOperationCount = 1;
#endif
    _lastAngle.store(std::numeric_limits<double>::quiet_NaN());
    _centerAngle.store(0.0);
    _steering.store(0.0f);
    _calibrated.store(false);
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([defaults objectForKey:kSensitivityKey] == nil) {
      [defaults setFloat:1.0f forKey:kSensitivityKey];
    }
  }
  return self;
}

- (BOOL)isSensorAvailable {
#if TARGET_OS_IOS
  return _motionManager.deviceMotionAvailable;
#else
  return NO;
#endif
}

- (BOOL)isEnabled {
  return [NSUserDefaults.standardUserDefaults boolForKey:kEnabledKey];
}

- (void)setEnabled:(BOOL)enabled {
  [NSUserDefaults.standardUserDefaults setBool:enabled forKey:kEnabledKey];
  if (enabled) {
    [self start];
  } else {
    [self stop];
  }
  SunPadLog(@"motion steering enabled=%d sensor=%d", enabled,
            self.sensorAvailable);
}

- (BOOL)isInverted {
  return [NSUserDefaults.standardUserDefaults boolForKey:kInvertedKey];
}

- (void)setInverted:(BOOL)inverted {
  [NSUserDefaults.standardUserDefaults setBool:inverted forKey:kInvertedKey];
}

- (float)sensitivity {
  const float value = [NSUserDefaults.standardUserDefaults floatForKey:kSensitivityKey];
  return std::clamp(value, 0.5f, 2.0f);
}

- (void)setSensitivity:(float)sensitivity {
  [NSUserDefaults.standardUserDefaults
      setFloat:std::clamp(sensitivity, 0.5f, 2.0f)
        forKey:kSensitivityKey];
}

- (float)currentSteering {
  return self.enabled ? _steering.load(std::memory_order_relaxed) : 0.0f;
}

- (void)start {
#if TARGET_OS_IOS
  if (!self.enabled || !self.sensorAvailable || _motionManager.deviceMotionActive) {
    return;
  }
  _calibrated.store(false, std::memory_order_relaxed);
  _steering.store(0.0f, std::memory_order_relaxed);
  __weak KartPadMotionSteering *weakSelf = self;
  [_motionManager startDeviceMotionUpdatesToQueue:_motionQueue
                                      withHandler:^(CMDeviceMotion *motion,
                                                    NSError *error) {
    KartPadMotionSteering *strongSelf = weakSelf;
    if (strongSelf == nil || error != nil) return;
    const CMAcceleration gravity = motion.gravity;
    if (std::hypot(gravity.x, gravity.y) < 0.08) return;
    const double angle = std::atan2(gravity.y, gravity.x);
    strongSelf->_lastAngle.store(angle, std::memory_order_relaxed);
    if (!strongSelf->_calibrated.exchange(true, std::memory_order_relaxed)) {
      strongSelf->_centerAngle.store(angle, std::memory_order_relaxed);
    }
    const float value = KartPadMotionSteeringValue(
        angle, strongSelf->_centerAngle.load(std::memory_order_relaxed),
        strongSelf.sensitivity, strongSelf.inverted);
    strongSelf->_steering.store(value, std::memory_order_relaxed);
  }];
  SunPadLog(@"motion steering started");
#endif
}

- (void)stop {
#if TARGET_OS_IOS
  [_motionManager stopDeviceMotionUpdates];
#endif
  _steering.store(0.0f, std::memory_order_relaxed);
  _calibrated.store(false, std::memory_order_relaxed);
}

- (void)recenter {
  const double angle = _lastAngle.load(std::memory_order_relaxed);
  if (!std::isfinite(angle)) return;
  _centerAngle.store(angle, std::memory_order_relaxed);
  _steering.store(0.0f, std::memory_order_relaxed);
  _calibrated.store(true, std::memory_order_relaxed);
  SunPadLog(@"motion steering recentered");
}

@end
