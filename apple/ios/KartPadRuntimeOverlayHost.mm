#import "kartpad_mobile_runtime_host.h"

#import "KartPadClassicInput.h"
#import "KartPadPhysicalControllers.h"
#import "SunPadDiagnostics.h"
#import "SunPadGameOverlay.h"
#import "SunPadInputMixer.h"
#import "SunPadSettings.h"

#import <SDL3/SDL_properties.h>
#import <SDL3/SDL_video.h>
#import <UIKit/UIKit.h>

#include <algorithm>

@interface KartPadRuntimeOverlayHost : NSObject <SunPadGameOverlayDelegate>
- (instancetype)initWithSDLWindow:(SDL_Window *)window;
- (void)uninstall;
@end

@interface KartPadGameOverlay : SunPadGameOverlay
@property(nonatomic, copy) void (^multiplayerRequested)(void);
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

@implementation KartPadGameOverlay

- (void)layoutSubviews {
  [super layoutSubviews];
  UIButton *menuButton = nil;
  for (UIView *candidate in self.subviews) {
    if ([candidate isKindOfClass:UIButton.class] &&
        [candidate.accessibilityLabel isEqualToString:@"Menu"]) {
      menuButton = (UIButton *)candidate;
      break;
    }
  }
  UIMenu *sourceMenu = menuButton.menu;
  if (sourceMenu == nil ||
      [sourceMenu.identifier isEqualToString:@"dev.kartpad.menu"]) {
    return;
  }

  __weak KartPadGameOverlay *weakSelf = self;
  UIAction *multiplayer =
      [UIAction actionWithTitle:@"Multiplayer…"
                          image:[UIImage systemImageNamed:@"person.2.fill"]
                     identifier:@"dev.kartpad.multiplayer"
                        handler:^(__kindof UIAction *action) {
                          (void)action;
                          if (weakSelf.multiplayerRequested != nil) {
                            weakSelf.multiplayerRequested();
                          }
                        }];
  NSMutableArray<UIMenuElement *> *children =
      [NSMutableArray arrayWithObject:multiplayer];
  [children addObjectsFromArray:sourceMenu.children];
  menuButton.menu = [UIMenu menuWithTitle:@"KartPad"
                                    image:sourceMenu.image
                               identifier:@"dev.kartpad.menu"
                                  options:sourceMenu.options
                                 children:children];
}

@end

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
  KartPadGameOverlay *overlay =
      [[KartPadGameOverlay alloc] initWithFrame:container.bounds];
  __weak KartPadRuntimeOverlayHost *weakSelf = self;
  overlay.multiplayerRequested = ^{
    [weakSelf showMultiplayerAccess];
  };
  _overlay = overlay;
  _overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                              UIViewAutoresizingFlexibleHeight;
  _overlay.backgroundColor = UIColor.clearColor;
  _overlay.delegate = self;
  [container addSubview:_overlay];
  [container bringSubviewToFront:_overlay];
  [[KartPadPhysicalControllers sharedControllers] start];

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

- (void)showMultiplayerAccess {
  [[SunPadInputMixer sharedMixer] clearInputFromTouch:YES];
  UIViewController *controller = KartPadVisibleViewController(_window);
  if (controller == nil) {
    return;
  }
  const NSUInteger controllerCount =
      [KartPadPhysicalControllers sharedControllers].connectedControllerCount;
  NSString *message = [NSString stringWithFormat:
      @"Choose Multiplayer in Mario Kart Wii's Main Menu. Connected extended controllers are assigned automatically to Players 1–4; KartPad touch remains available for Player 1. Connected now: %lu.",
      (unsigned long)controllerCount];
  UIAlertController *sheet =
      [UIAlertController alertControllerWithTitle:@"Multiplayer"
                                          message:message
                                   preferredStyle:UIAlertControllerStyleActionSheet];
  __weak KartPadRuntimeOverlayHost *weakSelf = self;
  [sheet addAction:[UIAlertAction actionWithTitle:@"Controller Setup…"
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
    (void)action;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(0.35 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
      KartPadRuntimeOverlayHost *strongSelf = weakSelf;
      if (strongSelf != nil) {
        [strongSelf gameOverlayRequestsControllerMapping:strongSelf->_overlay];
      }
    });
  }]];
  [sheet addAction:[UIAlertAction actionWithTitle:@"Continue Playing"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];
  UIPopoverPresentationController *popover = sheet.popoverPresentationController;
  popover.sourceView = _overlay;
  popover.sourceRect = CGRectMake(CGRectGetMidX(_overlay.bounds),
                                  CGRectGetMidY(_overlay.bounds), 1.0, 1.0);
  [controller presentViewController:sheet animated:YES completion:nil];
}

- (void)uninstall {
  [NSNotificationCenter.defaultCenter removeObserver:self];
  [[KartPadPhysicalControllers sharedControllers] stop];
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
  [[KartPadPhysicalControllers sharedControllers] reconcileControllers];
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
  const NSUInteger count =
      [KartPadPhysicalControllers sharedControllers].connectedControllerCount;
  NSString *message = [NSString stringWithFormat:
      @"Extended controllers connect automatically in stable Player 1–4 slots. Face buttons use SunPad's persisted A/B/X/Y/Z mapping; sticks, D-pad, Menu, shoulders, and triggers remain direct. Connected now: %lu.",
      (unsigned long)count];
  [self showIntegrationAlert:@"Controller Setup" message:message];
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

extern "C" bool KartPadMobileReadRuntimeSettings(
    KartPadMobileRuntimeSettings *settings) {
  if (settings == nullptr) {
    return false;
  }
  SunPadSettings *source = [SunPadSettings sharedSettings];
  settings->aspectRatioMode = static_cast<int>(source.aspectRatioMode);
  settings->resolutionScale = source.renderScaleFloat;
  settings->showFps = source.showFPSCounter ? 1 : 0;
  return true;
}

extern "C" bool KartPadMobileReadClassicInput(
    KartPadMobileClassicInputSnapshot *snapshot) {
  return KartPadMobileReadClassicInputForPlayer(0, snapshot);
}

extern "C" bool KartPadMobileReadClassicInputForPlayer(
    unsigned int player, KartPadMobileClassicInputSnapshot *snapshot) {
  if (snapshot == nullptr || gRuntimeOverlayHost == nil) {
    return false;
  }
  SunPadInputState source{};
  if (player == 0) {
    source = [[SunPadInputMixer sharedMixer] consumeMergedState];
  } else if (player < 4) {
    [[KartPadPhysicalControllers sharedControllers] consumePlayer:player
                                                            state:&source];
  } else {
    return false;
  }
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
