#import "kartpad_mobile_runtime_host.h"

#import "KartPadClassicInput.h"
#import "KartPadPhysicalControllers.h"
#import "SunPadDiagnostics.h"
#import "SunPadGameOverlay.h"
#import "SunPadInputMixer.h"
#import "SunPadSettings.h"

#import <SDL3/SDL_properties.h>
#import <SDL3/SDL_video.h>
#import <CommonCrypto/CommonDigest.h>
#import <TargetConditionals.h>
#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#include <algorithm>

@interface KartPadRuntimeOverlayHost : NSObject <SunPadGameOverlayDelegate,
                                                 UIDocumentPickerDelegate>
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

NSString *KartPadSupportRoot() {
  return [[NSHomeDirectory() stringByAppendingPathComponent:
      @"Library/Application Support"] stringByAppendingPathComponent:@"KartPad"];
}

NSString *KartPadSHA256ForFile(NSString *path, NSError **error) {
  NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe
                                         error:error];
  if (data == nil || data.length > UINT32_MAX) {
    return nil;
  }
  unsigned char digest[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
  NSMutableString *result =
      [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
  for (NSUInteger index = 0; index < CC_SHA256_DIGEST_LENGTH; ++index) {
    [result appendFormat:@"%02x", digest[index]];
  }
  return result;
}

NSString *KartPadResolvedExtractedRoot(NSURL *selectedURL) {
  NSFileManager *files = NSFileManager.defaultManager;
  NSArray<NSString *> *candidates = @[
    selectedURL.path,
    [selectedURL.path stringByAppendingPathComponent:@"DATA"],
    [selectedURL.path stringByAppendingPathComponent:@"GameData"],
  ];
  for (NSString *candidate in candidates) {
    BOOL directory = NO;
    if ([files fileExistsAtPath:[candidate stringByAppendingPathComponent:@"files"]
                    isDirectory:&directory] && directory &&
        [files fileExistsAtPath:[candidate stringByAppendingPathComponent:@"sys/fst.bin"]]) {
      return candidate;
    }
  }
  return nil;
}

NSString *KartPadValidateExtractedRoot(NSString *root, NSError **error) {
  if (root.length == 0) {
    return @"Choose an extracted Mario Kart Wii DATA folder containing files/ and sys/.";
  }
  NSArray<NSString *> *required = @[
    @"sys/boot.bin", @"sys/bi2.bin", @"sys/apploader.img", @"sys/fst.bin",
    @"sys/main.dol", @"files/rel/StaticR.rel",
  ];
  NSFileManager *files = NSFileManager.defaultManager;
  for (NSString *relative in required) {
    if (![files fileExistsAtPath:[root stringByAppendingPathComponent:relative]]) {
      return [NSString stringWithFormat:@"The extracted game data is incomplete (missing %@).",
                                        relative];
    }
  }

  NSData *boot = [NSData dataWithContentsOfFile:
      [root stringByAppendingPathComponent:@"sys/boot.bin"] options:0 error:error];
  if (boot == nil) {
    return @"KartPad could not read sys/boot.bin.";
  }
  if (boot.length < 0x20) {
    return @"The selected sys/boot.bin is truncated.";
  }
  const uint8_t *bytes = static_cast<const uint8_t *>(boot.bytes);
  if (memcmp(bytes, "RMCP01", 6) != 0 || bytes[6] != 0 || bytes[7] != 0) {
    return @"KartPad currently supports RMCP01 (PAL), disc 0, revision 0 only.";
  }
  const uint32_t magic = (static_cast<uint32_t>(bytes[0x18]) << 24) |
                         (static_cast<uint32_t>(bytes[0x19]) << 16) |
                         (static_cast<uint32_t>(bytes[0x1A]) << 8) |
                         static_cast<uint32_t>(bytes[0x1B]);
  if (magic != 0x5D1C9EA3u) {
    return @"The selected folder does not contain a valid extracted Wii disc header.";
  }

  NSString *dolHash = KartPadSHA256ForFile(
      [root stringByAppendingPathComponent:@"sys/main.dol"], error);
  if (dolHash == nil) {
    return @"KartPad could not hash sys/main.dol.";
  }
  if (![dolHash isEqualToString:
      @"80d18895b39c63bd80f457398bfcbb91b7d16ac116a41a88967e954080155b05"]) {
    return @"sys/main.dol does not match the supported RMCP01 revision 0 profile.";
  }
  return nil;
}

BOOL KartPadEnsureRelativeDvdRoot(NSError **error) {
  NSString *configPath = [KartPadSupportRoot() stringByAppendingPathComponent:@"Config.toml"];
  NSError *readError = nil;
  NSString *config = [NSString stringWithContentsOfFile:configPath
                                               encoding:NSUTF8StringEncoding
                                                  error:&readError];
  if (config == nil) {
    if ([NSFileManager.defaultManager fileExistsAtPath:configPath]) {
      if (error != nullptr) {
        *error = readError;
      }
      return NO;
    }
    config = @"";
  }
  NSRegularExpression *dvdLine = [NSRegularExpression
      regularExpressionWithPattern:@"(?m)^\\s*#?\\s*dvd_root\\s*=.*$"
                           options:0 error:error];
  if (dvdLine == nil) {
    return NO;
  }
  NSRange whole = NSMakeRange(0, config.length);
  config = [dvdLine stringByReplacingMatchesInString:config options:0 range:whole
                                         withTemplate:@""];
  NSRegularExpression *paths = [NSRegularExpression
      regularExpressionWithPattern:@"(?m)^\\s*\\[paths\\]\\s*$"
                           options:0 error:error];
  if (paths == nil) {
    return NO;
  }
  NSTextCheckingResult *match =
      [paths firstMatchInString:config options:0 range:NSMakeRange(0, config.length)];
  if (match != nil) {
    NSUInteger insertion = NSMaxRange(match.range);
    config = [config stringByReplacingCharactersInRange:NSMakeRange(insertion, 0)
                                              withString:@"\ndvd_root = \"GameData\""];
  } else {
    config = [config stringByAppendingString:
        @"\n\n[paths]\ndvd_root = \"GameData\"\n"];
  }
  return [config writeToFile:configPath atomically:YES
                    encoding:NSUTF8StringEncoding error:error];
}

void KartPadRemoveStaleImportDirectories(NSString *supportRoot) {
  NSFileManager *files = NSFileManager.defaultManager;
  NSArray<NSString *> *entries =
      [files contentsOfDirectoryAtPath:supportRoot error:nil];
  for (NSString *entry in entries) {
    if ([entry hasPrefix:@"GameData.import-"]) {
      [files removeItemAtPath:[supportRoot stringByAppendingPathComponent:entry]
                        error:nil];
    }
  }
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
  UIAlertController *_gameDataProgressAlert;
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

- (void)presentGameDataFolderPicker {
  [[SunPadInputMixer sharedMixer] clearInputFromTouch:YES];
  UIViewController *controller = KartPadVisibleViewController(_window);
  if (controller == nil) {
    return;
  }
  UIDocumentPickerViewController *picker =
      [[UIDocumentPickerViewController alloc]
          initForOpeningContentTypes:@[UTTypeFolder] asCopy:NO];
  picker.delegate = self;
  picker.allowsMultipleSelection = NO;
  [controller presentViewController:picker animated:YES completion:nil];
}

- (NSArray<NSURL *> *)extractedRootsInDocumentsDirectory {
  NSURL *documents = [NSFileManager.defaultManager
      URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
  if (documents == nil) {
    return @[];
  }
  NSArray<NSURL *> *entries = [NSFileManager.defaultManager
      contentsOfDirectoryAtURL:documents
    includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                       options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
  NSMutableArray<NSURL *> *roots = [NSMutableArray array];
  for (NSURL *entry in entries) {
    NSNumber *directory = nil;
    [entry getResourceValue:&directory forKey:NSURLIsDirectoryKey error:nil];
    if (directory.boolValue && KartPadResolvedExtractedRoot(entry) != nil) {
      [roots addObject:entry];
    }
  }
  [roots sortUsingComparator:^NSComparisonResult(NSURL *left, NSURL *right) {
    return [left.lastPathComponent localizedStandardCompare:right.lastPathComponent];
  }];
  return roots;
}

- (void)importExtractedGameDataFromURL:(NSURL *)url {
  UIViewController *controller = KartPadVisibleViewController(_window);
  if (controller == nil) {
    return;
  }
  UIAlertController *progress =
      [UIAlertController alertControllerWithTitle:@"Importing Game Data"
                                          message:@"Validating the extracted disc…"
                                   preferredStyle:UIAlertControllerStyleAlert];
  _gameDataProgressAlert = progress;
  [controller presentViewController:progress animated:YES completion:nil];

  __weak KartPadRuntimeOverlayHost *weakSelf = self;
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    BOOL securityScoped = [url startAccessingSecurityScopedResource];
    NSString *sourceRoot = KartPadResolvedExtractedRoot(url);
    NSError *workError = nil;
    NSString *validationError = KartPadValidateExtractedRoot(sourceRoot, &workError);
    if (validationError != nil || workError != nil) {
      if (securityScoped) {
        [url stopAccessingSecurityScopedResource];
      }
      dispatch_async(dispatch_get_main_queue(), ^{
        KartPadRuntimeOverlayHost *strongSelf = weakSelf;
        if (strongSelf == nil) {
          return;
        }
        [strongSelf->_gameDataProgressAlert dismissViewControllerAnimated:YES completion:^{
          [strongSelf showIntegrationAlert:@"Game Data Not Imported"
                                   message:validationError ?: workError.localizedDescription];
        }];
      });
      return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
      KartPadRuntimeOverlayHost *strongSelf = weakSelf;
      if (strongSelf == nil) {
        return;
      }
      strongSelf->_gameDataProgressAlert.message = @"Copying private game data…";
    });
    NSString *supportRoot = KartPadSupportRoot();
    NSString *staging = [supportRoot stringByAppendingPathComponent:
        [NSString stringWithFormat:@"GameData.import-%@", NSUUID.UUID.UUIDString]];
    NSFileManager *files = NSFileManager.defaultManager;
    [files createDirectoryAtPath:supportRoot withIntermediateDirectories:YES
                       attributes:@{NSFileProtectionKey:
                           NSFileProtectionCompleteUntilFirstUserAuthentication}
                            error:&workError];
    if (workError == nil) {
      KartPadRemoveStaleImportDirectories(supportRoot);
      [files copyItemAtPath:sourceRoot toPath:staging error:&workError];
    }
    if (securityScoped) {
      [url stopAccessingSecurityScopedResource];
    }

    if (workError == nil && !KartPadEnsureRelativeDvdRoot(&workError)) {
      workError = workError ?: [NSError errorWithDomain:@"dev.kartpad.gamedata"
                                                   code:2 userInfo:@{
        NSLocalizedDescriptionKey: @"Could not update Config.toml."
      }];
    }

    NSString *dataDirectory = [supportRoot stringByAppendingPathComponent:@"GameData"];
    NSString *rollback = [supportRoot stringByAppendingPathComponent:
        [NSString stringWithFormat:@"GameData.rollback-%@", NSUUID.UUID.UUIDString]];
    BOOL movedExisting = NO;
    if (workError == nil && [files fileExistsAtPath:dataDirectory]) {
      movedExisting = [files moveItemAtPath:dataDirectory toPath:rollback error:&workError];
    }
#if TARGET_OS_SIMULATOR
    if (workError == nil &&
        [NSProcessInfo.processInfo.environment[@"KARTPAD_IMPORT_FORCE_SWAP_FAILURE"] boolValue]) {
      workError = [NSError errorWithDomain:@"dev.kartpad.gamedata"
                                      code:3 userInfo:@{
        NSLocalizedDescriptionKey: @"Injected Simulator swap failure."
      }];
    }
#endif
    if (workError == nil) {
      [files moveItemAtPath:staging toPath:dataDirectory error:&workError];
    }
    if (workError != nil && movedExisting && ![files fileExistsAtPath:dataDirectory]) {
      [files moveItemAtPath:rollback toPath:dataDirectory error:nil];
    } else if (workError == nil && movedExisting) {
      [files removeItemAtPath:rollback error:nil];
    }
    if (workError != nil) {
      [files removeItemAtPath:staging error:nil];
    }
    if (workError == nil) {
      NSURL *dataURL = [NSURL fileURLWithPath:dataDirectory isDirectory:YES];
      [dataURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
      [files setAttributes:@{NSFileProtectionKey:
          NSFileProtectionCompleteUntilFirstUserAuthentication}
                 ofItemAtPath:dataDirectory error:nil];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
      KartPadRuntimeOverlayHost *strongSelf = weakSelf;
      if (strongSelf == nil) {
        return;
      }
      [strongSelf->_gameDataProgressAlert dismissViewControllerAnimated:YES completion:^{
        strongSelf->_gameDataProgressAlert = nil;
        if (workError != nil) {
          [strongSelf showIntegrationAlert:@"Game Data Import Failed"
                                   message:workError.localizedDescription];
          return;
        }
        SunPadSettings *settings = SunPadSettings.sharedSettings;
        settings.retainedGameDataPath = nil;
        settings.extractedGameRoot = dataDirectory;
        [settings synchronize];
        [strongSelf showIntegrationAlert:@"Game Data Imported"
                                 message:@"The validated RMCP01 data is stored privately. Close and reopen KartPad to use the new copy."];
      }];
    });
  });
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
    didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
  (void)controller;
  NSURL *url = urls.firstObject;
  if (url != nil) {
    [self importExtractedGameDataFromURL:url];
  }
}

- (void)gameOverlayRequestsGameDataChange:(SunPadGameOverlay *)overlay {
  (void)overlay;
  [self presentGameDataFolderPicker];
}

- (void)gameOverlayRequestsGameDataFolderImport:(SunPadGameOverlay *)overlay {
  (void)overlay;
  NSArray<NSURL *> *roots = [self extractedRootsInDocumentsDirectory];
  if (roots.count == 1) {
    [self importExtractedGameDataFromURL:roots.firstObject];
    return;
  }
  UIViewController *controller = KartPadVisibleViewController(_window);
  if (controller == nil) {
    return;
  }
  NSString *message = roots.count == 0
      ? @"No extracted DATA folder was found. In Files, place it directly in On My iPhone → KartPad, then try again."
      : @"Choose an extracted Mario Kart Wii DATA folder from On My iPhone → KartPad.";
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:@"KartPad Folder"
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];
  __weak KartPadRuntimeOverlayHost *weakSelf = self;
  for (NSURL *root in roots) {
    [alert addAction:[UIAlertAction actionWithTitle:root.lastPathComponent
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
      (void)action;
      [weakSelf importExtractedGameDataFromURL:root];
    }]];
  }
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                            style:UIAlertActionStyleCancel handler:nil]];
  [controller presentViewController:alert animated:YES completion:nil];
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
