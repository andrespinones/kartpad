#include "kartpad/mii/mii_database.h"

#include <algorithm>
#include <array>
#include <cassert>
#include <cstdint>
#include <string>
#include <vector>

int main() {
    constexpr std::array<uint8_t, 6> mac{0x02, 0x17, 0xAB, 0x10, 0x20, 0x30};
    auto database = kartpad::mii::CreateSeedDatabase(mac);
    assert(kartpad::mii::ValidateDatabase(database));

    auto records = kartpad::mii::ListMiis(database);
    assert(records.size() == 1);
    assert(records[0].name == "KartPad");

    auto imported = kartpad::mii::CreateDefaultMii(mac);
    kartpad::mii::WriteMiiName(imported, 0x02, "Racer");
    kartpad::mii::WriteBigEndian32(imported, 0x18, 0x80000002u);
    assert(kartpad::mii::ValidateMii(imported));
    assert(kartpad::mii::ImportMii(database, imported));
    assert(kartpad::mii::ValidateDatabase(database));

    records = kartpad::mii::ListMiis(database);
    assert(records.size() == 2);
    assert(records[1].name == "Racer");
    assert(!kartpad::mii::ImportMii(database, imported));

    assert(kartpad::mii::RemoveMii(database, records[1].slot));
    records = kartpad::mii::ListMiis(database);
    assert(records.size() == 1);
    assert(!kartpad::mii::RemoveMii(database, records[0].slot));

    auto invalid = imported;
    invalid[0] |= 0x80;
    assert(!kartpad::mii::ValidateMii(invalid));
    assert(!kartpad::mii::ValidateMii(
        std::span<const uint8_t>(invalid.data(), invalid.size() - 1)));
    return 0;
}
