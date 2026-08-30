#import "KartPadMacShell.h"

#import <AppKit/AppKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

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
@end

@implementation KartPadMacShellController

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
