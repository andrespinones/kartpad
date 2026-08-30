#import "KartPadMacShell.h"

#import <AppKit/AppKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

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

  for (NSMenuItem *item in appMenu.itemArray) {
    if ([item.title hasPrefix:@"Settings"] ||
        [item.title hasPrefix:@"Preferences"]) {
      item.target = Controller();
      item.action = @selector(showSettings:);
      item.enabled = YES;
      break;
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
