#import "KartPadMiiManager.h"

#include "kartpad/mii/mii_database.h"

#include <span>
#include <vector>

NSString *const KartPadMiiManagerErrorDomain = @"dev.kartpad.mii-manager";

namespace {

NSString *SupportRoot() {
  return [[NSHomeDirectory() stringByAppendingPathComponent:
      @"Library/Application Support"] stringByAppendingPathComponent:@"KartPad"];
}

NSString *DatabasePath() {
  return [SupportRoot() stringByAppendingPathComponent:
      @"NAND/shared2/menu/FaceLib/RFL_DB.dat"];
}

NSString *PendingPath() {
  return [SupportRoot() stringByAppendingPathComponent:@"PendingRFL_DB.dat"];
}

NSError *ManagerError(NSInteger code, const std::string& message) {
  NSString *description = [NSString stringWithUTF8String:message.c_str()];
  if (description.length == 0) description = @"Unknown Mii database error.";
  return [NSError errorWithDomain:KartPadMiiManagerErrorDomain code:code
                         userInfo:@{NSLocalizedDescriptionKey: description}];
}

NSData *ReadWorkingDatabase(NSError **error) {
  NSString *path = [NSFileManager.defaultManager fileExistsAtPath:PendingPath()]
      ? PendingPath() : DatabasePath();
  NSData *data = [NSData dataWithContentsOfFile:path
                                       options:NSDataReadingMappedIfSafe
                                         error:error];
  if (data == nil && error != nullptr && *error == nil) {
    *error = ManagerError(1,
        "No Mii database exists yet. Start Mario Kart Wii once, then try again.");
  }
  return data;
}

std::span<const uint8_t> Bytes(NSData *data) {
  return {static_cast<const uint8_t *>(data.bytes), data.length};
}

BOOL WritePending(std::vector<uint8_t>& database, NSError **error) {
  NSData *data = [NSData dataWithBytes:database.data() length:database.size()];
  if (![NSFileManager.defaultManager createDirectoryAtPath:SupportRoot()
                                withIntermediateDirectories:YES
                                                 attributes:nil error:error]) {
    return NO;
  }
  return [data writeToFile:PendingPath() options:NSDataWritingAtomic error:error];
}

BOOL ValidateData(NSData *data, NSError **error) {
  const auto validation = kartpad::mii::ValidateDatabase(Bytes(data));
  if (!validation) {
    if (error != nullptr) *error = ManagerError(2, validation.message);
    return NO;
  }
  return YES;
}

} // namespace

NSArray<NSDictionary<NSString *, id> *> *KartPadMiiRecords(NSError **error) {
  NSData *data = ReadWorkingDatabase(error);
  if (data == nil || !ValidateData(data, error)) return @[];

  NSMutableArray<NSDictionary<NSString *, id> *> *result = [NSMutableArray array];
  for (const auto& record : kartpad::mii::ListMiis(Bytes(data))) {
    NSString *name = [NSString stringWithUTF8String:record.name.c_str()];
    NSString *creator = [NSString stringWithUTF8String:record.creatorName.c_str()];
    [result addObject:@{
      @"slot": @(record.slot),
      @"name": name.length > 0 ? name : @"Unnamed Mii",
      @"creator": creator.length > 0 ? creator : @"Unknown",
      @"favoriteColor": @(record.favoriteColor),
      @"createId": @(record.createId),
    }];
  }
  return result;
}

BOOL KartPadStageMiiImport(NSData *miiData, NSString **name, NSError **error) {
  NSData *databaseData = ReadWorkingDatabase(error);
  if (databaseData == nil || !ValidateData(databaseData, error)) return NO;

  std::vector<uint8_t> database(
      static_cast<const uint8_t *>(databaseData.bytes),
      static_cast<const uint8_t *>(databaseData.bytes) + databaseData.length);
  const auto mii = Bytes(miiData);
  const auto result = kartpad::mii::ImportMii(database, mii);
  if (!result) {
    if (error != nullptr) *error = ManagerError(3, result.message);
    return NO;
  }
  if (name != nullptr) {
    const std::string decoded = kartpad::mii::ReadMiiName(mii, 0x02);
    *name = [NSString stringWithUTF8String:decoded.c_str()];
  }
  return WritePending(database, error);
}

BOOL KartPadStageMiiRemoval(NSUInteger slot, NSError **error) {
  NSData *databaseData = ReadWorkingDatabase(error);
  if (databaseData == nil || !ValidateData(databaseData, error)) return NO;

  std::vector<uint8_t> database(
      static_cast<const uint8_t *>(databaseData.bytes),
      static_cast<const uint8_t *>(databaseData.bytes) + databaseData.length);
  const auto result = kartpad::mii::RemoveMii(database, slot);
  if (!result) {
    if (error != nullptr) *error = ManagerError(4, result.message);
    return NO;
  }
  return WritePending(database, error);
}

BOOL KartPadApplyPendingMiiDatabase(NSError **error) {
  NSString *pending = PendingPath();
  if (![NSFileManager.defaultManager fileExistsAtPath:pending]) return YES;

  NSData *pendingData = [NSData dataWithContentsOfFile:pending
                                               options:NSDataReadingMappedIfSafe
                                                 error:error];
  if (pendingData == nil || !ValidateData(pendingData, error)) return NO;

  NSFileManager *files = NSFileManager.defaultManager;
  NSString *database = DatabasePath();
  NSString *parent = database.stringByDeletingLastPathComponent;
  if (![files createDirectoryAtPath:parent withIntermediateDirectories:YES
                         attributes:nil error:error]) {
    return NO;
  }

  if ([files fileExistsAtPath:database]) {
    NSString *backups = [SupportRoot() stringByAppendingPathComponent:@"MiiBackups"];
    if (![files createDirectoryAtPath:backups withIntermediateDirectories:YES
                           attributes:nil error:error]) {
      return NO;
    }
    NSString *stamp = [NSString stringWithFormat:@"%.0f",
        NSDate.date.timeIntervalSince1970];
    NSString *backup = [backups stringByAppendingPathComponent:
        [NSString stringWithFormat:@"RFL_DB-%@.dat", stamp]];
    if (![files copyItemAtPath:database toPath:backup error:error]) return NO;
  }

  if (![pendingData writeToFile:database options:NSDataWritingAtomic error:error]) {
    return NO;
  }
  if (![files removeItemAtPath:pending error:error]) return NO;
  return YES;
}

BOOL KartPadHasPendingMiiChanges(void) {
  return [NSFileManager.defaultManager fileExistsAtPath:PendingPath()];
}
