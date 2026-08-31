#import "kartpad_mobile_runtime_host.h"

#import "KartPadClassicInput.h"
#import "KartPadMotionSteering.h"
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
#include <cmath>

@interface KartPadRuntimeOverlayHost : NSObject <SunPadGameOverlayDelegate,
                                                 UIDocumentPickerDelegate>
- (instancetype)initWithSDLWindow:(SDL_Window *)window;
- (void)uninstall;
@end

@interface KartPadGameOverlay : SunPadGameOverlay
@property(nonatomic, copy) void (^multiplayerRequested)(void);
@property(nonatomic, copy) void (^motionSteeringRequested)(void);
@property(nonatomic, weak) UIButton *kartPadGasButton;
@property(nonatomic, strong) UIColor *kartPadGasRestColor;
@property(nonatomic, assign) NSUInteger kartPadGasHoldGeneration;
@property(nonatomic, assign) BOOL kartPadGasPressed;
@property(nonatomic, assign) BOOL kartPadGasHoldSelfTestStarted;
@property(nonatomic, assign) BOOL kartPadGasInputSelfTestStarted;
@property(nonatomic, assign) BOOL kartPadModalInputSelfTestStarted;
@property(nonatomic, assign) BOOL kartPadEditorUITestStarted;
- (void)resetKartPadControlAppearance;
@end

// KartPad keeps SunPad's pinned implementation byte-identical. This narrow
// declaration lets the owning subclass replace Sunshine's analog FLUDD
// pressure semantics with Mario Kart Wii's ordinary digital Classic R button.
@interface SunPadGameOverlay (KartPadControlHooks)
- (void)rPressureChanged:(uint8_t)pressure fullPress:(BOOL)fullPress;
- (void)clearTouchInput;
- (void)toggleSettingsPanel;
- (void)selectControlForEditing:(UIView *)control;
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

UIScrollView *KartPadScrollableSettingsView(UIView *root) {
  if ([root isKindOfClass:UIScrollView.class]) {
    UIScrollView *scroll = (UIScrollView *)root;
    if (scroll.contentSize.height > CGRectGetHeight(scroll.bounds) + 1.0) {
      return scroll;
    }
  }
  for (UIView *child in root.subviews) {
    UIScrollView *found = KartPadScrollableSettingsView(child);
    if (found != nil) return found;
  }
  return nil;
}

UIView *KartPadSubviewWithAccessibilityLabel(UIView *root, NSString *label,
                                              Class viewClass) {
  if ([root isKindOfClass:viewClass] &&
      [root.accessibilityLabel isEqualToString:label]) {
    return root;
  }
  for (UIView *child in root.subviews) {
    UIView *found = KartPadSubviewWithAccessibilityLabel(child, label,
                                                          viewClass);
    if (found != nil) return found;
  }
  return nil;
}

NSString *KartPadSupportRoot() {
  return [[NSHomeDirectory() stringByAppendingPathComponent:
      @"Library/Application Support"] stringByAppendingPathComponent:@"KartPad"];
}

NSString *KartPadRemovalMarkerPath() {
  return [KartPadSupportRoot() stringByAppendingPathComponent:
      @"RemoveGameDataOnNextLaunch"];
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

NSError *KartPadGameDataError(NSInteger code, NSString *message) {
  return [NSError errorWithDomain:@"dev.kartpad.gamedata" code:code userInfo:@{
    NSLocalizedDescriptionKey: message,
  }];
}

NSError *KartPadApplyScheduledGameDataRemoval() {
  NSFileManager *files = NSFileManager.defaultManager;
  NSString *marker = KartPadRemovalMarkerPath();
  if (![files fileExistsAtPath:marker]) {
    return nil;
  }

  NSString *supportRoot = KartPadSupportRoot();
  NSArray<NSString *> *entries =
      [files contentsOfDirectoryAtPath:supportRoot error:nil] ?: @[];
  for (NSString *entry in entries) {
    if ([entry isEqualToString:@"GameData"] ||
        [entry hasPrefix:@"GameData.import-"] ||
        [entry hasPrefix:@"GameData.rollback-"]) {
      NSError *error = nil;
      if (![files removeItemAtPath:[supportRoot stringByAppendingPathComponent:entry]
                            error:&error]) {
        return error ?: KartPadGameDataError(4, @"Could not remove stored game data.");
      }
    }
  }
  NSError *markerError = nil;
  if (![files removeItemAtPath:marker error:&markerError]) {
    return markerError ?: KartPadGameDataError(5, @"Could not finish game-data removal.");
  }

  SunPadSettings *settings = SunPadSettings.sharedSettings;
  settings.retainedGameDataPath = nil;
  settings.extractedGameRoot = nil;
  [settings synchronize];
  return nil;
}

void KartPadRecoverInterruptedImport(NSString *supportRoot) {
  NSFileManager *files = NSFileManager.defaultManager;
  NSString *dataDirectory = [supportRoot stringByAppendingPathComponent:@"GameData"];
  NSArray<NSString *> *entries =
      [files contentsOfDirectoryAtPath:supportRoot error:nil] ?: @[];
  NSMutableArray<NSString *> *rollbacks = [NSMutableArray array];
  for (NSString *entry in entries) {
    if ([entry hasPrefix:@"GameData.rollback-"]) {
      [rollbacks addObject:entry];
    }
  }
  [rollbacks sortUsingSelector:@selector(compare:)];
  if (![files fileExistsAtPath:dataDirectory] && rollbacks.count == 1) {
    NSString *rollback = [supportRoot stringByAppendingPathComponent:rollbacks.firstObject];
    [files moveItemAtPath:rollback toPath:dataDirectory error:nil];
  }
  KartPadRemoveStaleImportDirectories(supportRoot);
}

void KartPadRemoveRollbackDirectories(NSString *supportRoot) {
  NSFileManager *files = NSFileManager.defaultManager;
  NSArray<NSString *> *entries =
      [files contentsOfDirectoryAtPath:supportRoot error:nil] ?: @[];
  for (NSString *entry in entries) {
    if ([entry hasPrefix:@"GameData.rollback-"]) {
      [files removeItemAtPath:[supportRoot stringByAppendingPathComponent:entry]
                        error:nil];
    }
  }
}

BOOL KartPadInstalledGameDataIsValid() {
  NSString *supportRoot = KartPadSupportRoot();
  KartPadRecoverInterruptedImport(supportRoot);
  NSString *dataDirectory = [supportRoot stringByAppendingPathComponent:@"GameData"];
  NSError *error = nil;
  if (KartPadValidateExtractedRoot(dataDirectory, &error) != nil || error != nil) {
    return NO;
  }
  if (!KartPadEnsureRelativeDvdRoot(&error) || error != nil) {
    return NO;
  }
  KartPadRemoveRollbackDirectories(supportRoot);
  return YES;
}

NSError *KartPadPerformGameDataImport(NSURL *url) {
  BOOL securityScoped = [url startAccessingSecurityScopedResource];
  NSString *sourceRoot = KartPadResolvedExtractedRoot(url);
  NSError *workError = nil;
  NSString *validationError = KartPadValidateExtractedRoot(sourceRoot, &workError);
  if (validationError != nil && workError == nil) {
    workError = KartPadGameDataError(1, validationError);
  }
  if (workError != nil) {
    if (securityScoped) {
      [url stopAccessingSecurityScopedResource];
    }
    return workError;
  }

  NSString *supportRoot = KartPadSupportRoot();
  NSString *staging = [supportRoot stringByAppendingPathComponent:
      [NSString stringWithFormat:@"GameData.import-%@", NSUUID.UUID.UUIDString]];
  NSFileManager *files = NSFileManager.defaultManager;
  [files createDirectoryAtPath:supportRoot withIntermediateDirectories:YES
                     attributes:@{NSFileProtectionKey:
                         NSFileProtectionCompleteUntilFirstUserAuthentication}
                          error:&workError];
  if (workError == nil) {
    KartPadRecoverInterruptedImport(supportRoot);
    [files copyItemAtPath:sourceRoot toPath:staging error:&workError];
  }
  if (securityScoped) {
    [url stopAccessingSecurityScopedResource];
  }

  if (workError == nil && !KartPadEnsureRelativeDvdRoot(&workError)) {
    workError = workError ?: KartPadGameDataError(2, @"Could not update Config.toml.");
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
    workError = KartPadGameDataError(3, @"Injected Simulator swap failure.");
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
    return workError;
  }

  NSURL *dataURL = [NSURL fileURLWithPath:dataDirectory isDirectory:YES];
  [dataURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
  [files setAttributes:@{NSFileProtectionKey:
      NSFileProtectionCompleteUntilFirstUserAuthentication}
             ofItemAtPath:dataDirectory error:nil];
  KartPadRemoveRollbackDirectories(supportRoot);
  SunPadSettings *settings = SunPadSettings.sharedSettings;
  settings.retainedGameDataPath = nil;
  settings.extractedGameRoot = dataDirectory;
  [settings synchronize];
  return nil;
}

}  // namespace

@interface KartPadFirstLaunchViewController : UIViewController
@end

@implementation KartPadFirstLaunchViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = UIColor.systemBackgroundColor;

  UILabel *title = [[UILabel alloc] init];
  title.translatesAutoresizingMaskIntoConstraints = NO;
  title.text = @"KartPad";
  title.font = [UIFont systemFontOfSize:34.0 weight:UIFontWeightBold];
  title.textAlignment = NSTextAlignmentCenter;

  UILabel *message = [[UILabel alloc] init];
  message.translatesAutoresizingMaskIntoConstraints = NO;
  message.text = @"Your own extracted RMCP01 game data is required before play.";
  message.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
  message.textColor = UIColor.secondaryLabelColor;
  message.textAlignment = NSTextAlignmentCenter;
  message.numberOfLines = 0;

  UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[title, message]];
  stack.translatesAutoresizingMaskIntoConstraints = NO;
  stack.axis = UILayoutConstraintAxisVertical;
  stack.spacing = 12.0;
  [self.view addSubview:stack];
  [NSLayoutConstraint activateConstraints:@[
    [stack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [stack.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    [stack.leadingAnchor constraintGreaterThanOrEqualToAnchor:
        self.view.safeAreaLayoutGuide.leadingAnchor constant:32.0],
    [stack.trailingAnchor constraintLessThanOrEqualToAnchor:
        self.view.safeAreaLayoutGuide.trailingAnchor constant:-32.0],
  ]];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskLandscape;
}

@end

@interface KartPadFirstLaunchHost : NSObject <UIDocumentPickerDelegate>
@property(nonatomic, strong) UIWindow *window;
@property(nonatomic, strong) KartPadFirstLaunchViewController *root;
@property(nonatomic, assign) BOOL finished;
@property(nonatomic, assign) BOOL succeeded;
- (BOOL)run;
- (void)showOptions;
@end

@implementation KartPadFirstLaunchHost

- (UIWindowScene *)availableWindowScene {
  for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
    if ([scene isKindOfClass:UIWindowScene.class]) {
      return (UIWindowScene *)scene;
    }
  }
  return nil;
}

- (NSArray<NSURL *> *)documentsRoots {
  NSURL *documents = [NSFileManager.defaultManager
      URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
  NSArray<NSURL *> *entries = documents == nil ? @[] :
      [NSFileManager.defaultManager contentsOfDirectoryAtURL:documents
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

- (void)showMessage:(NSString *)title
             detail:(NSString *)detail
         completion:(void (^)(void))completion {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:title message:detail
                                   preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action) {
    (void)action;
    if (completion != nil) {
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                   (int64_t)(0.35 * NSEC_PER_SEC)),
                     dispatch_get_main_queue(), completion);
    }
  }]];
  [self.root presentViewController:alert animated:YES completion:nil];
}

- (void)startImport:(NSURL *)url {
  UIAlertController *progress =
      [UIAlertController alertControllerWithTitle:@"Importing Game Data"
                                          message:@"Validating and copying the extracted disc…"
                                   preferredStyle:UIAlertControllerStyleAlert];
  [self.root presentViewController:progress animated:YES completion:nil];
  __weak KartPadFirstLaunchHost *weakSelf = self;
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    NSError *error = KartPadPerformGameDataImport(url);
    dispatch_async(dispatch_get_main_queue(), ^{
      KartPadFirstLaunchHost *strongSelf = weakSelf;
      if (strongSelf == nil) {
        return;
      }
      [progress dismissViewControllerAnimated:YES completion:^{
        if (error != nil) {
          [strongSelf showMessage:@"Game Data Import Failed"
                           detail:error.localizedDescription completion:^{
            [strongSelf showOptions];
          }];
          return;
        }
        strongSelf.succeeded = YES;
        strongSelf.finished = YES;
      }];
    });
  });
}

- (void)chooseDocumentsRoot {
  NSArray<NSURL *> *roots = [self documentsRoots];
  if (roots.count == 0) {
    [self showMessage:@"KartPad Folder"
               detail:@"No extracted DATA folder was found. In Files, place it directly in On My iPhone or iPad → KartPad, then try again."
           completion:^{ [self showOptions]; }];
    return;
  }
  if (roots.count == 1) {
    [self startImport:roots.firstObject];
    return;
  }
  UIAlertController *choices =
      [UIAlertController alertControllerWithTitle:@"Choose Game Data"
                                          message:@"Select an extracted RMCP01 folder."
                                   preferredStyle:UIAlertControllerStyleAlert];
  for (NSURL *root in roots) {
    [choices addAction:[UIAlertAction actionWithTitle:root.lastPathComponent
                                                style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction *action) {
      (void)action;
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                   (int64_t)(0.35 * NSEC_PER_SEC)),
                     dispatch_get_main_queue(), ^{ [self startImport:root]; });
    }]];
  }
  [choices addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
    (void)action;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(0.35 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ [self showOptions]; });
  }]];
  [self.root presentViewController:choices animated:YES completion:nil];
}

- (void)showOptions {
  UIAlertController *options =
      [UIAlertController alertControllerWithTitle:@"Game Data Required"
          message:@"KartPad does not include Mario Kart Wii. Import your own extracted RMCP01 DATA folder to continue."
          preferredStyle:UIAlertControllerStyleAlert];
  [options addAction:[UIAlertAction actionWithTitle:@"Choose Extracted DATA Folder…"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
    (void)action;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(0.35 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
      UIDocumentPickerViewController *picker =
          [[UIDocumentPickerViewController alloc]
              initForOpeningContentTypes:@[UTTypeFolder] asCopy:NO];
      picker.delegate = self;
      picker.allowsMultipleSelection = NO;
      [self.root presentViewController:picker animated:YES completion:nil];
    });
  }]];
  [options addAction:[UIAlertAction actionWithTitle:@"Import from KartPad Folder"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
    (void)action;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(0.35 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ [self chooseDocumentsRoot]; });
  }]];
  [self.root presentViewController:options animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
    didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
  (void)controller;
  NSURL *url = urls.firstObject;
  if (url != nil) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(0.35 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ [self startImport:url]; });
  } else {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(0.35 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ [self showOptions]; });
  }
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
  (void)controller;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                               (int64_t)(0.35 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{ [self showOptions]; });
}

- (BOOL)run {
  NSError *removalError = KartPadApplyScheduledGameDataRemoval();
  if (removalError != nil) {
    NSLog(@"[KartPad] scheduled game-data removal failed: %@",
          removalError.localizedDescription);
  }
  if (removalError == nil && KartPadInstalledGameDataIsValid()) {
    return YES;
  }
  UIWindowScene *scene = [self availableWindowScene];
  if (scene == nil) {
    NSLog(@"[KartPad] no UIWindowScene is available for first-launch import");
    return NO;
  }
  self.root = [[KartPadFirstLaunchViewController alloc] init];
  self.window = [[UIWindow alloc] initWithWindowScene:scene];
  self.window.windowLevel = UIWindowLevelAlert + 1.0;
  self.window.rootViewController = self.root;
  [self.window makeKeyAndVisible];
  if (removalError != nil) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self showMessage:@"Game Data Removal Failed"
                 detail:removalError.localizedDescription completion:^{
        self.finished = YES;
        self.succeeded = NO;
      }];
    });
  } else {
    dispatch_async(dispatch_get_main_queue(), ^{ [self showOptions]; });
  }
  while (!self.finished) {
    @autoreleasepool {
      [NSRunLoop.currentRunLoop runMode:NSDefaultRunLoopMode
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    }
  }
  self.window.hidden = YES;
  self.window = nil;
  return self.succeeded;
}

@end

@implementation KartPadGameOverlay

- (void)toggleSettingsPanel {
  // Opening or closing a touch-modal must never leave a gameplay control held.
  // Keep this in KartPad's owner layer so the pinned SunPad snapshot remains
  // byte-identical to its upstream reference.
  [self clearTouchInput];
  [self resetKartPadControlAppearance];
  [super toggleSettingsPanel];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  UIButton *menuButton = nil;
  UIButton *leftShoulder = nil;
  UIButton *rightShoulder = nil;
  UIButton *gasButton = nil;
  for (UIView *candidate in self.subviews) {
    if (![candidate isKindOfClass:UIButton.class]) continue;
    UIButton *button = (UIButton *)candidate;
    if ([button.accessibilityLabel isEqualToString:@"Menu"]) menuButton = button;
    if ([button.accessibilityLabel isEqualToString:@"L"]) leftShoulder = button;
    if ([button.accessibilityLabel isEqualToString:@"R"]) rightShoulder = button;
    if ([button.accessibilityLabel isEqualToString:@"A"]) gasButton = button;
  }

  // Mario Kart's Classic R input is a normal digital shoulder button. Match
  // L exactly and suppress SunPad's Sunshine-specific pressure-fill artwork.
  if (leftShoulder != nil && rightShoulder != nil) {
    rightShoulder.bounds = CGRectMake(0.0, 0.0,
                                      CGRectGetWidth(leftShoulder.bounds),
                                      CGRectGetHeight(leftShoulder.bounds));
    rightShoulder.layer.cornerRadius =
        MIN(CGRectGetWidth(rightShoulder.bounds),
            CGRectGetHeight(rightShoulder.bounds)) * 0.5;
    rightShoulder.accessibilityHint = @"Drift, hop, brake, or reverse.";
    rightShoulder.accessibilityValue = @"Not pressed";
    for (CALayer *layer in rightShoulder.layer.sublayers) {
      if ([layer isKindOfClass:CAShapeLayer.class]) layer.hidden = YES;
    }
  }

  if (gasButton != nil && self.kartPadGasButton != gasButton) {
    self.kartPadGasButton = gasButton;
    self.kartPadGasRestColor = gasButton.backgroundColor;
    gasButton.accessibilityHint =
        @"Hold for one second to confirm continuous acceleration.";
    [gasButton addTarget:self action:@selector(kartPadGasDown:)
         forControlEvents:UIControlEventTouchDown];
    [gasButton addTarget:self action:@selector(kartPadGasUp:)
         forControlEvents:UIControlEventTouchUpInside |
                          UIControlEventTouchUpOutside |
                          UIControlEventTouchCancel];
#if TARGET_OS_SIMULATOR
    if (!self.kartPadGasHoldSelfTestStarted &&
        NSProcessInfo.processInfo.environment[@"KARTPAD_TOUCH_HOLD_SELF_TEST"] != nil) {
      self.kartPadGasHoldSelfTestStarted = YES;
      dispatch_async(dispatch_get_main_queue(), ^{
        [self kartPadGasDown:gasButton];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                     (int64_t)(30.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
          [self kartPadGasUp:gasButton];
        });
      });
    }
    if (!self.kartPadGasInputSelfTestStarted &&
        NSProcessInfo.processInfo.environment[@"KARTPAD_TOUCH_INPUT_SELF_TEST"] != nil) {
      self.kartPadGasInputSelfTestStarted = YES;
      dispatch_async(dispatch_get_main_queue(), ^{
        [gasButton sendActionsForControlEvents:UIControlEventTouchDown];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                     (int64_t)(1.1 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
          const SunPadInputState held =
              [[SunPadInputMixer sharedMixer] consumeMergedState];
          const KartPadClassicInputState heldClassic =
              kartpad::mobile::AdaptSunPadInput(held);
          const BOOL heldPassed =
              (heldClassic.buttons & kartpad::mobile::kClassicButtonA) != 0;
          gasButton.accessibilityValue = heldPassed
              ? @"Acceleration held · input verified"
              : @"Acceleration hold input test failed";
          NSLog(@"[KartPad] touch A hold self-test: %@ (classic=%08x)",
                heldPassed ? @"held pass" : @"held FAIL", heldClassic.buttons);
          [gasButton sendActionsForControlEvents:UIControlEventTouchUpInside];
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                       (int64_t)(0.1 * NSEC_PER_SEC)),
                         dispatch_get_main_queue(), ^{
            const SunPadInputState released =
                [[SunPadInputMixer sharedMixer] consumeMergedState];
            const KartPadClassicInputState releasedClassic =
                kartpad::mobile::AdaptSunPadInput(released);
            const BOOL releasePassed =
                (releasedClassic.buttons & kartpad::mobile::kClassicButtonA) == 0;
            gasButton.accessibilityHint = releasePassed
                ? @"Acceleration releases when your finger lifts. Input self-test passed."
                : @"Acceleration release input test failed.";
            NSLog(@"[KartPad] touch A release self-test: %@ (classic=%08x)",
                  releasePassed ? @"release pass" : @"release FAIL",
                  releasedClassic.buttons);
          });
        });
      });
    }
    if (!self.kartPadModalInputSelfTestStarted && menuButton != nil &&
        NSProcessInfo.processInfo.environment[@"KARTPAD_TOUCH_MODAL_SELF_TEST"] != nil) {
      self.kartPadModalInputSelfTestStarted = YES;
      dispatch_async(dispatch_get_main_queue(), ^{
        [gasButton sendActionsForControlEvents:UIControlEventTouchDown];
        const KartPadClassicInputState before = kartpad::mobile::AdaptSunPadInput(
            [[SunPadInputMixer sharedMixer] consumeMergedState]);
        [self toggleSettingsPanel];
        const KartPadClassicInputState after = kartpad::mobile::AdaptSunPadInput(
            [[SunPadInputMixer sharedMixer] consumeMergedState]);
        const BOOL passed =
            (before.buttons & kartpad::mobile::kClassicButtonA) != 0 &&
            (after.buttons & kartpad::mobile::kClassicButtonA) == 0;
        menuButton.accessibilityHint = passed
            ? @"Touch settings input-clear self-test passed."
            : @"Touch settings input-clear self-test failed.";
        NSLog(@"[KartPad] touch modal input self-test: %@ (before=%08x after=%08x)",
              passed ? @"pass" : @"FAIL", before.buttons, after.buttons);
        [self toggleSettingsPanel];
      });
    }
    if (!self.kartPadEditorUITestStarted && menuButton != nil &&
        NSProcessInfo.processInfo.environment[@"KARTPAD_TOUCH_EDITOR_UI_TEST"] != nil) {
      self.kartPadEditorUITestStarted = YES;
      NSString *mode =
          NSProcessInfo.processInfo.environment[@"KARTPAD_TOUCH_EDITOR_UI_TEST"];
      dispatch_async(dispatch_get_main_queue(), ^{
        [self toggleSettingsPanel];
        [self layoutIfNeeded];
        UIScrollView *scroll = KartPadScrollableSettingsView(self);
        if (scroll == nil) {
          menuButton.accessibilityHint =
              @"Touch editor lower-row test failed: settings scroll view missing.";
          NSLog(@"[KartPad] touch editor UI test: FAIL (scroll view missing)");
          return;
        }
        const CGFloat bottom = MAX(-scroll.adjustedContentInset.top,
            scroll.contentSize.height - CGRectGetHeight(scroll.bounds) +
                scroll.adjustedContentInset.bottom);
        [scroll setContentOffset:CGPointMake(scroll.contentOffset.x, bottom)
                       animated:NO];
        menuButton.accessibilityHint = @"Touch editor lower rows exposed.";
        NSLog(@"[KartPad] touch editor UI test: lower rows exposed (offset=%.1f)",
              bottom);
        if ([mode isEqualToString:@"move"]) {
          UISwitch *move = (UISwitch *)KartPadSubviewWithAccessibilityLabel(
              self, @"Move touch controls", UISwitch.class);
          if (move == nil) {
            NSLog(@"[KartPad] touch editor UI test: FAIL (move switch missing)");
            return;
          }
          [move setOn:YES animated:NO];
          [move sendActionsForControlEvents:UIControlEventValueChanged];
          UIButton *aButton = (UIButton *)KartPadSubviewWithAccessibilityLabel(
              self, @"A", UIButton.class);
          if (aButton != nil) [self selectControlForEditing:aButton];
          UISlider *aSize = (UISlider *)KartPadSubviewWithAccessibilityLabel(
              self, @"A size", UISlider.class);
          if (aSize != nil) {
            aSize.value = 1.25;
            [aSize sendActionsForControlEvents:UIControlEventValueChanged];
          }
          UIButton *done = (UIButton *)KartPadSubviewWithAccessibilityLabel(
              self, @"Finish moving touch controls", UIButton.class);
          const BOOL sizePersisted = std::fabs(
              [[SunPadSettings sharedSettings] sizeScaleForControl:@"A"] -
              1.25) < 0.001;
          const BOOL passed = done != nil && !done.hidden && aSize.enabled &&
                              sizePersisted;
          menuButton.accessibilityHint = passed
              ? @"Touch editor selected and resized A."
              : @"Touch editor move-mode test failed.";
          NSLog(@"[KartPad] touch editor UI test: move/resize %@ (A=%.2f)",
                passed ? @"pass" : @"FAIL",
                [[SunPadSettings sharedSettings] sizeScaleForControl:@"A"]);
        } else if ([mode isEqualToString:@"reset"]) {
          [[NSUserDefaults standardUserDefaults]
              setObject:@{@"A" : NSStringFromCGPoint(CGPointMake(0.5, 0.5))}
                 forKey:@"SunPadControlOrigins"];
          [[NSUserDefaults standardUserDefaults] synchronize];
          UIButton *reset = (UIButton *)KartPadSubviewWithAccessibilityLabel(
              self, @"Reset This Device Layout", UIButton.class);
          if (reset == nil) {
            NSLog(@"[KartPad] touch editor UI test: FAIL (reset button missing)");
            return;
          }
          [reset sendActionsForControlEvents:UIControlEventTouchUpInside];
          NSLog(@"[KartPad] touch editor UI test: reset confirmation opened");
        }
      });
    }
#endif
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
  UIAction *motionSteering =
      [UIAction actionWithTitle:@"Motion Steering…"
                          image:[UIImage systemImageNamed:@"gyroscope"]
                     identifier:@"dev.kartpad.motion-steering"
                        handler:^(__kindof UIAction *action) {
                          (void)action;
                          if (weakSelf.motionSteeringRequested != nil) {
                            weakSelf.motionSteeringRequested();
                          }
                        }];
  UIAction *(^unsupportedExperiment)(UIAction *, NSString *) =
      ^UIAction *(UIAction *sourceAction, NSString *detail) {
        UIAction *replacement =
            [UIAction actionWithTitle:sourceAction.title
                                image:sourceAction.image
                           identifier:sourceAction.identifier
                              handler:^(__kindof UIAction *action) {
          (void)action;
          UIAlertController *alert =
              [UIAlertController alertControllerWithTitle:@"Unavailable in KartPad"
                                                  message:detail
                                           preferredStyle:UIAlertControllerStyleAlert];
          [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                    style:UIAlertActionStyleDefault
                                                  handler:nil]];
          [weakSelf.window.rootViewController presentViewController:alert
                                                           animated:YES
                                                         completion:nil];
        }];
        replacement.state = UIMenuElementStateOff;
        return replacement;
      };
  NSMutableArray<UIMenuElement *> *children =
      [NSMutableArray arrayWithObjects:multiplayer, motionSteering, nil];
  for (UIMenuElement *element in sourceMenu.children) {
    if ([element isKindOfClass:UIAction.class]) {
      UIAction *action = (UIAction *)element;
      if ([action.title isEqualToString:
              @"Experimental Performance Mode (Restart Required)"]) {
        [children addObject:unsupportedExperiment(action,
            @"This SunPad experiment changes Sunshine's emulated CPU clock. "
             "KartPad's ahead-of-time Mario Kart Wii runtime does not expose "
             "that clock mode, so stable real-time timing remains active and "
             "no setting was changed.")];
        continue;
      }
      if ([action.title isEqualToString:
              @"Experimental 60 FPS (Restart Required)"]) {
        [children addObject:unsupportedExperiment(action,
            @"This SunPad experiment targets Sunshine's GMSE01 patch. It is "
             "not compatible with KartPad's Mario Kart Wii runtime, so the "
             "retail cadence remains active and no setting was changed.")];
        continue;
      }
    }
    [children addObject:element];
  }
  menuButton.menu = [UIMenu menuWithTitle:@"KartPad"
                                    image:sourceMenu.image
                               identifier:@"dev.kartpad.menu"
                                  options:sourceMenu.options
                                 children:children];
}

- (void)rPressureChanged:(uint8_t)pressure fullPress:(BOOL)fullPress {
  (void)fullPress;
  const BOOL pressed = pressure > 0;
  [super rPressureChanged:pressed ? 255 : 0 fullPress:pressed];
}

- (void)kartPadGasDown:(UIButton *)button {
  self.kartPadGasPressed = YES;
  const NSUInteger generation = ++self.kartPadGasHoldGeneration;
  __weak KartPadGameOverlay *weakSelf = self;
  __weak UIButton *weakButton = button;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)NSEC_PER_SEC),
                 dispatch_get_main_queue(), ^{
    KartPadGameOverlay *strongSelf = weakSelf;
    UIButton *strongButton = weakButton;
    if (strongSelf == nil || strongButton == nil ||
        !strongSelf.kartPadGasPressed ||
        strongSelf.kartPadGasHoldGeneration != generation) {
      return;
    }
    // SunPad already keeps A asserted from touch-down through touch-up. The
    // delayed treatment makes that sustained acceleration state unmistakable.
    strongButton.backgroundColor =
        [UIColor colorWithRed:0.06 green:0.78 blue:0.92 alpha:0.98];
    strongButton.layer.borderColor = UIColor.whiteColor.CGColor;
    strongButton.layer.shadowColor =
        [UIColor colorWithRed:0.06 green:0.78 blue:0.92 alpha:1.0].CGColor;
    strongButton.layer.shadowOpacity = 0.9;
    strongButton.layer.shadowRadius = 9.0;
    strongButton.layer.shadowOffset = CGSizeZero;
    strongButton.accessibilityValue = @"Acceleration held";
    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc]
        initWithStyle:UIImpactFeedbackStyleLight];
    [feedback impactOccurred];
  });
}

- (void)kartPadGasUp:(UIButton *)button {
  self.kartPadGasPressed = NO;
  ++self.kartPadGasHoldGeneration;
  button.backgroundColor = self.kartPadGasRestColor;
  button.layer.borderColor =
      [UIColor colorWithWhite:1.0 alpha:0.36].CGColor;
  button.layer.shadowOpacity = 0.0;
  button.accessibilityValue = nil;
}

- (void)resetKartPadControlAppearance {
  self.kartPadGasPressed = NO;
  ++self.kartPadGasHoldGeneration;
  if (self.kartPadGasButton != nil) {
    self.kartPadGasButton.backgroundColor = self.kartPadGasRestColor;
    self.kartPadGasButton.layer.borderColor =
        [UIColor colorWithWhite:1.0 alpha:0.36].CGColor;
    self.kartPadGasButton.layer.shadowOpacity = 0.0;
    self.kartPadGasButton.accessibilityValue = nil;
  }
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
  overlay.motionSteeringRequested = ^{
    [weakSelf showMotionSteering];
  };
  _overlay = overlay;
  _overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                              UIViewAutoresizingFlexibleHeight;
  _overlay.backgroundColor = UIColor.clearColor;
  _overlay.delegate = self;
  [container addSubview:_overlay];
  [container bringSubviewToFront:_overlay];
  [[KartPadPhysicalControllers sharedControllers] start];
  [[KartPadMotionSteering sharedSteering] start];

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

- (void)showMotionSteering {
  [[SunPadInputMixer sharedMixer] clearInputFromTouch:YES];
  UIViewController *controller = KartPadVisibleViewController(_window);
  if (controller == nil) return;
  KartPadMotionSteering *motion = [KartPadMotionSteering sharedSteering];
  NSString *status = motion.sensorAvailable
      ? [NSString stringWithFormat:
            @"Tilt the device like a steering wheel. Current state: %@. Sensitivity: %.1fx. Physical controllers take priority.",
            motion.enabled ? @"On" : @"Off", motion.sensitivity]
      : @"Motion data is unavailable on this device or Simulator. Touch and physical-controller steering remain available.";
  UIAlertController *sheet =
      [UIAlertController alertControllerWithTitle:@"Motion Steering"
                                          message:status
                                   preferredStyle:UIAlertControllerStyleActionSheet];
  if (motion.sensorAvailable) {
    [sheet addAction:[UIAlertAction
        actionWithTitle:motion.enabled ? @"Turn Off" : @"Turn On & Recenter"
                    style:UIAlertActionStyleDefault
                  handler:^(UIAlertAction *action) {
      (void)action;
      motion.enabled = !motion.enabled;
      if (motion.enabled) [motion recenter];
    }]];
    if (motion.enabled) {
      [sheet addAction:[UIAlertAction actionWithTitle:@"Recenter Now"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
        (void)action;
        [motion recenter];
      }]];
    }
    [sheet addAction:[UIAlertAction
        actionWithTitle:motion.inverted ? @"Use Standard Direction" : @"Invert Direction"
                    style:UIAlertActionStyleDefault
                  handler:^(UIAlertAction *action) {
      (void)action;
      motion.inverted = !motion.inverted;
    }]];
    [sheet addAction:[UIAlertAction
        actionWithTitle:@"Cycle Sensitivity"
                    style:UIAlertActionStyleDefault
                  handler:^(UIAlertAction *action) {
      (void)action;
      const float current = motion.sensitivity;
      motion.sensitivity = current < 0.75f ? 1.0f : (current < 1.5f ? 2.0f : 0.5f);
    }]];
  }
  [sheet addAction:[UIAlertAction actionWithTitle:@"Continue Playing"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];
  UIPopoverPresentationController *popover = sheet.popoverPresentationController;
  popover.sourceView = _overlay;
  popover.sourceRect = CGRectMake(CGRectGetMidX(_overlay.bounds),
                                  CGRectGetMidY(_overlay.bounds), 1.0, 1.0);
  [controller presentViewController:sheet animated:YES completion:nil];
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
  [[KartPadMotionSteering sharedSteering] stop];
  [[SunPadInputMixer sharedMixer] clearInputFromTouch:YES];
  if ([_overlay isKindOfClass:KartPadGameOverlay.class]) {
    [(KartPadGameOverlay *)_overlay resetKartPadControlAppearance];
  }
  _overlay.delegate = nil;
  [_overlay removeFromSuperview];
  _overlay = nil;
}

- (void)applicationWillResignActive:(NSNotification *)notification {
  (void)notification;
  [[SunPadInputMixer sharedMixer] clearInputFromTouch:YES];
  if ([_overlay isKindOfClass:KartPadGameOverlay.class]) {
    [(KartPadGameOverlay *)_overlay resetKartPadControlAppearance];
  }
  [[KartPadMotionSteering sharedSteering] stop];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
  (void)notification;
  [[KartPadPhysicalControllers sharedControllers] reconcileControllers];
  [[KartPadMotionSteering sharedSteering] start];
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
    NSError *workError = KartPadPerformGameDataImport(url);

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
  [[SunPadInputMixer sharedMixer] clearInputFromTouch:YES];
  NSString *supportRoot = KartPadSupportRoot();
  NSError *error = nil;
  [NSFileManager.defaultManager createDirectoryAtPath:supportRoot
                          withIntermediateDirectories:YES
                                           attributes:@{NSFileProtectionKey:
      NSFileProtectionCompleteUntilFirstUserAuthentication}
                                                error:&error];
  if (error == nil) {
    [@"remove-on-next-launch\n" writeToFile:KartPadRemovalMarkerPath()
                                   atomically:YES encoding:NSUTF8StringEncoding
                                      error:&error];
  }
  if (error != nil) {
    [self showIntegrationAlert:@"Game Data Removal Failed"
                       message:error.localizedDescription];
    return;
  }

  UIViewController *controller = KartPadVisibleViewController(_window);
  if (controller == nil) {
    [NSFileManager.defaultManager removeItemAtPath:KartPadRemovalMarkerPath()
                                             error:nil];
    return;
  }
  __weak KartPadRuntimeOverlayHost *weakSelf = self;
  UIAlertController *alert = [UIAlertController
      alertControllerWithTitle:@"Game Data Removal Scheduled"
                       message:@"KartPad will remove the private game-data copy before emulation starts on the next launch. Saves and control settings are not affected."
                preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"Undo"
                                             style:UIAlertActionStyleCancel
                                           handler:^(UIAlertAction *action) {
    (void)action;
    NSError *undoError = nil;
    if (![NSFileManager.defaultManager removeItemAtPath:KartPadRemovalMarkerPath()
                                                  error:&undoError]) {
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                   (int64_t)(0.35 * NSEC_PER_SEC)),
                     dispatch_get_main_queue(), ^{
        [weakSelf showIntegrationAlert:@"Undo Failed"
                               message:undoError.localizedDescription];
      });
    }
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                             style:UIAlertActionStyleDefault
                                           handler:nil]];
  [controller presentViewController:alert animated:YES completion:nil];
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

extern "C" bool KartPadMobileEnsureGameDataAvailable() {
  if (!NSThread.isMainThread) {
    __block BOOL available = NO;
    dispatch_sync(dispatch_get_main_queue(), ^{
      available = [[[KartPadFirstLaunchHost alloc] init] run];
    });
    return available;
  }
  return [[[KartPadFirstLaunchHost alloc] init] run];
}

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
  KartPadClassicInputState adapted =
      kartpad::mobile::AdaptSunPadInput(source);
  if (player == 0 &&
      [KartPadPhysicalControllers sharedControllers].connectedControllerCount == 0) {
    const float motion = [KartPadMotionSteering sharedSteering].currentSteering;
    const int motionStick = static_cast<int>(std::lround(motion * 127.0f));
    if (std::abs(motionStick) > std::abs(static_cast<int>(adapted.leftStickX))) {
      adapted.leftStickX = static_cast<std::int8_t>(
          std::clamp(motionStick, -127, 127));
    }
  }
  snapshot->buttons = adapted.buttons;
  snapshot->leftStickX = std::clamp(static_cast<float>(adapted.leftStickX) / 127.0f,
                                   -1.0f, 1.0f);
  snapshot->leftStickY = std::clamp(static_cast<float>(adapted.leftStickY) / 127.0f,
                                   -1.0f, 1.0f);
  snapshot->connected = adapted.connected ? 1 : 0;
  return true;
}
