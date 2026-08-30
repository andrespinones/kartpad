cmake_minimum_required(VERSION 3.27)

project(KartPadMobile LANGUAGES OBJCXX)

if(NOT CMAKE_SYSTEM_NAME STREQUAL "iOS")
  message(FATAL_ERROR "KartPadMobile must be configured for iOS or the iOS Simulator")
endif()

set(KARTPAD_ROOT "${CMAKE_CURRENT_LIST_DIR}/../..")
set(SUNPAD_SNAPSHOT "${KARTPAD_ROOT}/apple/third_party/sunpad")
set(APP_ICON_CATALOG "${CMAKE_CURRENT_LIST_DIR}/Assets.xcassets")
set(PRIVACY_MANIFEST "${CMAKE_CURRENT_LIST_DIR}/PrivacyInfo.xcprivacy")

add_executable(KartPad MACOSX_BUNDLE
  KartPadAppDelegate.mm
  KartPadShellViewController.mm
  "${SUNPAD_SNAPSHOT}/SunPadGameOverlay.mm"
  "${SUNPAD_SNAPSHOT}/SunPadInputMixer.mm"
  "${SUNPAD_SNAPSHOT}/SunPadSettings.mm"
  "${SUNPAD_SNAPSHOT}/SunPadDiagnostics.mm"
  "${KARTPAD_ROOT}/apple/mobile/KartPadClassicInput.mm"
  "${APP_ICON_CATALOG}"
  "${PRIVACY_MANIFEST}")

target_include_directories(KartPad PRIVATE
  "${CMAKE_CURRENT_LIST_DIR}"
  "${SUNPAD_SNAPSHOT}"
  "${KARTPAD_ROOT}/apple/mobile")
target_compile_features(KartPad PRIVATE cxx_std_20)
target_compile_options(KartPad PRIVATE
  -fobjc-arc -Wall -Wextra
  "-ffile-prefix-map=${KARTPAD_ROOT}=.")

foreach(framework IN ITEMS Foundation UIKit CoreGraphics QuartzCore Metal GameController UniformTypeIdentifiers)
  find_library(KARTPAD_${framework}_FRAMEWORK ${framework} REQUIRED)
  target_link_libraries(KartPad PRIVATE "${KARTPAD_${framework}_FRAMEWORK}")
endforeach()

set_source_files_properties("${APP_ICON_CATALOG}" "${PRIVACY_MANIFEST}"
  PROPERTIES MACOSX_PACKAGE_LOCATION Resources)

set_target_properties(KartPad PROPERTIES
  MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_LIST_DIR}/Info.plist"
  XCODE_ATTRIBUTE_ARCHS arm64
  XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME AppIcon
  XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED NO
  XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED NO
  XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD "c++20"
  XCODE_ATTRIBUTE_CURRENT_PROJECT_VERSION 1
  XCODE_ATTRIBUTE_GENERATE_INFOPLIST_FILE NO
  XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET 16.0
  XCODE_ATTRIBUTE_MARKETING_VERSION 0.1.0
  XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER dev.kartpad.app
  XCODE_ATTRIBUTE_SUPPORTED_PLATFORMS "iphonesimulator iphoneos"
  XCODE_ATTRIBUTE_SUPPORTS_MACCATALYST NO
  XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2")
