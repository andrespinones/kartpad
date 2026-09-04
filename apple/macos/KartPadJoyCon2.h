#pragma once

#import <Foundation/Foundation.h>

/* Experimental direct Bluetooth LE support for Nintendo Switch 2 controllers
 * (Joy-Con 2 L, Joy-Con 2 R, Pro Controller 2) on macOS.
 *
 * Each connected controller becomes its own SDL virtual gamepad, so two
 * Joy-Con 2 halves held sideways are two independent players. No kernel or
 * DriverKit driver is involved: KartPad talks to the controllers through
 * CoreBluetooth and feeds SDL directly. */

FOUNDATION_EXPORT NSString *const KartPadExperimentalJoyCon2DefaultsKey;
FOUNDATION_EXPORT NSString *const KartPadJoyCon2RememberMacDefaultsKey;

/* Opens the connection panel and starts scanning. */
void KartPadShowJoyCon2Pairing(void);

/* Starts or stops the Bluetooth LE bridge according to the stored
 * preference. Safe to call before SDL's joystick subsystem is initialized;
 * controllers attach to SDL lazily once it is. */
void KartPadApplyExperimentalJoyCon2Preference(void);
