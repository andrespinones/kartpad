#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^KartPadDiscExtractionProgress)(NSString *status, double fraction);

// KartPad-owned adaptation of SunPad's pinned DiscIO extraction boundary.
// The synchronous entry point is called from the import worker queue so the
// existing staging/validation/rollback transaction remains one operation.
@interface KartPadDiscExtractor : NSObject

+ (BOOL)extractImageAtPath:(NSString *)imagePath
               toDirectory:(NSString *)destination
                   progress:(nullable KartPadDiscExtractionProgress)progress
                      error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
