#import "KartPadMiiManager.h"

#include "kartpad/mii/mii_database.h"
#include "kartpad/mii/player_identity.h"

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

NSArray<NSDictionary<NSString *, NSString *> *> *SaveLocations() {
  NSString *support = SupportRoot();
  return @[
    @{
      @"path": [support stringByAppendingPathComponent:
          @"NAND/title/00010004/524d4350/data/rksys.dat"],
      @"backup": @"rksys-nand",
    },
    @{
      @"path": [support stringByAppendingPathComponent:
          @"RetroRewind/riivolution/save/RetroWFC/RMCP/rksys.dat"],
      @"backup": @"rksys-retro-rewind",
    },
    @{
      @"path": [support stringByAppendingPathComponent:
          @"RetroRewind/riivolution/save/RetroWFC2/RMCP/rksys.dat"],
      @"backup": @"rksys-retro-rewind-separate",
    },
  ];
}

NSString *PendingIdentityPath() {
  return [SupportRoot() stringByAppendingPathComponent:
      @"PendingPlayerIdentity.plist"];
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

BOOL ValidateSaveData(NSData *data, NSError **error) {
  const auto validation = kartpad::mii::ValidateRksys(Bytes(data));
  if (!validation) {
    if (error != nullptr) *error = ManagerError(5, validation.message);
    return NO;
  }
  return YES;
}

NSData *PlayerNameData(NSString *name, NSError **error) {
  NSString *trimmed = [name stringByTrimmingCharactersInSet:
      NSCharacterSet.whitespaceAndNewlineCharacterSet];
  if (trimmed.length == 0 || trimmed.length > 10) {
    if (error != nullptr) {
      *error = ManagerError(6,
          "A player name must contain 1 to 10 characters.");
    }
    return nil;
  }
  NSData *encoded = [trimmed dataUsingEncoding:NSUTF16BigEndianStringEncoding
                           allowLossyConversion:NO];
  if (encoded == nil || encoded.length == 0 || encoded.length > 20) {
    if (error != nullptr) {
      *error = ManagerError(7,
          "The player name contains an unsupported character.");
    }
    return nil;
  }
  return encoded;
}

BOOL BackupFile(NSString *source, NSString *folder, NSString *name,
                NSString *stamp, NSError **error) {
  NSFileManager *files = NSFileManager.defaultManager;
  if (![files fileExistsAtPath:source]) return YES;
  NSString *backups = [SupportRoot() stringByAppendingPathComponent:folder];
  if (![files createDirectoryAtPath:backups withIntermediateDirectories:YES
                         attributes:nil error:error]) {
    return NO;
  }
  NSString *backup = [backups stringByAppendingPathComponent:
      [NSString stringWithFormat:@"%@-%@.dat", name, stamp]];
  return [files copyItemAtPath:source toPath:backup error:error];
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

BOOL KartPadStagePlayerName(NSUInteger slot, NSString *name,
                           NSUInteger *updatedLicenses, NSError **error) {
  if (updatedLicenses != nullptr) *updatedLicenses = 0;
  NSData *nameData = PlayerNameData(name, error);
  if (nameData == nil) return NO;

  NSData *databaseData = ReadWorkingDatabase(error);
  if (databaseData == nil || !ValidateData(databaseData, error)) return NO;
  std::vector<uint8_t> database(
      static_cast<const uint8_t *>(databaseData.bytes),
      static_cast<const uint8_t *>(databaseData.bytes) + databaseData.length);
  if (slot >= kartpad::mii::kMaximumMiiSlots) {
    if (error != nullptr) {
      *error = ManagerError(8, "The selected Mii slot is invalid.");
    }
    return NO;
  }
  const auto createId = kartpad::mii::MiiCreateId(database, slot);
  const auto renamed = kartpad::mii::RenameMii(
      database, slot, Bytes(nameData));
  if (!renamed) {
    if (error != nullptr) *error = ManagerError(8, renamed.message);
    return NO;
  }

  std::size_t changed = 0;
  for (NSDictionary<NSString *, NSString *> *location in SaveLocations()) {
    NSString *path = location[@"path"];
    if (![NSFileManager.defaultManager fileExistsAtPath:path]) continue;
    NSData *saveData = [NSData dataWithContentsOfFile:path
                                             options:NSDataReadingMappedIfSafe
                                               error:error];
    if (saveData == nil || !ValidateSaveData(saveData, error)) return NO;
    std::vector<uint8_t> save(
        static_cast<const uint8_t *>(saveData.bytes),
        static_cast<const uint8_t *>(saveData.bytes) + saveData.length);
    std::size_t saveChanged = 0;
    const auto saveResult = kartpad::mii::RenameMatchingLicenses(
        save, createId, Bytes(nameData), saveChanged);
    if (!saveResult) {
      if (error != nullptr) *error = ManagerError(9, saveResult.message);
      return NO;
    }
    changed += saveChanged;
  }

  NSData *createIdData = [NSData dataWithBytes:createId.data()
                                         length:createId.size()];
  NSDictionary *identity = @{
    @"createId": createIdData,
    @"name": nameData,
  };
  NSData *identityData = [NSPropertyListSerialization
      dataWithPropertyList:identity format:NSPropertyListBinaryFormat_v1_0
                   options:0 error:error];
  if (identityData == nil ||
      ![identityData writeToFile:PendingIdentityPath()
                         options:NSDataWritingAtomic error:error]) return NO;
  if (!WritePending(database, error)) {
    [NSFileManager.defaultManager removeItemAtPath:PendingIdentityPath()
                                             error:nil];
    return NO;
  }
  if (updatedLicenses != nullptr) *updatedLicenses = changed;
  return YES;
}

BOOL KartPadApplyPendingMiiDatabase(NSError **error) {
  NSString *pending = PendingPath();
  NSString *pendingIdentity = PendingIdentityPath();
  NSFileManager *files = NSFileManager.defaultManager;
  const BOOL hasDatabase = [files fileExistsAtPath:pending];
  const BOOL hasIdentity = [files fileExistsAtPath:pendingIdentity];
  if (!hasDatabase && !hasIdentity) return YES;

  NSData *pendingData = nil;
  if (hasDatabase) {
    pendingData = [NSData dataWithContentsOfFile:pending
                                         options:NSDataReadingMappedIfSafe
                                           error:error];
    if (pendingData == nil || !ValidateData(pendingData, error)) return NO;
  }
  NSMutableArray<NSDictionary<NSString *, id> *> *saveChanges =
      [NSMutableArray array];
  if (hasIdentity) {
    NSData *identityData = [NSData dataWithContentsOfFile:pendingIdentity
                                                  options:0 error:error];
    id propertyList = identityData == nil ? nil :
        [NSPropertyListSerialization propertyListWithData:identityData
                                                  options:0 format:nil
                                                    error:error];
    NSDictionary *identity = [propertyList isKindOfClass:NSDictionary.class]
        ? propertyList : nil;
    NSData *createId = [identity[@"createId"] isKindOfClass:NSData.class]
        ? identity[@"createId"] : nil;
    NSData *name = [identity[@"name"] isKindOfClass:NSData.class]
        ? identity[@"name"] : nil;
    if (createId.length != kartpad::mii::kCreateIdByteSize ||
        name.length == 0 || name.length > kartpad::mii::kMiiNameByteSize ||
        (name.length % 2) != 0) {
      if (error != nullptr) {
        *error = ManagerError(10, "The pending player identity is invalid.");
      }
      return NO;
    }
    std::array<uint8_t, kartpad::mii::kCreateIdByteSize> createIdBytes{};
    std::copy_n(static_cast<const uint8_t *>(createId.bytes),
                createIdBytes.size(), createIdBytes.begin());
    for (NSDictionary<NSString *, NSString *> *location in SaveLocations()) {
      NSString *path = location[@"path"];
      if (![files fileExistsAtPath:path]) continue;
      NSData *saveData = [NSData dataWithContentsOfFile:path
                                                options:NSDataReadingMappedIfSafe
                                                  error:error];
      if (saveData == nil || !ValidateSaveData(saveData, error)) return NO;
      std::vector<uint8_t> updatedSave(
          static_cast<const uint8_t *>(saveData.bytes),
          static_cast<const uint8_t *>(saveData.bytes) + saveData.length);
      std::size_t changedLicenses = 0;
      const auto renameResult = kartpad::mii::RenameMatchingLicenses(
          updatedSave, createIdBytes, Bytes(name), changedLicenses);
      if (!renameResult) {
        if (error != nullptr) *error = ManagerError(11, renameResult.message);
        return NO;
      }
      if (changedLicenses > 0) {
        [saveChanges addObject:@{
          @"path": path,
          @"backup": location[@"backup"],
          @"data": [NSData dataWithBytes:updatedSave.data()
                                    length:updatedSave.size()],
        }];
      }
    }
  }

  NSString *database = DatabasePath();
  NSString *stamp = [NSString stringWithFormat:@"%.0f-%@",
      NSDate.date.timeIntervalSince1970, NSUUID.UUID.UUIDString];
  if (hasDatabase &&
      !BackupFile(database, @"MiiBackups", @"RFL_DB", stamp, error)) return NO;
  for (NSDictionary<NSString *, id> *change in saveChanges) {
    if (!BackupFile(change[@"path"], @"SaveBackups", change[@"backup"],
                    stamp, error)) return NO;
  }

  if (hasDatabase) {
    NSString *parent = database.stringByDeletingLastPathComponent;
    if (![files createDirectoryAtPath:parent withIntermediateDirectories:YES
                           attributes:nil error:error] ||
        ![pendingData writeToFile:database options:NSDataWritingAtomic error:error]) {
      return NO;
    }
  }
  for (NSDictionary<NSString *, id> *change in saveChanges) {
    NSString *save = change[@"path"];
    NSString *parent = save.stringByDeletingLastPathComponent;
    NSData *saveData = change[@"data"];
    if (![files createDirectoryAtPath:parent withIntermediateDirectories:YES
                           attributes:nil error:error] ||
        ![saveData writeToFile:save options:NSDataWritingAtomic error:error]) {
      return NO;
    }
  }
  if (hasDatabase && ![files removeItemAtPath:pending error:error]) return NO;
  if (hasIdentity &&
      ![files removeItemAtPath:pendingIdentity error:error]) return NO;
  return YES;
}

BOOL KartPadHasPendingMiiChanges(void) {
  return [NSFileManager.defaultManager fileExistsAtPath:PendingPath()] ||
      [NSFileManager.defaultManager fileExistsAtPath:PendingIdentityPath()];
}
