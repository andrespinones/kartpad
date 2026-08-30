#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KartPadShellViewController : UIViewController
- (void)clearTransientInput;
- (void)resumeAfterForeground;
@end

NS_ASSUME_NONNULL_END
