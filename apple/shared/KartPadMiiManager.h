#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const KartPadMiiManagerErrorDomain;

NSArray<NSDictionary<NSString *, id> *> *KartPadMiiRecords(NSError **error);
BOOL KartPadStageMiiImport(NSData *miiData, NSString *_Nullable *_Nullable name,
                          NSError **error);
BOOL KartPadStageMiiRemoval(NSUInteger slot, NSError **error);
BOOL KartPadStagePlayerName(NSUInteger slot, NSString *name,
                           NSUInteger *_Nullable updatedLicenses,
                           NSError **error);
BOOL KartPadApplyPendingMiiDatabase(NSError **error);
BOOL KartPadHasPendingMiiChanges(void);

NS_ASSUME_NONNULL_END
