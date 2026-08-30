#import "KartPadMacShell.h"

#import <AppKit/AppKit.h>
#import <CommonCrypto/CommonDigest.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#include <SDL3/SDL_events.h>
#include <SDL3/SDL_keycode.h>
#include <SDL3/SDL_scancode.h>

#include "runtime_config.h"

static constexpr NSInteger kKartPadMenuTag = 0x4b505344;

static NSURL *ApplicationSupportURL() {
  return [NSURL fileURLWithPath:[NSHomeDirectory()
      stringByAppendingPathComponent:@"Library/Application Support/KartPad"]
                       isDirectory:YES];
}

static NSURL *CacheURL() {
  return [NSURL fileURLWithPath:[NSHomeDirectory()
      stringByAppendingPathComponent:@"Library/Caches/KartPad"]
                       isDirectory:YES];
}

static NSString *YesNo(BOOL value) { return value ? @"yes" : @"no"; }

static NSString *SHA256ForFile(NSString *path, NSError **error) {
  NSData *data = [NSData dataWithContentsOfFile:path
                                       options:NSDataReadingMappedIfSafe
                                         error:error];
  if (data == nil || data.length > UINT32_MAX) return nil;
  unsigned char digest[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256(data.bytes, static_cast<CC_LONG>(data.length), digest);
  NSMutableString *result =
      [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
  for (NSUInteger index = 0; index < CC_SHA256_DIGEST_LENGTH; ++index) {
    [result appendFormat:@"%02x", digest[index]];
  }
  return result;
}

static NSString *ResolvedExtractedRoot(NSURL *selectedURL) {
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
        [files fileExistsAtPath:
            [candidate stringByAppendingPathComponent:@"sys/fst.bin"]]) {
      return candidate;
    }
  }
  return nil;
}

static NSString *ValidateExtractedRoot(NSString *root, NSError **error) {
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
      return [NSString stringWithFormat:
          @"The extracted game data is incomplete (missing %@).", relative];
    }
  }

  NSData *boot = [NSData dataWithContentsOfFile:
      [root stringByAppendingPathComponent:@"sys/boot.bin"]
                                             options:0
                                               error:error];
  if (boot == nil) return @"KartPad could not read sys/boot.bin.";
  if (boot.length < 0x20) return @"The selected sys/boot.bin is truncated.";
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

  NSString *hash = SHA256ForFile(
      [root stringByAppendingPathComponent:@"sys/main.dol"], error);
  if (hash == nil) return @"KartPad could not hash sys/main.dol.";
  if (![hash isEqualToString:
      @"80d18895b39c63bd80f457398bfcbb91b7d16ac116a41a88967e954080155b05"]) {
    return @"sys/main.dol does not match the supported RMCP01 revision 0 profile.";
  }
  return nil;
}

static NSString *ConfiguredGameDataRoot() {
  const RuntimeUserConfig config = RuntimeConfigFile::LoadConfigFile();
  if (!config.dvdRoot || config.dvdRoot->empty()) return nil;
  std::filesystem::path root(*config.dvdRoot);
  if (root.is_relative()) root = RuntimeConfigFile::ResolveConfigPath().parent_path() / root;
  return [NSString stringWithUTF8String:root.lexically_normal().string().c_str()];
}

static BOOL WriteGameDataRoot(NSString *root) {
  if (root.length == 0) return NO;
  const bool wrote = RuntimeConfigFile::WriteSetting(
      "paths", "dvd_root",
      RuntimeConfigFile::FormatString(root.fileSystemRepresentation));
  if (wrote) RuntimeConfigFile::Reload();
  return wrote;
}

static NSString *ChooseAndValidateGameData() {
  NSOpenPanel *panel = NSOpenPanel.openPanel;
  panel.title = @"Choose Extracted Mario Kart Wii Data";
  panel.message = @"Choose your own extracted RMCP01 DATA folder containing files/ and sys/.";
  panel.prompt = @"Choose Game Data";
  panel.canChooseFiles = NO;
  panel.canChooseDirectories = YES;
  panel.allowsMultipleSelection = NO;
  if ([panel runModal] != NSModalResponseOK || panel.URL == nil) return nil;

  NSError *error = nil;
  NSString *root = ResolvedExtractedRoot(panel.URL);
  NSString *validation = ValidateExtractedRoot(root, &error);
  if (validation == nil && error == nil) return root;

  NSAlert *alert = [NSAlert new];
  alert.messageText = @"Unsupported Game Data";
  alert.informativeText = error.localizedDescription.length > 0
      ? error.localizedDescription : validation;
  [alert runModal];
  return @"";
}

static NSString *DiagnosticsReport() {
  NSFileManager *files = NSFileManager.defaultManager;
  NSURL *support = ApplicationSupportURL();
  NSURL *cache = CacheURL();
  NSURL *config = [support URLByAppendingPathComponent:@"Config.toml"];
  NSURL *save = [support
      URLByAppendingPathComponent:
          @"NAND/title/00010004/524d4350/data/rksys.dat"];
  NSBundle *bundle = NSBundle.mainBundle;
  NSString *version =
      [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
  if (version.length == 0) version = @"unknown";
  NSString *build = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
  if (build.length == 0) build = @"unknown";
  NSString *generated = [NSISO8601DateFormatter stringFromDate:NSDate.date
                                                     timeZone:NSTimeZone.localTimeZone
                                                formatOptions:NSISO8601DateFormatWithInternetDateTime];
  return [NSString stringWithFormat:
      @"KartPad diagnostics\n"
       "schema=1\n"
       "generated=%@\n"
       "appVersion=%@\n"
       "appBuild=%@\n"
       "os=%@\n"
       "architecture=arm64\n"
       "applicationSupportExists=%@\n"
       "cacheExists=%@\n"
       "configExists=%@\n"
       "saveExists=%@\n"
       "privacy=paths, game data, save contents, credentials, and logs omitted\n",
      generated, version, build, NSProcessInfo.processInfo.operatingSystemVersionString,
      YesNo([files fileExistsAtPath:support.path]),
      YesNo([files fileExistsAtPath:cache.path]),
      YesNo([files fileExistsAtPath:config.path]),
      YesNo([files fileExistsAtPath:save.path])];
}

@interface KartPadMacShellController : NSObject
@property(nonatomic, strong) NSPanel *settingsPanel;
@property(nonatomic, strong) NSPopUpButton *resolutionMenu;
@property(nonatomic, strong) NSPopUpButton *displayModeMenu;
@property(nonatomic, strong) NSButton *showFpsCheckbox;
@property(nonatomic, strong) NSButton *muteCheckbox;
@property(nonatomic, strong) NSSlider *volumeSlider;
@property(nonatomic, strong) NSTextField *volumeValue;
@end

@implementation KartPadMacShellController

- (void)quitKartPad:(id)sender {
  for (NSWindow *window in NSApp.windows) {
    if (![window isKindOfClass:NSPanel.class] && window.isVisible) {
      // Let Aurora observe the native close event. Its window-close path
      // flushes placement state and exits without running C++ teardown from a
      // translated guest fiber.
      [window performClose:sender];
      return;
    }
  }
  [NSApp terminate:sender];
}

- (void)chooseGameData:(id)sender {
  (void)sender;
  NSString *root = ChooseAndValidateGameData();
  if (root == nil || root.length == 0) return;
  if (!WriteGameDataRoot(root)) {
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Game Data Could Not Be Saved";
    alert.informativeText = @"KartPad could not update Config.toml.";
    [alert runModal];
    return;
  }
  NSAlert *alert = [NSAlert new];
  alert.messageText = @"Game Data Ready";
  alert.informativeText =
      @"KartPad validated the RMCP01 data. Quit and reopen KartPad to use it.";
  [alert runModal];
}

- (void)showControllerSettings:(id)sender {
  (void)sender;
  [NSApp activateIgnoringOtherApps:YES];
  for (NSWindow *window in NSApp.windows) {
    if (![window isKindOfClass:NSPanel.class] && window.isVisible) {
      [window makeKeyAndOrderFront:nil];
      break;
    }
  }

  SDL_Event event{};
  event.type = SDL_EVENT_KEY_DOWN;
  event.key.scancode = SDL_SCANCODE_F10;
  event.key.key = SDLK_F10;
  event.key.down = true;
  if (!SDL_PushEvent(&event)) return;
  event.type = SDL_EVENT_KEY_UP;
  event.key.type = SDL_EVENT_KEY_UP;
  event.key.down = false;
  SDL_PushEvent(&event);
}

- (NSTextField *)label:(NSString *)text {
  NSTextField *label = [NSTextField labelWithString:text];
  label.font = [NSFont systemFontOfSize:NSFont.systemFontSize];
  return label;
}

- (NSStackView *)rowWithLabel:(NSString *)label control:(NSView *)control {
  NSTextField *title = [self label:label];
  [title.widthAnchor constraintEqualToConstant:122.0].active = YES;
  NSStackView *row = [NSStackView stackViewWithViews:@[title, control]];
  row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  row.alignment = NSLayoutAttributeCenterY;
  row.spacing = 12.0;
  return row;
}

- (void)updateVolumeValue:(id)sender {
  (void)sender;
  self.volumeValue.stringValue =
      [NSString stringWithFormat:@"%ld%%", self.volumeSlider.integerValue];
}

- (void)closeSettings:(id)sender {
  (void)sender;
  [self.settingsPanel orderOut:nil];
}

- (void)saveSettings:(id)sender {
  (void)sender;
  static constexpr float kResolutionValues[] = {0.0f, 1.0f, 1.5f, 2.0f,
                                                 3.0f, 4.0f};
  static constexpr const char *kDisplayModeValues[] = {
      "windowed", "borderless", "exclusive"};
  const NSInteger resolutionIndex = self.resolutionMenu.indexOfSelectedItem;
  const NSInteger displayIndex = self.displayModeMenu.indexOfSelectedItem;
  if (resolutionIndex < 0 || resolutionIndex >= 6 || displayIndex < 0 ||
      displayIndex >= 3) {
    return;
  }

  std::ostringstream resolution;
  resolution << kResolutionValues[resolutionIndex];
  std::ostringstream volume;
  volume << std::clamp(static_cast<float>(self.volumeSlider.doubleValue) / 100.0f,
                       0.0f, 1.0f);
  const bool wroteResolution = RuntimeConfigFile::WriteSetting(
      "video", "resolution_multiplier", resolution.str());
  const bool wroteDisplay = RuntimeConfigFile::WriteSetting(
      "video", "display_mode",
      RuntimeConfigFile::FormatString(kDisplayModeValues[displayIndex]));
  const bool wroteFps = RuntimeConfigFile::WriteSetting(
      "video", "show_fps",
      self.showFpsCheckbox.state == NSControlStateValueOn ? "true" : "false");
  const bool wroteVolume =
      RuntimeConfigFile::WriteSetting("audio", "volume", volume.str());
  const bool wroteMute = RuntimeConfigFile::WriteSetting(
      "audio", "muted",
      self.muteCheckbox.state == NSControlStateValueOn ? "true" : "false");

  if (!(wroteResolution && wroteDisplay && wroteFps && wroteVolume && wroteMute)) {
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Settings Could Not Be Saved";
    alert.informativeText =
        @"KartPad could not update Config.toml. Your previous settings remain available.";
    [alert beginSheetModalForWindow:self.settingsPanel completionHandler:nil];
    return;
  }
  [self.settingsPanel orderOut:nil];
}

- (void)showSettings:(id)sender {
  (void)sender;
  const RuntimeUserConfig config = RuntimeConfigFile::LoadConfigFile();
  if (self.settingsPanel == nil) {
    self.settingsPanel = [[NSPanel alloc]
        initWithContentRect:NSMakeRect(0, 0, 470, 312)
                  styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable)
                    backing:NSBackingStoreBuffered
                      defer:NO];
    self.settingsPanel.title = @"KartPad Settings";
    self.settingsPanel.releasedWhenClosed = NO;

    self.resolutionMenu = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    [self.resolutionMenu addItemsWithTitles:@[
      @"Auto (Window Size)", @"Native (1×)", @"1.5×", @"2×", @"3×", @"4×"
    ]];
    self.resolutionMenu.accessibilityLabel = @"Render Resolution";

    self.displayModeMenu = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    [self.displayModeMenu addItemsWithTitles:@[
      @"Windowed", @"Borderless Fullscreen", @"Exclusive Fullscreen"
    ]];
    self.displayModeMenu.accessibilityLabel = @"Display Mode";

    self.showFpsCheckbox = [NSButton checkboxWithTitle:@"Show FPS counter"
                                               target:nil
                                               action:nil];
    self.muteCheckbox = [NSButton checkboxWithTitle:@"Mute game audio"
                                            target:nil
                                            action:nil];

    self.volumeSlider = [NSSlider sliderWithValue:100.0
                                        minValue:0.0
                                        maxValue:100.0
                                          target:self
                                          action:@selector(updateVolumeValue:)];
    self.volumeSlider.continuous = YES;
    self.volumeSlider.accessibilityLabel = @"Master Volume";
    [self.volumeSlider.widthAnchor constraintEqualToConstant:190.0].active = YES;
    self.volumeValue = [self label:@"100%"];
    [self.volumeValue.widthAnchor constraintEqualToConstant:42.0].active = YES;
    NSStackView *volumeControl =
        [NSStackView stackViewWithViews:@[self.volumeSlider, self.volumeValue]];
    volumeControl.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    volumeControl.spacing = 8.0;

    NSTextField *restart = [self label:
        @"Changes are saved safely and apply the next time KartPad launches."];
    restart.textColor = NSColor.secondaryLabelColor;
    restart.maximumNumberOfLines = 2;
    restart.lineBreakMode = NSLineBreakByWordWrapping;

    NSTextField *controller = [self label:
        @"Controller mappings remain available from Controller settings in the in-game F10 bar."];
    controller.textColor = NSColor.secondaryLabelColor;
    controller.maximumNumberOfLines = 2;
    controller.lineBreakMode = NSLineBreakByWordWrapping;

    NSButton *cancel = [NSButton buttonWithTitle:@"Cancel"
                                          target:self
                                          action:@selector(closeSettings:)];
    NSButton *save = [NSButton buttonWithTitle:@"Save Changes"
                                        target:self
                                        action:@selector(saveSettings:)];
    save.keyEquivalent = @"\r";
    NSView *buttonSpacer = [NSView new];
    NSStackView *buttons =
        [NSStackView stackViewWithViews:@[buttonSpacer, cancel, save]];
    buttons.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    buttons.alignment = NSLayoutAttributeCenterY;
    buttons.distribution = NSStackViewDistributionFill;
    buttons.spacing = 8.0;
    [buttonSpacer setContentHuggingPriority:NSLayoutPriorityDefaultLow
                            forOrientation:NSLayoutConstraintOrientationHorizontal];

    NSStackView *content = [NSStackView stackViewWithViews:@[
      [self rowWithLabel:@"Render resolution" control:self.resolutionMenu],
      [self rowWithLabel:@"Display mode" control:self.displayModeMenu],
      [self rowWithLabel:@"Overlay" control:self.showFpsCheckbox],
      [self rowWithLabel:@"Master volume" control:volumeControl],
      [self rowWithLabel:@"Audio" control:self.muteCheckbox],
      restart, controller, buttons
    ]];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    content.orientation = NSUserInterfaceLayoutOrientationVertical;
    content.alignment = NSLayoutAttributeLeading;
    content.spacing = 16.0;
    self.settingsPanel.contentView = [NSView new];
    [self.settingsPanel.contentView addSubview:content];
    [NSLayoutConstraint activateConstraints:@[
      [content.leadingAnchor constraintEqualToAnchor:self.settingsPanel.contentView.leadingAnchor
                                             constant:24.0],
      [content.trailingAnchor constraintEqualToAnchor:self.settingsPanel.contentView.trailingAnchor
                                              constant:-24.0],
      [content.topAnchor constraintEqualToAnchor:self.settingsPanel.contentView.topAnchor
                                         constant:24.0],
      [content.bottomAnchor constraintLessThanOrEqualToAnchor:self.settingsPanel.contentView.bottomAnchor
                                                      constant:-20.0],
      [restart.widthAnchor constraintEqualToAnchor:content.widthAnchor],
      [controller.widthAnchor constraintEqualToAnchor:content.widthAnchor],
      [buttons.widthAnchor constraintEqualToAnchor:content.widthAnchor]
    ]];
  }

  static constexpr float kResolutionValues[] = {0.0f, 1.0f, 1.5f, 2.0f,
                                                 3.0f, 4.0f};
  const float resolution = config.resolutionMultiplier.value_or(1.0f);
  NSInteger resolutionIndex = 1;
  for (NSInteger index = 0; index < 6; ++index) {
    if (std::fabs(resolution - kResolutionValues[index]) < 0.001f) {
      resolutionIndex = index;
      break;
    }
  }
  [self.resolutionMenu selectItemAtIndex:resolutionIndex];

  const std::string display = config.displayMode.value_or("windowed");
  [self.displayModeMenu selectItemAtIndex:
      display == "borderless" ? 1 : (display == "exclusive" ? 2 : 0)];
  self.showFpsCheckbox.state = config.showFps.value_or(true)
      ? NSControlStateValueOn : NSControlStateValueOff;
  self.muteCheckbox.state = config.audioMuted.value_or(false)
      ? NSControlStateValueOn : NSControlStateValueOff;
  self.volumeSlider.doubleValue =
      std::clamp(static_cast<double>(config.audioVolume.value_or(1.0f)) * 100.0,
                 0.0, 100.0);
  [self updateVolumeValue:nil];

  [self.settingsPanel center];
  [self.settingsPanel makeKeyAndOrderFront:nil];
  [NSApp activateIgnoringOtherApps:YES];
}

- (void)showApplicationSupport:(id)sender {
  (void)sender;
  NSURL *url = ApplicationSupportURL();
  [NSFileManager.defaultManager createDirectoryAtURL:url
                         withIntermediateDirectories:YES
                                          attributes:nil
                                               error:nil];
  [NSWorkspace.sharedWorkspace openURL:url];
}

- (void)showCache:(id)sender {
  (void)sender;
  NSURL *url = CacheURL();
  [NSFileManager.defaultManager createDirectoryAtURL:url
                         withIntermediateDirectories:YES
                                          attributes:nil
                                               error:nil];
  [NSWorkspace.sharedWorkspace openURL:url];
}

- (void)saveDiagnostics:(id)sender {
  (void)sender;
  NSSavePanel *panel = NSSavePanel.savePanel;
  panel.title = @"Save KartPad Diagnostics";
  panel.nameFieldStringValue = @"KartPad-Diagnostics.txt";
  panel.allowedContentTypes = @[UTTypePlainText];
  [panel beginWithCompletionHandler:^(NSModalResponse response) {
    if (response != NSModalResponseOK || panel.URL == nil) return;
    NSError *error = nil;
    if (![DiagnosticsReport() writeToURL:panel.URL
                              atomically:YES
                                encoding:NSUTF8StringEncoding
                                   error:&error]) {
      NSAlert *alert = [NSAlert new];
      alert.messageText = @"Diagnostics Could Not Be Saved";
      NSString *description = error.localizedDescription;
      alert.informativeText =
          description.length == 0 ? @"Unknown write error." : description;
      [alert runModal];
    }
  }];
}

@end

static KartPadMacShellController *Controller() {
  static KartPadMacShellController *controller;
  static dispatch_once_t once;
  dispatch_once(&once, ^{ controller = [KartPadMacShellController new]; });
  return controller;
}

static void InstallMenu() {
  NSMenu *mainMenu = NSApp.mainMenu;
  if (mainMenu == nil) {
    mainMenu = [NSMenu new];
    NSApp.mainMenu = mainMenu;
  }

  NSMenuItem *appItem = mainMenu.itemArray.firstObject;
  if (appItem == nil) {
    appItem = [[NSMenuItem alloc] initWithTitle:@"KartPad" action:nil keyEquivalent:@""];
    [mainMenu addItem:appItem];
  }
  NSMenu *appMenu = appItem.submenu;
  if (appMenu == nil) {
    appMenu = [[NSMenu alloc] initWithTitle:@"KartPad"];
    appItem.submenu = appMenu;
  }
  if ([appMenu itemWithTag:kKartPadMenuTag] != nil) return;

  bool hasStandardApplicationMenu = false;
  for (NSMenuItem *item in appMenu.itemArray) {
    if ([item.title hasPrefix:@"About "] ||
        item.action == @selector(orderFrontStandardAboutPanel:)) {
      hasStandardApplicationMenu = true;
      break;
    }
  }
  if (!hasStandardApplicationMenu) {
    [appMenu removeAllItems];

    NSMenuItem *about = [[NSMenuItem alloc]
        initWithTitle:@"About KartPad"
               action:@selector(orderFrontStandardAboutPanel:)
        keyEquivalent:@""];
    about.target = NSApp;
    [appMenu addItem:about];
    [appMenu addItem:NSMenuItem.separatorItem];

    NSMenuItem *settings = [[NSMenuItem alloc]
        initWithTitle:@"Settings…"
               action:@selector(showSettings:)
        keyEquivalent:@","];
    settings.target = Controller();
    [appMenu addItem:settings];
    [appMenu addItem:NSMenuItem.separatorItem];

    NSMenuItem *services = [[NSMenuItem alloc]
        initWithTitle:@"Services" action:nil keyEquivalent:@""];
    services.submenu = [[NSMenu alloc] initWithTitle:@"Services"];
    NSApp.servicesMenu = services.submenu;
    [appMenu addItem:services];
    [appMenu addItem:NSMenuItem.separatorItem];

    NSMenuItem *hide = [[NSMenuItem alloc]
        initWithTitle:@"Hide KartPad" action:@selector(hide:) keyEquivalent:@"h"];
    hide.target = NSApp;
    [appMenu addItem:hide];
    NSMenuItem *hideOthers = [[NSMenuItem alloc]
        initWithTitle:@"Hide Others"
               action:@selector(hideOtherApplications:)
        keyEquivalent:@"h"];
    hideOthers.keyEquivalentModifierMask =
        NSEventModifierFlagOption | NSEventModifierFlagCommand;
    hideOthers.target = NSApp;
    [appMenu addItem:hideOthers];
    NSMenuItem *showAll = [[NSMenuItem alloc]
        initWithTitle:@"Show All"
               action:@selector(unhideAllApplications:)
        keyEquivalent:@""];
    showAll.target = NSApp;
    [appMenu addItem:showAll];
    [appMenu addItem:NSMenuItem.separatorItem];

    NSMenuItem *quit = [[NSMenuItem alloc]
        initWithTitle:@"Quit KartPad"
               action:@selector(quitKartPad:)
        keyEquivalent:@"q"];
    quit.target = Controller();
    [appMenu addItem:quit];
  }

  for (NSMenuItem *item in appMenu.itemArray) {
    if ([item.title hasPrefix:@"Settings"] ||
        [item.title hasPrefix:@"Preferences"]) {
      item.target = Controller();
      item.action = @selector(showSettings:);
      item.enabled = YES;
    } else if (item.action == @selector(terminate:)) {
      item.target = Controller();
      item.action = @selector(quitKartPad:);
    }
  }

  NSInteger insertIndex = appMenu.numberOfItems;
  for (NSInteger index = 0; index < appMenu.numberOfItems; ++index) {
    if ([appMenu itemAtIndex:index].action == @selector(hide:)) {
      insertIndex = index;
      break;
    }
  }
  [appMenu insertItem:NSMenuItem.separatorItem atIndex:insertIndex++];
  NSMenuItem *data = [[NSMenuItem alloc]
      initWithTitle:@"Show KartPad Data"
             action:@selector(showApplicationSupport:)
      keyEquivalent:@""];
  data.target = Controller();
  data.tag = kKartPadMenuTag;
  [appMenu insertItem:data atIndex:insertIndex++];

  NSMenuItem *cache = [[NSMenuItem alloc]
      initWithTitle:@"Show KartPad Cache"
             action:@selector(showCache:)
      keyEquivalent:@""];
  cache.target = Controller();
  [appMenu insertItem:cache atIndex:insertIndex++];

  NSMenuItem *gameData = [[NSMenuItem alloc]
      initWithTitle:@"Choose Game Data…"
             action:@selector(chooseGameData:)
      keyEquivalent:@""];
  gameData.target = Controller();
  [appMenu insertItem:gameData atIndex:insertIndex++];

  NSMenuItem *controllerSettings = [[NSMenuItem alloc]
      initWithTitle:@"Controller Settings…"
             action:@selector(showControllerSettings:)
      keyEquivalent:@""];
  controllerSettings.target = Controller();
  [appMenu insertItem:controllerSettings atIndex:insertIndex++];

  NSString *diagnosticsTitle =
      [@"Save Diagnostics Report" stringByAppendingString:@"…"];
  NSMenuItem *diagnostics = [[NSMenuItem alloc]
      initWithTitle:diagnosticsTitle
             action:@selector(saveDiagnostics:)
      keyEquivalent:@""];
  diagnostics.target = Controller();
  [appMenu insertItem:diagnostics atIndex:insertIndex];
}

void KartPadMacShellInstall(void) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [NSApplication sharedApplication];
    InstallMenu();
  });
}

bool KartPadMacShellPrepareGameData(void) {
  @autoreleasepool {
    RuntimeConfigFile::EnsureConfigFile();
    NSError *error = nil;
    NSString *configured = ConfiguredGameDataRoot();
    if (ValidateExtractedRoot(configured, &error) == nil && error == nil) {
      return true;
    }

    NSApplication *app = [NSApplication sharedApplication];
    [app setActivationPolicy:NSApplicationActivationPolicyRegular];
    [app finishLaunching];
    [app activateIgnoringOtherApps:YES];
    NSMenu *temporaryMainMenu = nil;
    if (app.mainMenu == nil) {
      temporaryMainMenu = [NSMenu new];
      NSMenuItem *applicationItem =
          [[NSMenuItem alloc] initWithTitle:@"KartPad" action:nil keyEquivalent:@""];
      applicationItem.submenu = [[NSMenu alloc] initWithTitle:@"KartPad"];
      [temporaryMainMenu addItem:applicationItem];
      app.mainMenu = temporaryMainMenu;
    }
    auto finishFirstRunMenu = [&] {
      if (temporaryMainMenu != nil && app.mainMenu == temporaryMainMenu) {
        app.mainMenu = nil;
      }
    };
    dispatch_async(dispatch_get_main_queue(), ^{
      [NSApp activateIgnoringOtherApps:YES];
    });
    for (;;) {
      NSAlert *required = [NSAlert new];
      required.messageText = @"Game Data Required";
      required.informativeText =
          @"KartPad does not include Mario Kart Wii. Choose your own extracted RMCP01 DATA folder to continue. Disc-image extraction and translation remain part of the Mac self-build workflow.";
      [required addButtonWithTitle:@"Choose Extracted Folder…"];
      [required addButtonWithTitle:@"Quit"];
      if ([required runModal] != NSAlertFirstButtonReturn) {
        finishFirstRunMenu();
        return false;
      }

      NSString *root = ChooseAndValidateGameData();
      if (root == nil) {
        finishFirstRunMenu();
        return false;
      }
      if (root.length == 0) continue;
      if (WriteGameDataRoot(root)) {
        finishFirstRunMenu();
        return true;
      }

      NSAlert *writeError = [NSAlert new];
      writeError.messageText = @"Game Data Could Not Be Saved";
      writeError.informativeText = @"KartPad could not update Config.toml.";
      [writeError runModal];
    }
  }
}
