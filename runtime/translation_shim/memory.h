#pragma once

#include <cstdint>

namespace MemoryInline {
std::uint8_t FlatReadRam8(std::uint32_t address);
void FlatWriteRam8(std::uint32_t address,std::uint8_t value);
void FlatWriteRam32(std::uint32_t address, std::uint32_t value);
double FlatReadFloat32(std::uint32_t address);
void FlatWriteRamFloat32(std::uint32_t address, double value);
}
