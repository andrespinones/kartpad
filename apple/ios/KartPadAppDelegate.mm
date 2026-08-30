#import <UIKit/UIKit.h>

#import "KartPadShellViewController.h"
#import "SunPadDiagnostics.h"

@interface KartPadAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@end

@implementation KartPadAppDelegate

- (UIInterfaceOrientationMask)application:(UIApplication *)application
    supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    (void)application;
    (void)window;
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    (void)application;
    (void)launchOptions;
    SunPadDiagnosticsStart();
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [[KartPadShellViewController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    (void)application;
    [(KartPadShellViewController *)self.window.rootViewController clearTransientInput];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    (void)application;
    [(KartPadShellViewController *)self.window.rootViewController resumeAfterForeground];
}

@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil,
                                 NSStringFromClass(KartPadAppDelegate.class));
    }
}
