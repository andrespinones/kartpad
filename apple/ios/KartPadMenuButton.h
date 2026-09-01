#pragma once

#import <UIKit/UIKit.h>

NS_INLINE UIButton *KartPadFindMenuButton(UIView *root) {
    if ([root isKindOfClass:UIButton.class] &&
        [root.accessibilityLabel isEqualToString:@"Menu"]) {
        return (UIButton *)root;
    }
    for (UIView *child in root.subviews) {
        UIButton *button = KartPadFindMenuButton(child);
        if (button != nil)
            return button;
    }
    return nil;
}

NS_INLINE void KartPadConfigureMenuButton(UIButton *button) {
    if (button == nil || button.configuration != nil)
        return;

    UIImage *image = [button imageForState:UIControlStateNormal];
    UIButtonConfiguration *configuration =
        [UIButtonConfiguration plainButtonConfiguration];
    configuration.image = image;
    configuration.baseForegroundColor = UIColor.whiteColor;
    configuration.contentInsets = NSDirectionalEdgeInsetsZero;
    configuration.cornerStyle = UIButtonConfigurationCornerStyleCapsule;

    UIBackgroundConfiguration *background =
        [UIBackgroundConfiguration clearConfiguration];
    background.backgroundColor = [UIColor colorWithWhite:0.06 alpha:0.72];
    background.cornerRadius = 20.0;
    background.strokeColor = [UIColor colorWithWhite:1.0 alpha:0.30];
    background.strokeWidth = 1.0;
    configuration.background = background;

    // Keep UIKit's context-menu transition on one explicit appearance instead
    // of synthesizing a rectangular selected-state preview during dismissal.
    button.automaticallyUpdatesConfiguration = NO;
    button.configuration = configuration;
    button.backgroundColor = UIColor.clearColor;
    button.layer.borderWidth = 0.0;
}
