#include <kartpad/mii/seed_mii_database.h>

#include <algorithm>
#include <array>
#include <cstdint>
#include <span>

int main() {
    constexpr std::array<uint8_t, 6> mac{0x00, 0x09, 0xBF, 0x12, 0x34, 0x56};
    const auto database = kartpad::mii::CreateSeedDatabase(mac);
    if (database.size() != kartpad::mii::kDatabaseSize ||
        !std::equal(database.begin(), database.begin() + 4, "RNOD") ||
        !std::equal(database.begin() + 0x1D00,
                    database.begin() + 0x1D04, "RNHD")) {
        return 1;
    }

    const auto block = std::span<const uint8_t>(database).subspan(
        kartpad::mii::kMiiBlockOffset, kartpad::mii::kMiiBlockSize);
    if (block[0x02] != 0 || block[0x03] != 'K' ||
        block[0x04] != 0 || block[0x05] != 'a' ||
        block[0x18] != 0x80 || block[0x1B] != 0x01 ||
        block[0x1C] != 0xC8 || block[0x1D] != 0x12 ||
        block[0x1E] != 0x34 || block[0x1F] != 0x56) {
        return 2;
    }

    const uint16_t storedCrc = static_cast<uint16_t>(
        (static_cast<uint16_t>(database[kartpad::mii::kDatabaseCrcOffset]) << 8) |
        database[kartpad::mii::kDatabaseCrcOffset + 1]);
    const uint16_t calculatedCrc = kartpad::mii::Crc16Ccitt(
        std::span<const uint8_t>(database.data(), kartpad::mii::kDatabaseCrcOffset));
    if (storedCrc != calculatedCrc) {
        return 3;
    }

    const auto second = kartpad::mii::CreateSeedDatabase(mac);
    if (database != second) {
        return 4;
    }
    return 0;
}
