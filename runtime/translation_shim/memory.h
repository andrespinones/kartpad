#pragma once

#include <cstdint>

namespace MemoryInline {
void FlatWriteRam32(std::uint32_t address, std::uint32_t value);
double FlatReadFloat32(std::uint32_t address);
void FlatWriteRamFloat32(std::uint32_t address, double value);
}
