// Experimental Nintendo Switch 2 controller bridge for macOS.
//
// Protocol details (advertisement layout, GATT UUIDs, command framing, button
// bits, stick packing, calibration addresses, pairing commands) follow the
// public reverse-engineering work in Nadeflore/switch2-controllers (MIT) and
// OZORDI/JoyCon2Mac (MIT). No Nintendo code or data is included.
//
// Copyright 2026 KartPad contributors
// SPDX-License-Identifier: GPL-2.0-or-later

#import "KartPadJoyCon2.h"

#import <AppKit/AppKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <IOBluetooth/IOBluetooth.h>

#include <SDL3/SDL_gamepad.h>
#include <SDL3/SDL_hints.h>
#include <SDL3/SDL_init.h>
#include <SDL3/SDL_joystick.h>
#include <SDL3/SDL_stdinc.h>

#include <algorithm>
#include <array>
#include <climits>
#include <cmath>
#include <cstdint>
#include <cstring>

NSString *const KartPadExperimentalJoyCon2DefaultsKey =
    @"KartPadExperimentalJoyCon2Enabled";
NSString *const KartPadJoyCon2RememberMacDefaultsKey =
    @"KartPadJoyCon2RememberMac";
NSString *const KartPadSeparateOriginalJoyConsDefaultsKey =
    @"KartPadSeparateOriginalJoyCons";

namespace {

// Bluetooth identity -------------------------------------------------------

constexpr uint16_t kNintendoCompanyID = 0x0553;
constexpr uint16_t kNintendoVendorID = 0x057E;
constexpr uint16_t kProductJoyCon2Right = 0x2066;
constexpr uint16_t kProductJoyCon2Left = 0x2067;
constexpr uint16_t kProductProController2 = 0x2069;

// CoreBluetooth hands us the manufacturer payload with the 2-byte company id
// in front. After that: 01 00 03 | vendor(2 LE) | product(2 LE) | 3 bytes |
// reconnect host address (6 bytes, little-endian) | ...
constexpr NSUInteger kAdvVendorOffset = 5;
constexpr NSUInteger kAdvProductOffset = 7;
constexpr NSUInteger kAdvReconnectOffset = 12;
constexpr NSUInteger kAdvMinimumLength = kAdvReconnectOffset + 6;

NSString *const kInputUUID = @"AB7DE9BE-89FE-49AD-828F-118F09DF7FD2";
NSString *const kCommandUUID = @"649D4AC9-8EB7-4E6C-AF44-1EA54FE5F005";
NSString *const kResponseUUID = @"C765A961-D9D8-4D36-A20A-5315B111836A";
NSString *const kVibrationLeftUUID = @"289326CB-A471-485D-A8F4-240C14F18241";
NSString *const kVibrationRightUUID = @"FA19B0FB-CD1F-46A7-84A1-BBB09E00C149";
NSString *const kVibrationProUUID = @"CC483F51-9258-427D-A939-630C31F72B05";

constexpr size_t kMaxControllers = 4;
constexpr NSTimeInterval kCommandTimeout = 1.5;
constexpr NSTimeInterval kConnectCooldown = 5.0;

// The controller lets a vibration decay unless it is refreshed, so an active
// rumble is re-sent at this interval (switch2-controllers uses the same).
constexpr NSTimeInterval kRumbleRefreshInterval = 0.02;

// Input report ---------------------------------------------------------------

constexpr NSUInteger kReportButtonsOffset = 4;   // 32-bit little-endian
constexpr NSUInteger kReportLeftStickOffset = 10;  // 3 bytes, 12-bit X then Y
constexpr NSUInteger kReportRightStickOffset = 13;
constexpr NSUInteger kReportMinimumLength = 16;

enum : uint32_t {
  kBtnY = 1u << 0,
  kBtnX = 1u << 1,
  kBtnB = 1u << 2,
  kBtnA = 1u << 3,
  kBtnSRRight = 1u << 4,
  kBtnSLRight = 1u << 5,
  kBtnR = 1u << 6,
  kBtnZR = 1u << 7,
  kBtnMinus = 1u << 8,
  kBtnPlus = 1u << 9,
  kBtnRightStick = 1u << 10,
  kBtnLeftStick = 1u << 11,
  kBtnHome = 1u << 12,
  kBtnCapture = 1u << 13,
  kBtnC = 1u << 14,
  kBtnDown = 1u << 16,
  kBtnUp = 1u << 17,
  kBtnRight = 1u << 18,
  kBtnLeft = 1u << 19,
  kBtnSRLeft = 1u << 20,
  kBtnSLLeft = 1u << 21,
  kBtnL = 1u << 22,
  kBtnZL = 1u << 23,
};

// Command channel ------------------------------------------------------------

constexpr uint8_t kCmdMemory = 0x02;
constexpr uint8_t kSubMemoryRead = 0x04;
constexpr uint8_t kCmdLeds = 0x09;
constexpr uint8_t kSubLedsSetPlayer = 0x07;
constexpr uint8_t kCmdPair = 0x15;
constexpr uint8_t kSubPairSetMac = 0x01;
constexpr uint8_t kSubPairLtk1 = 0x04;
constexpr uint8_t kSubPairLtk2 = 0x02;
constexpr uint8_t kSubPairFinish = 0x03;

constexpr uint32_t kAddrUserCalibrationStick1 = 0x1FC042;
constexpr uint32_t kAddrFactoryCalibrationStick1 = 0x0130A8;
constexpr uint32_t kAddrUserCalibrationStick2 = 0x1FC062;
constexpr uint32_t kAddrFactoryCalibrationStick2 = 0x0130E8;
constexpr uint8_t kCalibrationLength = 0x0B;

constexpr std::array<uint8_t, 8> kPlayerLedPatterns = {
    0x01, 0x03, 0x07, 0x0F, 0x09, 0x05, 0x0D, 0x06};

// SDL virtual gamepad layout: buttons 0..15 follow SDL_GamepadButton order so
// the automatic virtual mapping lines up one-to-one.
constexpr int kVirtualButtonCount = SDL_GAMEPAD_BUTTON_MISC1 + 1;
constexpr int kVirtualAxisCount = SDL_GAMEPAD_AXIS_COUNT;

enum class ControllerKind { JoyConLeft, JoyConRight, ProController };

struct StickCalibration {
  int centerX = 2048, centerY = 2048;
  int maxX = 1500, maxY = 1500;  // positive excursion from center
  int minX = 1500, minY = 1500;  // negative excursion from center
  bool valid = false;
};

// Fallback used when the controller memory read fails: settle on a center
// after the stick rests in the neutral band for a while (JoyCon2Mac approach).
struct AutoCalibration {
  int centerX = 2048, centerY = 2048;
  int lastX = INT_MIN, lastY = INT_MIN;
  int stableSamples = 0;
  long long sumX = 0, sumY = 0;
  bool calibrated = false;
};

struct StickRaw {
  int x = 0;
  int y = 0;
};

struct GamepadState {
  std::array<bool, kVirtualButtonCount> buttons{};
  std::array<Sint16, kVirtualAxisCount> axes{};
};

uint16_t ReadU16(const uint8_t *p) {
  return static_cast<uint16_t>(p[0] | (p[1] << 8));
}

uint32_t ReadU32(const uint8_t *p) {
  return static_cast<uint32_t>(p[0]) | (static_cast<uint32_t>(p[1]) << 8) |
         (static_cast<uint32_t>(p[2]) << 16) | (static_cast<uint32_t>(p[3]) << 24);
}

StickRaw ReadStick(const uint8_t *p) {
  const uint32_t packed = static_cast<uint32_t>(p[0]) |
                          (static_cast<uint32_t>(p[1]) << 8) |
                          (static_cast<uint32_t>(p[2]) << 16);
  return {static_cast<int>(packed & 0xFFF), static_cast<int>(packed >> 12)};
}

const char *KindName(ControllerKind kind) {
  switch (kind) {
    case ControllerKind::JoyConLeft: return "Joy-Con 2 (L)";
    case ControllerKind::JoyConRight: return "Joy-Con 2 (R)";
    case ControllerKind::ProController: return "Pro Controller 2";
  }
  return "Switch 2 controller";
}

uint16_t KindProductID(ControllerKind kind) {
  switch (kind) {
    case ControllerKind::JoyConLeft: return kProductJoyCon2Left;
    case ControllerKind::JoyConRight: return kProductJoyCon2Right;
    case ControllerKind::ProController: return kProductProController2;
  }
  return 0;
}

bool KindForProduct(uint16_t product, ControllerKind *kind) {
  switch (product) {
    case kProductJoyCon2Left: *kind = ControllerKind::JoyConLeft; return true;
    case kProductJoyCon2Right: *kind = ControllerKind::JoyConRight; return true;
    case kProductProController2: *kind = ControllerKind::ProController; return true;
    default: return false;
  }
}

NSData *MakeCommand(uint8_t command, uint8_t subcommand, const uint8_t *data,
                    size_t length) {
  const uint8_t header[] = {command, 0x91, 0x01, subcommand, 0x00,
                            static_cast<uint8_t>(length), 0x00, 0x00};
  NSMutableData *buffer = [NSMutableData dataWithBytes:header length:sizeof(header)];
  if (length > 0) [buffer appendBytes:data length:length];
  return buffer;
}

NSData *MakeMemoryRead(uint8_t length, uint32_t address) {
  const uint8_t data[] = {length, 0x7E, 0x00, 0x00,
                          static_cast<uint8_t>(address & 0xFF),
                          static_cast<uint8_t>((address >> 8) & 0xFF),
                          static_cast<uint8_t>((address >> 16) & 0xFF),
                          static_cast<uint8_t>((address >> 24) & 0xFF)};
  return MakeCommand(kCmdMemory, kSubMemoryRead, data, sizeof(data));
}

NSData *MakeSetPlayerLeds(int playerNumber) {
  const int index = std::clamp(playerNumber, 1, static_cast<int>(kPlayerLedPatterns.size())) - 1;
  const uint8_t data[] = {kPlayerLedPatterns[static_cast<size_t>(index)], 0x00, 0x00, 0x00};
  return MakeCommand(kCmdLeds, kSubLedsSetPlayer, data, sizeof(data));
}

// Vibration -----------------------------------------------------------------

// SDL rumble strength (0..65535) to the controller's 10-bit motor amplitude.
// Zero stays zero; anything else lands in a conservative 64..768 band.
uint16_t RumbleAmplitude(uint16_t strength) {
  if (strength == 0) return 0;
  return static_cast<uint16_t>(64 + (static_cast<uint32_t>(strength) * 704u) / 65535u);
}

// One 40-bit motor block: low-frequency (9-bit freq, tone bit, 10-bit amp)
// then high-frequency (9-bit freq, tone bit, 10-bit amp), little-endian.
void AppendMotorBlock(NSMutableData *data, uint16_t lowAmplitude, uint16_t highAmplitude) {
  constexpr uint64_t kLowFrequency = 0x0E1;
  constexpr uint64_t kHighFrequency = 0x1E1;
  const uint64_t packed = (kLowFrequency & 0x1FF) |
                          ((static_cast<uint64_t>(lowAmplitude) & 0x3FF) << 10) |
                          ((kHighFrequency & 0x1FF) << 20) |
                          ((static_cast<uint64_t>(highAmplitude) & 0x3FF) << 30);
  uint8_t bytes[5];
  for (size_t index = 0; index < sizeof(bytes); ++index) {
    bytes[index] = static_cast<uint8_t>((packed >> (8 * index)) & 0xFF);
  }
  [data appendBytes:bytes length:sizeof(bytes)];
}

// Vibration write: 0x00, then per motor a 0x5N sequence byte followed by three
// motor blocks (the current sample plus two silent ones). Pro Controller 2
// carries two motors, Joy-Con 2 one.
NSData *MakeVibrationPacket(ControllerKind kind, uint8_t sequence,
                            uint16_t lowAmplitude, uint16_t highAmplitude) {
  NSMutableData *data = [NSMutableData dataWithCapacity:33];
  const uint8_t prefix = 0x00;
  [data appendBytes:&prefix length:1];
  const int motors = kind == ControllerKind::ProController ? 2 : 1;
  for (int motor = 0; motor < motors; ++motor) {
    const uint8_t header = static_cast<uint8_t>(0x50 | (sequence & 0x0F));
    [data appendBytes:&header length:1];
    AppendMotorBlock(data, lowAmplitude, highAmplitude);
    AppendMotorBlock(data, 0, 0);
    AppendMotorBlock(data, 0, 0);
  }
  return data;
}

NSString *VibrationUUIDForKind(ControllerKind kind) {
  switch (kind) {
    case ControllerKind::JoyConLeft: return kVibrationLeftUUID;
    case ControllerKind::JoyConRight: return kVibrationRightUUID;
    case ControllerKind::ProController: return kVibrationProUUID;
  }
  return kVibrationLeftUUID;
}

// Returns the memory payload of a read response, or nil if it does not match.
NSData *MemoryReadPayload(NSData *response, uint8_t length, uint32_t address) {
  if (response == nil || response.length < 16 + length) return nil;
  const uint8_t *bytes = static_cast<const uint8_t *>(response.bytes);
  if (bytes[0] != kCmdMemory || bytes[1] != 0x01) return nil;
  const uint8_t *payload = bytes + 8;
  if (payload[0] != length || ReadU32(payload + 4) != address) return nil;
  return [NSData dataWithBytes:payload + 8 length:length];
}

bool ParseCalibration(NSData *payload, StickCalibration *calibration) {
  if (payload == nil || payload.length < 9) return false;
  const uint8_t *bytes = static_cast<const uint8_t *>(payload.bytes);
  if (bytes[0] == 0xFF && bytes[1] == 0xFF && bytes[2] == 0xFF) return false;
  const StickRaw center = ReadStick(bytes);
  const StickRaw max = ReadStick(bytes + 3);
  const StickRaw min = ReadStick(bytes + 6);
  if (center.x < 512 || center.x > 3584 || center.y < 512 || center.y > 3584) return false;
  if (max.x < 200 || max.y < 200 || min.x < 200 || min.y < 200) return false;
  calibration->centerX = center.x;
  calibration->centerY = center.y;
  calibration->maxX = max.x;
  calibration->maxY = max.y;
  calibration->minX = min.x;
  calibration->minY = min.y;
  calibration->valid = true;
  return true;
}

float CalibrateAxis(int raw, int center, int maxExcursion, int minExcursion) {
  constexpr int kDeadzone = 160;  // ~8% of a 2048 half-range
  const int value = raw - center;
  if (value > kDeadzone) {
    return std::min(static_cast<float>(value) / static_cast<float>(maxExcursion), 1.0f);
  }
  if (value < -kDeadzone) {
    return -std::min(static_cast<float>(-value) / static_cast<float>(minExcursion), 1.0f);
  }
  return 0.0f;
}

bool UpdateAutoCalibration(AutoCalibration &calibration, int rawX, int rawY) {
  const bool neutral = rawX >= 1500 && rawX <= 2600 && rawY >= 1500 && rawY <= 2600;
  const bool stable = neutral && (calibration.lastX == INT_MIN ||
                                  (std::abs(rawX - calibration.lastX) <= 4 &&
                                   std::abs(rawY - calibration.lastY) <= 4));
  calibration.lastX = rawX;
  calibration.lastY = rawY;
  if (!stable) {
    calibration.stableSamples = 0;
    calibration.sumX = 0;
    calibration.sumY = 0;
    return calibration.calibrated;
  }
  calibration.stableSamples++;
  calibration.sumX += rawX;
  calibration.sumY += rawY;
  if (calibration.stableSamples >= 30) {
    calibration.centerX = static_cast<int>(calibration.sumX / calibration.stableSamples);
    calibration.centerY = static_cast<int>(calibration.sumY / calibration.stableSamples);
    calibration.calibrated = true;
    calibration.stableSamples = 0;
    calibration.sumX = 0;
    calibration.sumY = 0;
  }
  return calibration.calibrated;
}

// Normalized stick in [-1, 1], X right and Y up, before any rotation.
void NormalizeStick(const StickRaw &raw, const StickCalibration &calibration,
                    AutoCalibration &fallback, float *x, float *y) {
  if (calibration.valid) {
    *x = CalibrateAxis(raw.x, calibration.centerX, calibration.maxX, calibration.minX);
    *y = CalibrateAxis(raw.y, calibration.centerY, calibration.maxY, calibration.minY);
    return;
  }
  if (!UpdateAutoCalibration(fallback, raw.x, raw.y)) {
    *x = 0.0f;
    *y = 0.0f;
    return;
  }
  float nx = static_cast<float>(raw.x - fallback.centerX) / 2048.0f;
  float ny = static_cast<float>(raw.y - fallback.centerY) / 2048.0f;
  if (std::fabs(nx) < 0.08f && std::fabs(ny) < 0.08f) {
    nx = 0.0f;
    ny = 0.0f;
  }
  *x = std::clamp(nx * 1.7f, -1.0f, 1.0f);
  *y = std::clamp(ny * 1.7f, -1.0f, 1.0f);
}

Sint16 AxisValue(float value) {
  return static_cast<Sint16>(std::lround(std::clamp(value, -1.0f, 1.0f) * 32767.0f));
}

void SetButton(GamepadState &state, SDL_GamepadButton button, bool pressed) {
  state.buttons[static_cast<size_t>(button)] = pressed;
}

// Sideways Joy-Con layout, matching the geometry Nintendo uses when one
// Joy-Con is held with SL/SR at the top:
//   Right Joy-Con rotates clockwise:  A=south X=east B=west Y=north
//   Left Joy-Con rotates anticlockwise: Left=south Down=east Up=west Right=north
// SL/SR become the shoulders, the rail bumper (L or R) is D-pad Up so Mario
// Kart Wii has a trick button, and the rail trigger (ZL or ZR) is the right
// trigger.
GamepadState TranslateReport(ControllerKind kind, uint32_t buttons,
                             float leftX, float leftY, float rightX, float rightY) {
  GamepadState state;
  switch (kind) {
    case ControllerKind::JoyConRight: {
      SetButton(state, SDL_GAMEPAD_BUTTON_SOUTH, buttons & kBtnA);
      SetButton(state, SDL_GAMEPAD_BUTTON_EAST, buttons & kBtnX);
      SetButton(state, SDL_GAMEPAD_BUTTON_WEST, buttons & kBtnB);
      SetButton(state, SDL_GAMEPAD_BUTTON_NORTH, buttons & kBtnY);
      SetButton(state, SDL_GAMEPAD_BUTTON_LEFT_SHOULDER, buttons & kBtnSLRight);
      SetButton(state, SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER, buttons & kBtnSRRight);
      SetButton(state, SDL_GAMEPAD_BUTTON_START, buttons & kBtnPlus);
      SetButton(state, SDL_GAMEPAD_BUTTON_BACK, buttons & kBtnC);
      SetButton(state, SDL_GAMEPAD_BUTTON_GUIDE, buttons & kBtnHome);
      SetButton(state, SDL_GAMEPAD_BUTTON_LEFT_STICK, buttons & kBtnRightStick);
      SetButton(state, SDL_GAMEPAD_BUTTON_DPAD_UP, buttons & kBtnR);
      state.axes[SDL_GAMEPAD_AXIS_RIGHT_TRIGGER] = (buttons & kBtnZR) ? 32767 : 0;
      // Clockwise rotation: (x, y) -> (y, -x); SDL Y is down-positive.
      state.axes[SDL_GAMEPAD_AXIS_LEFTX] = AxisValue(rightY);
      state.axes[SDL_GAMEPAD_AXIS_LEFTY] = AxisValue(rightX);
      break;
    }
    case ControllerKind::JoyConLeft: {
      SetButton(state, SDL_GAMEPAD_BUTTON_SOUTH, buttons & kBtnLeft);
      SetButton(state, SDL_GAMEPAD_BUTTON_EAST, buttons & kBtnDown);
      SetButton(state, SDL_GAMEPAD_BUTTON_WEST, buttons & kBtnUp);
      SetButton(state, SDL_GAMEPAD_BUTTON_NORTH, buttons & kBtnRight);
      SetButton(state, SDL_GAMEPAD_BUTTON_LEFT_SHOULDER, buttons & kBtnSLLeft);
      SetButton(state, SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER, buttons & kBtnSRLeft);
      SetButton(state, SDL_GAMEPAD_BUTTON_START, buttons & kBtnCapture);
      SetButton(state, SDL_GAMEPAD_BUTTON_BACK, buttons & kBtnMinus);
      SetButton(state, SDL_GAMEPAD_BUTTON_LEFT_STICK, buttons & kBtnLeftStick);
      SetButton(state, SDL_GAMEPAD_BUTTON_DPAD_UP, buttons & kBtnL);
      state.axes[SDL_GAMEPAD_AXIS_RIGHT_TRIGGER] = (buttons & kBtnZL) ? 32767 : 0;
      // Anticlockwise rotation: (x, y) -> (-y, x); SDL Y is down-positive.
      state.axes[SDL_GAMEPAD_AXIS_LEFTX] = AxisValue(-leftY);
      state.axes[SDL_GAMEPAD_AXIS_LEFTY] = AxisValue(-leftX);
      break;
    }
    case ControllerKind::ProController: {
      SetButton(state, SDL_GAMEPAD_BUTTON_SOUTH, buttons & kBtnB);
      SetButton(state, SDL_GAMEPAD_BUTTON_EAST, buttons & kBtnA);
      SetButton(state, SDL_GAMEPAD_BUTTON_WEST, buttons & kBtnY);
      SetButton(state, SDL_GAMEPAD_BUTTON_NORTH, buttons & kBtnX);
      SetButton(state, SDL_GAMEPAD_BUTTON_LEFT_SHOULDER, buttons & kBtnL);
      SetButton(state, SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER, buttons & kBtnR);
      SetButton(state, SDL_GAMEPAD_BUTTON_START, buttons & kBtnPlus);
      SetButton(state, SDL_GAMEPAD_BUTTON_BACK, buttons & kBtnMinus);
      SetButton(state, SDL_GAMEPAD_BUTTON_GUIDE, buttons & kBtnHome);
      SetButton(state, SDL_GAMEPAD_BUTTON_MISC1, buttons & kBtnCapture);
      SetButton(state, SDL_GAMEPAD_BUTTON_LEFT_STICK, buttons & kBtnLeftStick);
      SetButton(state, SDL_GAMEPAD_BUTTON_RIGHT_STICK, buttons & kBtnRightStick);
      SetButton(state, SDL_GAMEPAD_BUTTON_DPAD_UP, buttons & kBtnUp);
      SetButton(state, SDL_GAMEPAD_BUTTON_DPAD_DOWN, buttons & kBtnDown);
      SetButton(state, SDL_GAMEPAD_BUTTON_DPAD_LEFT, buttons & kBtnLeft);
      SetButton(state, SDL_GAMEPAD_BUTTON_DPAD_RIGHT, buttons & kBtnRight);
      state.axes[SDL_GAMEPAD_AXIS_LEFT_TRIGGER] = (buttons & kBtnZL) ? 32767 : 0;
      state.axes[SDL_GAMEPAD_AXIS_RIGHT_TRIGGER] = (buttons & kBtnZR) ? 32767 : 0;
      state.axes[SDL_GAMEPAD_AXIS_LEFTX] = AxisValue(leftX);
      state.axes[SDL_GAMEPAD_AXIS_LEFTY] = AxisValue(-leftY);
      state.axes[SDL_GAMEPAD_AXIS_RIGHTX] = AxisValue(rightX);
      state.axes[SDL_GAMEPAD_AXIS_RIGHTY] = AxisValue(-rightY);
      break;
    }
  }
  return state;
}

bool LocalBluetoothAddress(std::array<uint8_t, 6> *address) {
  IOBluetoothHostController *controller = IOBluetoothHostController.defaultController;
  NSString *text = controller.addressAsString;
  if (text.length == 0) return false;
  NSString *normalized = [[text stringByReplacingOccurrencesOfString:@"-" withString:@""]
      stringByReplacingOccurrencesOfString:@":" withString:@""];
  if (normalized.length != 12) return false;
  for (int index = 0; index < 6; ++index) {
    NSString *component = [normalized substringWithRange:NSMakeRange(index * 2, 2)];
    unsigned int value = 0;
    if (![[NSScanner scannerWithString:component] scanHexInt:&value]) return false;
    (*address)[static_cast<size_t>(index)] = static_cast<uint8_t>(value);
  }
  return true;
}

NSString *HexString(NSData *data, NSUInteger maxBytes) {
  const uint8_t *bytes = static_cast<const uint8_t *>(data.bytes);
  NSMutableString *text = [NSMutableString string];
  for (NSUInteger index = 0; index < data.length && index < maxBytes; ++index) {
    [text appendFormat:index == 0 ? @"%02X" : @" %02X", bytes[index]];
  }
  return text;
}

void Log(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);
void Log(NSString *format, ...) {
  va_list args;
  va_start(args, format);
  NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);
  NSLog(@"[KartPad] Joy-Con 2: %@", message);
}

}  // namespace

#pragma mark - Device

typedef void (^KartPadJoyCon2ResponseBlock)(NSData *_Nullable response);

@interface KartPadJoyCon2Device : NSObject
@property(nonatomic, strong) CBPeripheral *peripheral;
@property(nonatomic, assign) ControllerKind kind;
@property(nonatomic, assign) BOOL pairingMode;
@property(nonatomic, strong) CBCharacteristic *inputCharacteristic;
@property(nonatomic, strong) CBCharacteristic *commandCharacteristic;
@property(nonatomic, strong) CBCharacteristic *responseCharacteristic;
@property(nonatomic, strong) CBCharacteristic *vibrationCharacteristic;
@property(nonatomic, copy) NSString *status;
@property(nonatomic, assign) BOOL ready;
@property(nonatomic, assign) int playerNumber;
@property(nonatomic, assign) SDL_JoystickID joystickID;
@property(nonatomic, assign) SDL_Joystick *joystick;
@property(nonatomic, assign) NSUInteger packetCount;
@property(nonatomic, readonly) NSString *displayName;
@property(nonatomic, readonly) BOOL hasRequiredCharacteristics;
- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral kind:(ControllerKind)kind;
- (void)enqueueCommand:(NSData *)command label:(NSString *)label
            completion:(KartPadJoyCon2ResponseBlock _Nullable)completion;
- (void)handleResponse:(NSData *)response;
- (void)handleInputReport:(NSData *)report;
- (void)readCalibrationForStick:(int)stick completion:(dispatch_block_t)completion;
- (BOOL)attachToSDL;
- (void)detachFromSDL;
- (void)cancelPendingCommands;
- (void)applyPlayerNumber:(int)playerNumber;
- (void)setRumbleLow:(uint16_t)low high:(uint16_t)high;
- (void)stopRumble;
@end

@implementation KartPadJoyCon2Device {
  NSMutableArray<NSData *> *_commandQueue;
  NSMutableArray<NSString *> *_commandLabels;
  NSMutableArray<KartPadJoyCon2ResponseBlock> *_commandCompletions;
  BOOL _commandInFlight;
  uint8_t _currentCommandID;
  KartPadJoyCon2ResponseBlock _currentCompletion;
  NSTimer *_responseTimer;
  StickCalibration _stick1;
  StickCalibration _stick2;
  AutoCalibration _auto1;
  AutoCalibration _auto2;
  GamepadState _lastState;
  uint16_t _rumbleLow;
  uint16_t _rumbleHigh;
  uint8_t _rumbleSequence;
  NSTimer *_rumbleTimer;
}

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral kind:(ControllerKind)kind {
  self = [super init];
  if (self != nil) {
    _peripheral = peripheral;
    _kind = kind;
    _status = @"Connecting…";
    _playerNumber = 0;
    _commandQueue = [NSMutableArray array];
    _commandLabels = [NSMutableArray array];
    _commandCompletions = [NSMutableArray array];
  }
  return self;
}

- (NSString *)displayName {
  return [NSString stringWithUTF8String:KindName(_kind)];
}

- (BOOL)hasRequiredCharacteristics {
  return _inputCharacteristic != nil && _commandCharacteristic != nil &&
         _responseCharacteristic != nil;
}

#pragma mark Commands

- (void)enqueueCommand:(NSData *)command label:(NSString *)label
            completion:(KartPadJoyCon2ResponseBlock _Nullable)completion {
  [_commandQueue addObject:command];
  [_commandLabels addObject:label ?: @"command"];
  [_commandCompletions addObject:completion ?: ^(NSData *_Nullable response) { (void)response; }];
  [self sendNextCommand];
}

- (void)sendNextCommand {
  if (_commandInFlight || _commandQueue.count == 0) return;
  if (_commandCharacteristic == nil || _peripheral.state != CBPeripheralStateConnected) {
    [self cancelPendingCommands];
    return;
  }
  NSData *command = _commandQueue.firstObject;
  NSString *label = _commandLabels.firstObject;
  KartPadJoyCon2ResponseBlock completion = _commandCompletions.firstObject;
  [_commandQueue removeObjectAtIndex:0];
  [_commandLabels removeObjectAtIndex:0];
  [_commandCompletions removeObjectAtIndex:0];

  _commandInFlight = YES;
  _currentCommandID = static_cast<const uint8_t *>(command.bytes)[0];
  _currentCompletion = completion;

  CBCharacteristicWriteType writeType = CBCharacteristicWriteWithResponse;
  if (!(_commandCharacteristic.properties & CBCharacteristicPropertyWrite) &&
      (_commandCharacteristic.properties & CBCharacteristicPropertyWriteWithoutResponse)) {
    writeType = CBCharacteristicWriteWithoutResponse;
  }
  Log(@"%@ %@: %@", self.displayName, label, HexString(command, 24));
  [_peripheral writeValue:command forCharacteristic:_commandCharacteristic type:writeType];

  __weak KartPadJoyCon2Device *weakSelf = self;
  _responseTimer = [NSTimer scheduledTimerWithTimeInterval:kCommandTimeout
                                                   repeats:NO
                                                     block:^(NSTimer *timer) {
    (void)timer;
    KartPadJoyCon2Device *strongSelf = weakSelf;
    if (strongSelf == nil) return;
    Log(@"%@ %@: no response, continuing", strongSelf.displayName, label);
    [strongSelf finishCommandWithResponse:nil];
  }];
}

- (void)finishCommandWithResponse:(NSData *_Nullable)response {
  [_responseTimer invalidate];
  _responseTimer = nil;
  KartPadJoyCon2ResponseBlock completion = _currentCompletion;
  _currentCompletion = nil;
  _commandInFlight = NO;
  if (completion != nil) completion(response);
  [self sendNextCommand];
}

- (void)handleResponse:(NSData *)response {
  if (!_commandInFlight || response.length == 0) return;
  const uint8_t *bytes = static_cast<const uint8_t *>(response.bytes);
  if (bytes[0] != _currentCommandID) {
    Log(@"%@ ignoring response for command %02X while waiting for %02X",
        self.displayName, bytes[0], _currentCommandID);
    return;
  }
  [self finishCommandWithResponse:response];
}

- (void)cancelPendingCommands {
  [_responseTimer invalidate];
  _responseTimer = nil;
  _commandInFlight = NO;
  _currentCompletion = nil;
  [_commandQueue removeAllObjects];
  [_commandLabels removeAllObjects];
  [_commandCompletions removeAllObjects];
}

- (void)applyPlayerNumber:(int)playerNumber {
  if (playerNumber < 1) return;
  _playerNumber = playerNumber;
  if (_joystick != nullptr) {
    _status = [NSString stringWithFormat:@"Connected as Player %d", playerNumber];
  }
  [self enqueueCommand:MakeSetPlayerLeds(playerNumber)
                 label:[NSString stringWithFormat:@"set player %d LEDs", playerNumber]
            completion:nil];
}

#pragma mark Rumble

- (void)writeRumblePacket {
  if (_vibrationCharacteristic == nil || _peripheral.state != CBPeripheralStateConnected) return;
  NSData *packet = MakeVibrationPacket(_kind, _rumbleSequence++,
                                       RumbleAmplitude(_rumbleLow), RumbleAmplitude(_rumbleHigh));
  CBCharacteristicWriteType writeType = CBCharacteristicWriteWithoutResponse;
  if (!(_vibrationCharacteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) &&
      (_vibrationCharacteristic.properties & CBCharacteristicPropertyWrite)) {
    writeType = CBCharacteristicWriteWithResponse;
  }
  [_peripheral writeValue:packet forCharacteristic:_vibrationCharacteristic type:writeType];
}

- (void)setRumbleLow:(uint16_t)low high:(uint16_t)high {
  if (_vibrationCharacteristic == nil) return;
  const BOOL wasActive = _rumbleLow != 0 || _rumbleHigh != 0;
  _rumbleLow = low;
  _rumbleHigh = high;
  const BOOL active = low != 0 || high != 0;
  if (!active) {
    [_rumbleTimer invalidate];
    _rumbleTimer = nil;
    if (wasActive) [self writeRumblePacket];  // one explicit stop sample
    return;
  }
  [self writeRumblePacket];
  if (_rumbleTimer == nil) {
    __weak KartPadJoyCon2Device *weakSelf = self;
    _rumbleTimer = [NSTimer scheduledTimerWithTimeInterval:kRumbleRefreshInterval
                                                   repeats:YES
                                                     block:^(NSTimer *timer) {
      KartPadJoyCon2Device *strongSelf = weakSelf;
      if (strongSelf == nil) {
        [timer invalidate];
        return;
      }
      [strongSelf writeRumblePacket];
    }];
  }
}

- (void)stopRumble {
  [self setRumbleLow:0 high:0];
}

#pragma mark Calibration

- (void)readCalibrationForStick:(int)stick completion:(dispatch_block_t)completion {
  const uint32_t userAddress = stick == 1 ? kAddrUserCalibrationStick1 : kAddrUserCalibrationStick2;
  const uint32_t factoryAddress = stick == 1 ? kAddrFactoryCalibrationStick1 : kAddrFactoryCalibrationStick2;
  StickCalibration *target = stick == 1 ? &_stick1 : &_stick2;
  __weak KartPadJoyCon2Device *weakSelf = self;
  [self enqueueCommand:MakeMemoryRead(kCalibrationLength, userAddress)
                 label:[NSString stringWithFormat:@"read user stick %d calibration", stick]
            completion:^(NSData *_Nullable response) {
    KartPadJoyCon2Device *strongSelf = weakSelf;
    if (strongSelf == nil) return;
    if (ParseCalibration(MemoryReadPayload(response, kCalibrationLength, userAddress), target)) {
      Log(@"%@ using user stick %d calibration", strongSelf.displayName, stick);
      completion();
      return;
    }
    [strongSelf enqueueCommand:MakeMemoryRead(kCalibrationLength, factoryAddress)
                         label:[NSString stringWithFormat:@"read factory stick %d calibration", stick]
                    completion:^(NSData *_Nullable factoryResponse) {
      KartPadJoyCon2Device *innerSelf = weakSelf;
      if (innerSelf == nil) return;
      if (ParseCalibration(MemoryReadPayload(factoryResponse, kCalibrationLength, factoryAddress), target)) {
        Log(@"%@ using factory stick %d calibration", innerSelf.displayName, stick);
      } else {
        Log(@"%@ stick %d calibration unavailable; using automatic centering",
            innerSelf.displayName, stick);
      }
      completion();
    }];
  }];
}

#pragma mark Input

- (void)handleInputReport:(NSData *)report {
  if (report.length < kReportMinimumLength || _joystick == nullptr) return;
  const uint8_t *bytes = static_cast<const uint8_t *>(report.bytes);
  const uint32_t buttons = ReadU32(bytes + kReportButtonsOffset);
  float leftX = 0.0f, leftY = 0.0f, rightX = 0.0f, rightY = 0.0f;
  if (_kind != ControllerKind::JoyConRight) {
    NormalizeStick(ReadStick(bytes + kReportLeftStickOffset), _stick1, _auto1, &leftX, &leftY);
  }
  if (_kind == ControllerKind::JoyConRight) {
    // A single Joy-Con stores its stick calibration in the first slot.
    NormalizeStick(ReadStick(bytes + kReportRightStickOffset), _stick1, _auto1, &rightX, &rightY);
  } else if (_kind == ControllerKind::ProController) {
    NormalizeStick(ReadStick(bytes + kReportRightStickOffset), _stick2, _auto2, &rightX, &rightY);
  }
  const GamepadState state = TranslateReport(_kind, buttons, leftX, leftY, rightX, rightY);
  for (int index = 0; index < kVirtualButtonCount; ++index) {
    const size_t slot = static_cast<size_t>(index);
    if (state.buttons[slot] != _lastState.buttons[slot]) {
      SDL_SetJoystickVirtualButton(_joystick, index, state.buttons[slot]);
    }
  }
  for (int index = 0; index < kVirtualAxisCount; ++index) {
    const size_t slot = static_cast<size_t>(index);
    if (state.axes[slot] != _lastState.axes[slot]) {
      SDL_SetJoystickVirtualAxis(_joystick, index, state.axes[slot]);
    }
  }
  _lastState = state;
  _packetCount += 1;
  if (_packetCount == 1) {
    Log(@"%@ first input report (%lu bytes): %@", self.displayName,
        (unsigned long)report.length, HexString(report, 16));
  }
}

#pragma mark SDL

static void SDLCALL KartPadJoyCon2SetPlayerIndex(void *userdata, int playerIndex) {
  KartPadJoyCon2Device *device = (__bridge KartPadJoyCon2Device *)userdata;
  if (device == nil || playerIndex < 0) return;
  dispatch_async(dispatch_get_main_queue(), ^{
    [device applyPlayerNumber:playerIndex + 1];
  });
}

static bool SDLCALL KartPadJoyCon2Rumble(void *userdata, Uint16 lowFrequency, Uint16 highFrequency) {
  KartPadJoyCon2Device *device = (__bridge KartPadJoyCon2Device *)userdata;
  if (device == nil) return false;
  // Called from SDL's joystick lock; the BLE write happens on the main queue.
  dispatch_async(dispatch_get_main_queue(), ^{
    [device setRumbleLow:lowFrequency high:highFrequency];
  });
  return true;
}

static void SDLCALL KartPadJoyCon2Cleanup(void *userdata) {
  if (userdata != nullptr) CFBridgingRelease(userdata);
}

- (BOOL)attachToSDL {
  if (_joystick != nullptr) return YES;
  if (!SDL_WasInit(SDL_INIT_JOYSTICK)) return NO;

  SDL_VirtualJoystickDesc desc;
  SDL_INIT_INTERFACE(&desc);
  desc.type = SDL_JOYSTICK_TYPE_GAMEPAD;
  desc.vendor_id = kNintendoVendorID;
  desc.product_id = KindProductID(_kind);
  desc.naxes = static_cast<Uint16>(kVirtualAxisCount);
  desc.nbuttons = static_cast<Uint16>(kVirtualButtonCount);
  desc.button_mask = (1u << kVirtualButtonCount) - 1u;
  desc.name = KindName(_kind);
  desc.userdata = const_cast<void *>(CFBridgingRetain(self));
  desc.SetPlayerIndex = KartPadJoyCon2SetPlayerIndex;
  if (_vibrationCharacteristic != nil) desc.Rumble = KartPadJoyCon2Rumble;
  desc.Cleanup = KartPadJoyCon2Cleanup;

  const SDL_JoystickID joystickID = SDL_AttachVirtualJoystick(&desc);
  if (joystickID == 0) {
    Log(@"%@ SDL_AttachVirtualJoystick failed: %s", self.displayName, SDL_GetError());
    CFBridgingRelease(desc.userdata);
    return NO;
  }
  SDL_Joystick *joystick = SDL_OpenJoystick(joystickID);
  if (joystick == nullptr) {
    Log(@"%@ SDL_OpenJoystick failed: %s", self.displayName, SDL_GetError());
    SDL_DetachVirtualJoystick(joystickID);
    return NO;
  }
  _joystickID = joystickID;
  _joystick = joystick;
  _lastState = GamepadState{};
  Log(@"%@ attached as SDL virtual gamepad %u", self.displayName, joystickID);
  return YES;
}

- (void)detachFromSDL {
  [_rumbleTimer invalidate];
  _rumbleTimer = nil;
  if ((_rumbleLow != 0 || _rumbleHigh != 0) && _peripheral.state == CBPeripheralStateConnected) {
    _rumbleLow = 0;
    _rumbleHigh = 0;
    [self writeRumblePacket];
  }
  _rumbleLow = 0;
  _rumbleHigh = 0;
  if (_joystick != nullptr) {
    SDL_CloseJoystick(_joystick);
    _joystick = nullptr;
  }
  if (_joystickID != 0) {
    SDL_DetachVirtualJoystick(_joystickID);
    _joystickID = 0;
  }
}

@end

#pragma mark - Manager

@interface KartPadJoyCon2Manager : NSObject
    <CBCentralManagerDelegate, CBPeripheralDelegate, NSWindowDelegate>
+ (instancetype)sharedManager;
- (void)setEnabled:(BOOL)enabled;
- (void)showPanel;
@end

@implementation KartPadJoyCon2Manager {
  CBCentralManager *_central;
  NSMutableDictionary<NSUUID *, KartPadJoyCon2Device *> *_devices;
  NSMutableDictionary<NSUUID *, NSDate *> *_lastAttempt;
  NSMutableSet<NSUUID *> *_reportedForeignHosts;
  BOOL _enabled;
  BOOL _scanning;
  NSPanel *_panel;
  NSTextField *_statusField;
  NSTextField *_headline;
  NSTimer *_attachTimer;
}

+ (instancetype)sharedManager {
  static KartPadJoyCon2Manager *manager;
  static dispatch_once_t once;
  dispatch_once(&once, ^{ manager = [KartPadJoyCon2Manager new]; });
  return manager;
}

- (instancetype)init {
  self = [super init];
  if (self != nil) {
    _devices = [NSMutableDictionary dictionary];
    _lastAttempt = [NSMutableDictionary dictionary];
    _reportedForeignHosts = [NSMutableSet set];
  }
  return self;
}

#pragma mark Enable / scan

- (void)setEnabled:(BOOL)enabled {
  if (_enabled == enabled) {
    if (enabled) [self startScanningIfPossible];
    return;
  }
  _enabled = enabled;
  if (enabled) {
    if (_central == nil) {
      _central = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    [self startScanningIfPossible];
  } else {
    [self stopScanning];
    for (KartPadJoyCon2Device *device in _devices.allValues) {
      [device cancelPendingCommands];
      [device detachFromSDL];
      [_central cancelPeripheralConnection:device.peripheral];
    }
    [_devices removeAllObjects];
  }
  [self refreshPanel];
}

- (NSUInteger)activeDeviceCount {
  return _devices.count;
}

- (void)startScanningIfPossible {
  if (!_enabled || _central == nil || _central.state != CBManagerStatePoweredOn) return;
  if (_scanning || [self activeDeviceCount] >= kMaxControllers) return;
  [_central scanForPeripheralsWithServices:nil
                                   options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
  _scanning = YES;
  Log(@"scanning for Switch 2 controllers");
  [self refreshPanel];
}

- (void)stopScanning {
  if (_scanning && _central != nil) [_central stopScan];
  _scanning = NO;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
  (void)central;
  switch (_central.state) {
    case CBManagerStatePoweredOn:
      [self startScanningIfPossible];
      break;
    case CBManagerStateUnauthorized:
      Log(@"Bluetooth access is not authorized for KartPad");
      _scanning = NO;
      break;
    default:
      _scanning = NO;
      break;
  }
  [self refreshPanel];
}

- (BOOL)parseAdvertisement:(NSDictionary<NSString *, id> *)advertisement
                      kind:(ControllerKind *)kind
               pairingMode:(BOOL *)pairingMode
             pairedToOther:(BOOL *)pairedToOther {
  NSData *manufacturer = advertisement[CBAdvertisementDataManufacturerDataKey];
  if (manufacturer.length < kAdvMinimumLength) return NO;
  const uint8_t *bytes = static_cast<const uint8_t *>(manufacturer.bytes);
  if (ReadU16(bytes) != kNintendoCompanyID) return NO;
  if (ReadU16(bytes + kAdvVendorOffset) != kNintendoVendorID) return NO;
  if (!KindForProduct(ReadU16(bytes + kAdvProductOffset), kind)) return NO;

  const uint8_t *reconnect = bytes + kAdvReconnectOffset;
  bool zero = true;
  for (int index = 0; index < 6; ++index) zero = zero && reconnect[index] == 0;
  *pairingMode = zero;
  *pairedToOther = NO;
  if (!zero) {
    std::array<uint8_t, 6> local{};
    if (LocalBluetoothAddress(&local)) {
      bool matches = true;
      for (int index = 0; index < 6; ++index) {
        matches = matches && reconnect[index] == local[static_cast<size_t>(5 - index)];
      }
      *pairedToOther = !matches;
    }
  }
  return YES;
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *, id> *)advertisementData
                  RSSI:(NSNumber *)RSSI {
  (void)central;
  if (_devices[peripheral.identifier] != nil) return;
  ControllerKind kind = ControllerKind::JoyConLeft;
  BOOL pairingMode = NO;
  BOOL pairedToOther = NO;
  if (![self parseAdvertisement:advertisementData kind:&kind
                    pairingMode:&pairingMode pairedToOther:&pairedToOther]) {
    return;
  }
  if (pairedToOther) {
    if (![_reportedForeignHosts containsObject:peripheral.identifier]) {
      [_reportedForeignHosts addObject:peripheral.identifier];
      Log(@"%s is paired to another host; hold SYNC to pair it with this Mac",
          KindName(kind));
      [self refreshPanel];
    }
    return;
  }
  if ([self activeDeviceCount] >= kMaxControllers) return;
  NSDate *lastAttempt = _lastAttempt[peripheral.identifier];
  if (lastAttempt != nil && -lastAttempt.timeIntervalSinceNow < kConnectCooldown) return;
  _lastAttempt[peripheral.identifier] = NSDate.date;
  [_reportedForeignHosts removeObject:peripheral.identifier];

  KartPadJoyCon2Device *device = [[KartPadJoyCon2Device alloc] initWithPeripheral:peripheral
                                                                             kind:kind];
  device.pairingMode = pairingMode;
  _devices[peripheral.identifier] = device;
  peripheral.delegate = self;
  Log(@"connecting to %s (%@, RSSI %@)", KindName(kind),
      pairingMode ? @"pairing mode" : @"already paired", RSSI);
  [_central connectPeripheral:peripheral options:nil];
  if ([self activeDeviceCount] >= kMaxControllers) [self stopScanning];
  [self refreshPanel];
}

#pragma mark Connection lifecycle

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
  (void)central;
  KartPadJoyCon2Device *device = _devices[peripheral.identifier];
  if (device == nil) {
    [_central cancelPeripheralConnection:peripheral];
    return;
  }
  device.status = @"Discovering services…";
  [peripheral discoverServices:nil];
  [self refreshPanel];
}

- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
  (void)central;
  Log(@"connect failed: %@", error.localizedDescription ?: @"unknown error");
  [self forgetPeripheral:peripheral];
}

- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
  (void)central;
  KartPadJoyCon2Device *device = _devices[peripheral.identifier];
  Log(@"%s disconnected%@", device != nil ? KindName(device.kind) : "controller",
      error != nil ? [NSString stringWithFormat:@": %@", error.localizedDescription] : @"");
  [self forgetPeripheral:peripheral];
}

- (void)forgetPeripheral:(CBPeripheral *)peripheral {
  KartPadJoyCon2Device *device = _devices[peripheral.identifier];
  if (device != nil) {
    [device cancelPendingCommands];
    [device detachFromSDL];
    [_devices removeObjectForKey:peripheral.identifier];
  }
  [self refreshPanel];
  if (_enabled) {
    __weak KartPadJoyCon2Manager *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
      [weakSelf startScanningIfPossible];
    });
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
  KartPadJoyCon2Device *device = _devices[peripheral.identifier];
  if (device == nil) return;
  if (error != nil) {
    device.status = [NSString stringWithFormat:@"Service discovery failed: %@",
                     error.localizedDescription];
    [self refreshPanel];
    return;
  }
  for (CBService *service in peripheral.services) {
    [peripheral discoverCharacteristics:nil forService:service];
  }
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error {
  KartPadJoyCon2Device *device = _devices[peripheral.identifier];
  if (device == nil || error != nil) return;
  CBUUID *inputUUID = [CBUUID UUIDWithString:kInputUUID];
  CBUUID *commandUUID = [CBUUID UUIDWithString:kCommandUUID];
  CBUUID *responseUUID = [CBUUID UUIDWithString:kResponseUUID];
  CBUUID *vibrationUUID = [CBUUID UUIDWithString:VibrationUUIDForKind(device.kind)];
  for (CBCharacteristic *characteristic in service.characteristics) {
    if ([characteristic.UUID isEqual:inputUUID]) {
      device.inputCharacteristic = characteristic;
    } else if ([characteristic.UUID isEqual:commandUUID]) {
      device.commandCharacteristic = characteristic;
    } else if ([characteristic.UUID isEqual:responseUUID]) {
      device.responseCharacteristic = characteristic;
    } else if ([characteristic.UUID isEqual:vibrationUUID]) {
      device.vibrationCharacteristic = characteristic;
    }
  }
  if (device.vibrationCharacteristic == nil && device.hasRequiredCharacteristics && !device.ready) {
    Log(@"%@ vibration characteristic not found; rumble disabled", device.displayName);
  }
  if (!device.hasRequiredCharacteristics || device.ready) return;
  device.ready = YES;
  device.status = @"Reading calibration…";
  [self refreshPanel];
  [peripheral setNotifyValue:YES forCharacteristic:device.responseCharacteristic];
  [self runStartupForDevice:device];
}

- (void)runStartupForDevice:(KartPadJoyCon2Device *)device {
  __weak KartPadJoyCon2Manager *weakSelf = self;
  __weak KartPadJoyCon2Device *weakDevice = device;
  dispatch_block_t finish = ^{
    KartPadJoyCon2Manager *strongSelf = weakSelf;
    KartPadJoyCon2Device *strongDevice = weakDevice;
    if (strongSelf == nil || strongDevice == nil) return;
    [strongSelf finishStartupForDevice:strongDevice];
  };
  dispatch_block_t afterCalibration = ^{
    KartPadJoyCon2Manager *strongSelf = weakSelf;
    KartPadJoyCon2Device *strongDevice = weakDevice;
    if (strongSelf == nil || strongDevice == nil) return;
    [strongDevice applyPlayerNumber:[strongSelf provisionalPlayerNumberForDevice:strongDevice]];
    if (strongDevice.pairingMode &&
        [NSUserDefaults.standardUserDefaults boolForKey:KartPadJoyCon2RememberMacDefaultsKey]) {
      [strongSelf sendPairingCommandsToDevice:strongDevice];
    }
    // The command queue is strictly sequential, so this final LED write runs
    // after the pairing commands and marks the end of startup.
    [strongDevice enqueueCommand:MakeSetPlayerLeds(strongDevice.playerNumber)
                           label:@"confirm player LEDs"
                      completion:^(NSData *_Nullable response) {
      (void)response;
      finish();
    }];
  };
  if (device.kind == ControllerKind::ProController) {
    [device readCalibrationForStick:1 completion:^{
      KartPadJoyCon2Device *strongDevice = weakDevice;
      if (strongDevice == nil) return;
      [strongDevice readCalibrationForStick:2 completion:afterCalibration];
    }];
  } else {
    [device readCalibrationForStick:1 completion:afterCalibration];
  }
}

- (int)provisionalPlayerNumberForDevice:(KartPadJoyCon2Device *)device {
  NSMutableSet<NSNumber *> *taken = [NSMutableSet set];
  for (KartPadJoyCon2Device *other in _devices.allValues) {
    if (other != device && other.playerNumber > 0) [taken addObject:@(other.playerNumber)];
  }
  for (int number = 1; number <= static_cast<int>(kMaxControllers); ++number) {
    if (![taken containsObject:@(number)]) return number;
  }
  return static_cast<int>(kMaxControllers);
}

- (void)sendPairingCommandsToDevice:(KartPadJoyCon2Device *)device {
  std::array<uint8_t, 6> local{};
  if (!LocalBluetoothAddress(&local)) {
    Log(@"local Bluetooth address unavailable; skipping reconnect pairing");
    return;
  }
  uint8_t setMac[14] = {0x00, 0x02};
  for (int index = 0; index < 6; ++index) {
    setMac[2 + index] = local[static_cast<size_t>(5 - index)];
    setMac[8 + index] = local[static_cast<size_t>(5 - index)];
  }
  // Long-term keys as used by JoyCon2Mac's macOS pairing flow.
  const uint8_t ltk1[17] = {0x00, 0x08, 0x06, 0x5A, 0x60, 0xE9, 0x02, 0xE4, 0xE1,
                            0x02, 0x02, 0x9E, 0x3F, 0xA3, 0x9A, 0x78, 0xD1};
  const uint8_t ltk2[17] = {0x00, 0x93, 0x4E, 0x58, 0x0F, 0x16, 0x3A, 0xEE, 0xCF,
                            0xB5, 0x75, 0xFC, 0x91, 0x36, 0xB2, 0x2F, 0xBB};
  const uint8_t finish[1] = {0x00};
  [device enqueueCommand:MakeCommand(kCmdPair, kSubPairSetMac, setMac, sizeof(setMac))
                   label:@"pair: set host address" completion:nil];
  [device enqueueCommand:MakeCommand(kCmdPair, kSubPairLtk1, ltk1, sizeof(ltk1))
                   label:@"pair: key 1" completion:nil];
  [device enqueueCommand:MakeCommand(kCmdPair, kSubPairLtk2, ltk2, sizeof(ltk2))
                   label:@"pair: key 2" completion:nil];
  [device enqueueCommand:MakeCommand(kCmdPair, kSubPairFinish, finish, sizeof(finish))
                   label:@"pair: finish" completion:nil];
}

- (void)finishStartupForDevice:(KartPadJoyCon2Device *)device {
  if (device.peripheral.state != CBPeripheralStateConnected) return;
  [device.peripheral setNotifyValue:YES forCharacteristic:device.inputCharacteristic];
  if ([device attachToSDL]) {
    device.status = [NSString stringWithFormat:@"Connected as Player %d", device.playerNumber];
  } else {
    device.status = @"Connected; waiting for SDL…";
    [self scheduleAttachRetry];
  }
  [self refreshPanel];
}

- (void)scheduleAttachRetry {
  if (_attachTimer != nil) return;
  __weak KartPadJoyCon2Manager *weakSelf = self;
  _attachTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES
                                                   block:^(NSTimer *timer) {
    KartPadJoyCon2Manager *strongSelf = weakSelf;
    if (strongSelf == nil) {
      [timer invalidate];
      return;
    }
    [strongSelf retryPendingAttachments];
  }];
}

- (void)retryPendingAttachments {
  BOOL pending = NO;
  for (KartPadJoyCon2Device *device in _devices.allValues) {
    if (!device.ready || device.joystick != nullptr) continue;
    if (device.peripheral.state != CBPeripheralStateConnected) continue;
    if ([device attachToSDL]) {
      device.status = [NSString stringWithFormat:@"Connected as Player %d", device.playerNumber];
    } else {
      pending = YES;
    }
  }
  if (!pending) {
    [_attachTimer invalidate];
    _attachTimer = nil;
  }
  [self refreshPanel];
}

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
  (void)peripheral;
  if (error != nil) {
    Log(@"notification state for %@ failed: %@", characteristic.UUID.UUIDString,
        error.localizedDescription);
  }
}

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
  if (error != nil) return;
  KartPadJoyCon2Device *device = _devices[peripheral.identifier];
  if (device == nil) return;
  if ([characteristic isEqual:device.inputCharacteristic]) {
    [device handleInputReport:characteristic.value];
  } else if ([characteristic isEqual:device.responseCharacteristic]) {
    [device handleResponse:characteristic.value];
  }
}

- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
  (void)peripheral;
  (void)characteristic;
  if (error != nil) Log(@"write failed: %@", error.localizedDescription);
}

#pragma mark Panel

- (void)showPanel {
  if (_panel == nil) {
    _panel = [[NSPanel alloc]
        initWithContentRect:NSMakeRect(0, 0, 560, 300)
                  styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable)
                    backing:NSBackingStoreBuffered
                      defer:NO];
    _panel.title = @"Experimental Joy-Con 2 (Switch 2)";
    _panel.releasedWhenClosed = NO;
    _panel.delegate = self;

    _headline = [NSTextField labelWithString:
        @"Hold SYNC on each Joy-Con 2 until its LEDs run back and forth."];
    _headline.font = [NSFont systemFontOfSize:15 weight:NSFontWeightSemibold];
    _headline.maximumNumberOfLines = 2;
    _headline.lineBreakMode = NSLineBreakByWordWrapping;

    NSTextField *note = [NSTextField labelWithString:
        @"Each Joy-Con becomes its own player, held sideways with SL/SR at the top. "
        @"A Joy-Con that already paired with this Mac reconnects when you press any button. "
        @"Pick the Joy-Con 2 Sideways preset in Controller Settings for each player."];
    note.maximumNumberOfLines = 4;
    note.lineBreakMode = NSLineBreakByWordWrapping;
    note.textColor = NSColor.secondaryLabelColor;

    _statusField = [NSTextField labelWithString:@""];
    _statusField.font = [NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightRegular];
    _statusField.maximumNumberOfLines = 6;
    _statusField.lineBreakMode = NSLineBreakByWordWrapping;

    NSButton *close = [NSButton buttonWithTitle:@"Close" target:self
                                         action:@selector(closePanel:)];
    NSView *spacer = [NSView new];
    NSStackView *buttons = [NSStackView stackViewWithViews:@[spacer, close]];
    buttons.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    [spacer setContentHuggingPriority:NSLayoutPriorityDefaultLow
                       forOrientation:NSLayoutConstraintOrientationHorizontal];

    NSStackView *content = [NSStackView stackViewWithViews:
        @[_headline, note, _statusField, buttons]];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    content.orientation = NSUserInterfaceLayoutOrientationVertical;
    content.alignment = NSLayoutAttributeLeading;
    content.spacing = 14;
    _panel.contentView = [NSView new];
    [_panel.contentView addSubview:content];
    [NSLayoutConstraint activateConstraints:@[
      [content.leadingAnchor constraintEqualToAnchor:_panel.contentView.leadingAnchor constant:24],
      [content.trailingAnchor constraintEqualToAnchor:_panel.contentView.trailingAnchor constant:-24],
      [content.topAnchor constraintEqualToAnchor:_panel.contentView.topAnchor constant:24],
      [content.bottomAnchor constraintLessThanOrEqualToAnchor:_panel.contentView.bottomAnchor constant:-20],
      [_headline.widthAnchor constraintEqualToAnchor:content.widthAnchor],
      [note.widthAnchor constraintEqualToAnchor:content.widthAnchor],
      [_statusField.widthAnchor constraintEqualToAnchor:content.widthAnchor],
      [buttons.widthAnchor constraintEqualToAnchor:content.widthAnchor],
    ]];
  }
  [_panel center];
  [_panel makeKeyAndOrderFront:nil];
  [NSApp activateIgnoringOtherApps:YES];
  [self refreshPanel];
}

- (void)closePanel:(id)sender {
  (void)sender;
  [_panel close];
}

- (void)refreshPanel {
  if (_panel == nil || !_panel.isVisible) return;
  NSMutableArray<NSString *> *lines = [NSMutableArray array];
  if (!_enabled) {
    [lines addObject:@"Joy-Con 2 support is off. Enable it from the Controls menu."];
  } else if (_central.state == CBManagerStateUnauthorized) {
    [lines addObject:@"Bluetooth access denied. Allow KartPad in System Settings → Privacy & Security → Bluetooth."];
  } else if (_central.state != CBManagerStatePoweredOn) {
    [lines addObject:@"Waiting for Bluetooth to power on…"];
  } else if (_scanning) {
    [lines addObject:@"Scanning… hold SYNC on a Joy-Con 2, or press a button on one paired earlier."];
  }
  NSArray<KartPadJoyCon2Device *> *devices =
      [_devices.allValues sortedArrayUsingComparator:^NSComparisonResult(
          KartPadJoyCon2Device *a, KartPadJoyCon2Device *b) {
        return [@(a.playerNumber) compare:@(b.playerNumber)];
      }];
  for (KartPadJoyCon2Device *device in devices) {
    [lines addObject:[NSString stringWithFormat:@"%@: %@", device.displayName, device.status]];
  }
  if (_reportedForeignHosts.count > 0) {
    [lines addObject:@"A controller paired to another console was ignored. Hold SYNC to pair it here."];
  }
  _statusField.stringValue = [lines componentsJoinedByString:@"\n"];
}

- (void)windowWillClose:(NSNotification *)notification {
  (void)notification;
}

@end

#pragma mark - C entry points

void KartPadShowJoyCon2Pairing(void) {
  [[KartPadJoyCon2Manager sharedManager] setEnabled:YES];
  [[KartPadJoyCon2Manager sharedManager] showPanel];
}

void KartPadApplyExperimentalJoyCon2Preference(void) {
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  if ([defaults objectForKey:KartPadJoyCon2RememberMacDefaultsKey] == nil) {
    [defaults setBool:YES forKey:KartPadJoyCon2RememberMacDefaultsKey];
  }
  [[KartPadJoyCon2Manager sharedManager]
      setEnabled:[defaults boolForKey:KartPadExperimentalJoyCon2DefaultsKey]];
}

void KartPadApplySeparateOriginalJoyConsPreference(void) {
  const BOOL separate = [NSUserDefaults.standardUserDefaults
      boolForKey:KartPadSeparateOriginalJoyConsDefaultsKey];
  // SDL's default ("1") merges an original Joy-Con L/R pair into one gamepad.
  SDL_SetHint(SDL_HINT_JOYSTICK_HIDAPI_COMBINE_JOY_CONS, separate ? "0" : "1");
}
