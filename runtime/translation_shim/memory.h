#pragma once

#include <cstdint>

extern "C" void GX_HLE_FIFO_WriteFloat(float value);
extern "C" void GX_HLE_FIFO_Write32(std::uint32_t value);
extern "C" void GX_HLE_FIFO_Write16(std::uint16_t value);
extern "C" void GX_HLE_FIFO_Write8(std::uint8_t value);
extern "C" void GX_HLE_FIFO_WriteBurst(const std::uint8_t* data,
                                        std::uint32_t sizeBytes);

namespace MemoryInline {
struct ResolvedLoadPair {
  std::uint32_t first{};
  std::uint32_t second{};
  bool valid{};
};

std::uint8_t FlatReadRam8(std::uint32_t address);
std::uint16_t FlatReadRam16(std::uint32_t address);
std::uint32_t FlatReadRam32(std::uint32_t address);
void FlatWriteRam8(std::uint32_t address,std::uint8_t value);
void FlatWriteRam16(std::uint32_t address,std::uint16_t value);
void FlatWriteRam32(std::uint32_t address, std::uint32_t value);
float FlatReadFloat32(std::uint32_t address);
void FlatWriteRamFloat32(std::uint32_t address, double value);

std::uint8_t FlatRead8(std::uint32_t address);
std::uint16_t FlatRead16(std::uint32_t address);
std::uint32_t FlatRead32(std::uint32_t address);
double FlatReadFloat64(std::uint32_t address);
void FlatWrite8(std::uint32_t address, std::uint8_t value);
void FlatWrite16(std::uint32_t address, std::uint16_t value);
void FlatWrite32(std::uint32_t address, std::uint32_t value);
void FlatWriteFloat32(std::uint32_t address, double value);
void FlatWriteFloat64(std::uint32_t address, double value);
void FlatWriteRamFloat64(std::uint32_t address, double value);

std::uint8_t* ResolveRangeHost(std::uint32_t base, std::int32_t minOffset,
                              std::uint32_t length, bool needsRead, bool needsWrite);
ResolvedLoadPair ReadResolvedPair16(std::uint8_t* host, std::uint32_t rangeOffset);
ResolvedLoadPair ReadResolvedPair32(std::uint8_t* host, std::uint32_t rangeOffset);
bool WriteResolvedPair16(std::uint8_t* host, std::uint32_t rangeOffset,
                         std::uint32_t packed);
bool WriteResolvedPair32(std::uint8_t* host, std::uint32_t rangeOffset,
                         std::uint64_t packed);
std::uint8_t ReadResolved8(std::uint8_t* host, std::uint32_t rangeOffset,
                           std::uint32_t address);
std::uint16_t ReadResolved16(std::uint8_t* host, std::uint32_t rangeOffset,
                             std::uint32_t address);
std::uint32_t ReadResolved32(std::uint8_t* host, std::uint32_t rangeOffset,
                             std::uint32_t address);
float ReadResolvedFloat32(std::uint8_t* host, std::uint32_t rangeOffset,
                          std::uint32_t address);
double ReadResolvedFloat64(std::uint8_t* host, std::uint32_t rangeOffset,
                           std::uint32_t address);
void WriteResolved8(std::uint8_t* host, std::uint32_t rangeOffset,
                    std::uint32_t address, std::uint8_t value);
void WriteResolved16(std::uint8_t* host, std::uint32_t rangeOffset,
                     std::uint32_t address, std::uint16_t value);
void WriteResolved32(std::uint8_t* host, std::uint32_t rangeOffset,
                     std::uint32_t address, std::uint32_t value);
void WriteResolvedFloat32(std::uint8_t* host, std::uint32_t rangeOffset,
                          std::uint32_t address, double value);
void WriteResolvedFloat64(std::uint8_t* host, std::uint32_t rangeOffset,
                          std::uint32_t address, double value);
}
