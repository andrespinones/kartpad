#pragma once

#include "kartpad/mii/mii_database.h"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <span>

namespace kartpad::mii {

inline constexpr std::size_t kRksysSize = 0x2BC000;
inline constexpr std::size_t kRksysCoreCrcOffset = 0x27FFC;
inline constexpr std::size_t kRksysLicenseOffset = 0x08;
inline constexpr std::size_t kRksysLicenseSize = 0x8CC0;
inline constexpr std::size_t kRksysLicenseCount = 4;
inline constexpr std::size_t kRksysMiiNameOffset = 0x14;
inline constexpr std::size_t kRksysCreateIdOffset = 0x28;

inline uint32_t Crc32(std::span<const uint8_t> bytes) {
    uint32_t crc = 0xFFFFFFFFu;
    for (const uint8_t byte : bytes) {
        crc ^= byte;
        for (int bit = 0; bit < 8; ++bit) {
            crc = (crc & 1u) != 0
                ? (crc >> 1) ^ 0xEDB88320u
                : crc >> 1;
        }
    }
    return crc ^ 0xFFFFFFFFu;
}

inline DatabaseResult ValidateRksys(std::span<const uint8_t> rksys) {
    if (rksys.size() != kRksysSize) {
        return {false, "The Mario Kart Wii save has an unexpected size."};
    }
    constexpr std::array<uint8_t, 8> kHeader{
        'R', 'K', 'S', 'D', '0', '0', '0', '6'};
    if (!std::equal(kHeader.begin(), kHeader.end(), rksys.begin())) {
        return {false, "The Mario Kart Wii save header is invalid."};
    }
    const uint32_t stored = ReadBigEndian32(rksys, kRksysCoreCrcOffset);
    const uint32_t calculated = Crc32(rksys.first(kRksysCoreCrcOffset));
    if (stored != calculated) {
        return {false, "The Mario Kart Wii save checksum is invalid."};
    }
    return {true, {}};
}

inline void UpdateRksysCrc(std::span<uint8_t> rksys) {
    WriteBigEndian32(rksys, kRksysCoreCrcOffset,
                     Crc32(std::span<const uint8_t>(
                         rksys.data(), kRksysCoreCrcOffset)));
}

inline std::array<uint8_t, kCreateIdByteSize> MiiCreateId(
        std::span<const uint8_t> database, std::size_t slot) {
    std::array<uint8_t, kCreateIdByteSize> result{};
    const std::size_t offset =
        kMiiBlockOffset + slot * kMiiBlockSize + 0x18;
    if (offset + result.size() <= database.size()) {
        std::copy_n(database.begin() + offset, result.size(), result.begin());
    }
    return result;
}

inline DatabaseResult RenameMatchingLicenses(
        std::span<uint8_t> rksys,
        const std::array<uint8_t, kCreateIdByteSize>& createId,
        std::span<const uint8_t> utf16BigEndianName,
        std::size_t& updatedLicenses) {
    updatedLicenses = 0;
    if (const auto validation = ValidateRksys(rksys); !validation) {
        return validation;
    }
    if (const auto validation =
            ValidateUtf16BigEndianName(utf16BigEndianName); !validation) {
        return validation;
    }

    for (std::size_t index = 0; index < kRksysLicenseCount; ++index) {
        const std::size_t license = kRksysLicenseOffset + index * kRksysLicenseSize;
        if (rksys[license] != 'R' || rksys[license + 1] != 'K' ||
            rksys[license + 2] != 'P' || rksys[license + 3] != 'D') {
            continue;
        }
        const auto storedId = std::span<const uint8_t>(rksys).subspan(
            license + kRksysCreateIdOffset, kCreateIdByteSize);
        if (!std::equal(createId.begin(), createId.end(), storedId.begin())) {
            continue;
        }
        auto storedName = rksys.subspan(
            license + kRksysMiiNameOffset, kMiiNameByteSize);
        std::fill(storedName.begin(), storedName.end(), 0);
        std::copy(utf16BigEndianName.begin(), utf16BigEndianName.end(),
                  storedName.begin());
        ++updatedLicenses;
    }
    if (updatedLicenses > 0) {
        UpdateRksysCrc(rksys);
    }
    return {true, {}};
}

} // namespace kartpad::mii
