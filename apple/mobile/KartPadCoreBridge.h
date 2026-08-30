#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Runs a bounded, content-free check through the same host, guest-memory,
// scheduler, and translated-code libraries linked into the mobile app.
NSString *KartPadCoreIntegrationSummary(void);

NS_ASSUME_NONNULL_END
