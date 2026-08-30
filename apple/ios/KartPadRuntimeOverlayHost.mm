#import "kartpad_mobile_runtime_host.h"

#import "KartPadClassicInput.h"
#import "SunPadDiagnostics.h"
#import "SunPadGameOverlay.h"
#import "SunPadInputMixer.h"

#import <SDL3/SDL_properties.h>
#import <SDL3/SDL_video.h>
#import <UIKit/UIKit.h>

#include <algorithm>

@interface KartPadRuntimeOverlayHost : NSObject <SunPadGameOverlayDelegate>
- (instancetype)initWithSDLWindow:(SDL_Window *)window;
- (void)uninstall;
@end

namespace {

KartPadRuntimeOverlayHost *gRuntimeOverlayHost = nil;

UIViewController *KartPadVisibleViewController(UIWindow *window) {
  UIViewController *controller = window.rootViewController;
  while (controller.presentedViewController != nil) {
    controller = controller.presentedViewController;
  }
  return controller;
}

}  // namespace

@implementation KartPadRuntimeOverlayHost {
  __weak UIWindow *_window;
  SunPadGameOverlay *_overlay;
}

- (instancetype)initWithSDLWindow:(SDL_Window *)window {
  self = [super init];
  if (self == nil || window == nullptr) {
    return nil;
  }

  SDL_PropertiesID properties = SDL_GetWindowProperties(window);
  UIWindow *uiWindow = (__bridge UIWindow *)SDL_GetPointerProperty(
      properties, SDL_PROP_WINDOW_UIKIT_WINDOW_POINTER, nullptr);
  UIView *container = uiWindow.rootViewController.view;
  if (uiWindow == nil || container == nil) {
    NSLog(@"[KartPad] SDL UIKit window is unavailable for the touch overlay");
    return nil;
  }

  _window = uiWindow;
  _overlay = [[SunPadGameOverlay alloc] initWithFrame:container.bounds];
  _overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                              UIViewAutoresizingFlexibleHeight;
  _overlay.backgroundColor = UIColor.clearColor;
  _overlay.delegate = self;
  [container addSubview:_overlay];
  [container bringSubviewToFront:_overlay];

  NSNotificationCenter *notifications = NSNotificationCenter.defaultCenter;
  [notifications addObserver:self
                     selector:@selector(applicationWillResignActive:)
                         name:UIApplicationWillResignActiveNotification
                       object:nil];
  [notifications addObserver:self
                     selector:@selector(applicationDidBecomeActive:)
                         name:UIApplicationDidBecomeActiveNotification
                       object:nil];
  SunPadDiagnosticsStart();
  NSLog(@"[KartPad] exact SunPad runtime overlay installed");
  return self;
}

- (void)uninstall {
  [NSNotificationCenter.defaultCenter removeObserver:self];
  [[SunPadInputMixer sharedMixer] clearInputFromTouch:YES];
  _overlay.delegate = nil;
  [_overlay removeFromSuperview];
  _overlay = nil;
}

- (void)applicationWillResignActive:(NSNotification *)notification {
  (void)notification;
  [[SunPadInputMixer sharedMixer] clearInputFromTouch:YES];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
  (void)notification;
  [_overlay refreshControllerVisibility];
  [_overlay applySettings];
}

- (void)showIntegrationAlert:(NSString *)title message:(NSString *)message {
  [[SunPadInputMixer sharedMixer] clearInputFromTouch:YES];
  UIWindow *window = _window;
  UIViewController *controller = KartPadVisibleViewController(window);
  if (controller == nil) {
    return;
  }
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:title
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                            style:UIAlertActionStyleDefault
                                          handler:nil]];
  [controller presentViewController:alert animated:YES completion:nil];
}

- (void)gameOverlayRequestsGameDataChange:(SunPadGameOverlay *)overlay {
  (void)overlay;
  [self showIntegrationAlert:@"Import or Reimport Game Data"
                     message:@"KartPad's private game-data importer is not connected to this runtime candidate yet."];
}

- (void)gameOverlayRequestsGameDataFolderImport:(SunPadGameOverlay *)overlay {
  (void)overlay;
  [self showIntegrationAlert:@"Import from KartPad Folder"
                     message:@"The Files-visible import boundary is present; extraction remains the next integration step."];
}

- (void)gameOverlayRequestsGameDataRemoval:(SunPadGameOverlay *)overlay {
  (void)overlay;
  [self showIntegrationAlert:@"Remove Stored Game Data"
                     message:@"No private game image is retained by this candidate."];
}

- (void)gameOverlayRequestsControllerMapping:(SunPadGameOverlay *)overlay {
  (void)overlay;
  [self showIntegrationAlert:@"Controller Button Mapping"
                     message:@"Touch is mapped directly to Mario Kart's Classic Controller ABI; physical remapping remains open."];
}

- (NSString *)gameOverlayDiagnosticContext:(SunPadGameOverlay *)overlay {
  (void)overlay;
  return @"product=KartPad\nsurface=SDL UIKit+Metal\ncore=full-retail\nprivateDataIncluded=false";
}

- (NSString *)gameOverlayPerformanceProfile:(SunPadGameOverlay *)overlay {
  (void)overlay;
  return @"full-retail-simulator";
}

@end

extern "C" void KartPadMobileRuntimeHostInstall(void *sdlWindow) {
  if (sdlWindow == nullptr || !NSThread.isMainThread) {
    NSLog(@"[KartPad] refusing overlay installation away from UIKit's main thread");
    return;
  }
  [gRuntimeOverlayHost uninstall];
  gRuntimeOverlayHost =
      [[KartPadRuntimeOverlayHost alloc] initWithSDLWindow:(SDL_Window *)sdlWindow];
}

extern "C" void KartPadMobileRuntimeHostUninstall() {
  [gRuntimeOverlayHost uninstall];
  gRuntimeOverlayHost = nil;
}

extern "C" bool KartPadMobileReadClassicInput(
    KartPadMobileClassicInputSnapshot *snapshot) {
  if (snapshot == nullptr || gRuntimeOverlayHost == nil) {
    return false;
  }
  const SunPadInputState source =
      [[SunPadInputMixer sharedMixer] consumeMergedState];
  const KartPadClassicInputState adapted =
      kartpad::mobile::AdaptSunPadInput(source);
  snapshot->buttons = adapted.buttons;
  snapshot->leftStickX = std::clamp(static_cast<float>(adapted.leftStickX) / 127.0f,
                                   -1.0f, 1.0f);
  snapshot->leftStickY = std::clamp(static_cast<float>(adapted.leftStickY) / 127.0f,
                                   -1.0f, 1.0f);
  snapshot->connected = adapted.connected ? 1 : 0;
  return true;
}
