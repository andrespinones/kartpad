#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/* Converts a calibrated device angle into a normalized Classic-stick value.
 * The dead zone is removed continuously, then full lock is clamped. */
float KartPadMotionSteeringValue(double angle, double center,
                                 float sensitivity, BOOL inverted) noexcept;

@interface KartPadMotionSteering : NSObject

+ (instancetype)sharedSteering;

@property(nonatomic, assign, getter=isEnabled) BOOL enabled;
@property(nonatomic, assign, getter=isInverted) BOOL inverted;
@property(nonatomic, assign) float sensitivity;
@property(nonatomic, readonly, getter=isSensorAvailable) BOOL sensorAvailable;
@property(nonatomic, readonly) float currentSteering;

- (void)start;
- (void)stop;
- (void)recenter;

@end

NS_ASSUME_NONNULL_END
