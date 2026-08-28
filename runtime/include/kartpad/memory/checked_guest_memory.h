#pragma once

#include <cstddef>
#include <cstdint>
#include <functional>
#include <mutex>
#include <optional>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

namespace kartpad::memory {

enum class FaultKind {
  Unmapped,
  CrossRegion,
  ExecutableWrite,
  InvalidMapping,
};

struct FaultContext {
  std::uint32_t guest_pc = 0;
  std::uint32_t guest_lr = 0;
  std::string translated_function;
  std::string register_dump;
};

class GuestMemoryFault final : public std::runtime_error {
 public:
  GuestMemoryFault(FaultKind kind, std::uint32_t address, std::size_t width, std::string message,
                   std::optional<FaultContext> context = std::nullopt);
  [[nodiscard]] FaultKind Kind() const noexcept { return kind_; }
  [[nodiscard]] std::uint32_t Address() const noexcept { return address_; }
  [[nodiscard]] std::size_t Width() const noexcept { return width_; }
  [[nodiscard]] const std::optional<FaultContext>& Context() const noexcept { return context_; }

 private:
  FaultKind kind_;
  std::uint32_t address_;
  std::size_t width_;
  std::optional<FaultContext> context_;
};

class CheckedGuestMemory final {
 public:
  using BackingId = std::uint32_t;
  using MmioRead = std::function<std::uint64_t(std::uint32_t, std::size_t)>;
  using MmioWrite = std::function<void(std::uint32_t, std::size_t, std::uint64_t)>;
  using FaultContextProvider = std::function<FaultContext()>;

  struct Region {
    std::uint32_t guest_base = 0;
    std::uint64_t size = 0;
    BackingId backing = 0;
    std::uint64_t backing_offset = 0;
  };

  void Map(const Region& region);
  void RegisterMmio(std::uint32_t start, std::uint32_t end, MmioRead read, MmioWrite write);
  void RegisterExecutable(std::uint32_t start, std::uint32_t end);
  void SetFaultContextProvider(FaultContextProvider provider);
  void Reset();

  [[nodiscard]] std::uint64_t LoadUnsigned(std::uint32_t address, std::size_t width) const;
  [[nodiscard]] std::int64_t LoadSigned(std::uint32_t address, std::size_t width) const;
  void Store(std::uint32_t address, std::size_t width, std::uint64_t value);

  [[nodiscard]] std::size_t RegionCount() const;
  [[nodiscard]] std::uint64_t BackingSize(BackingId backing) const;

 private:
  struct Mapping {
    std::uint32_t guest_base;
    std::uint64_t size;
    BackingId backing;
    std::uint64_t backing_offset;
  };
  struct MmioRange {
    std::uint32_t start;
    std::uint32_t end;
    MmioRead read;
    MmioWrite write;
  };
  struct AddressRange {
    std::uint32_t start;
    std::uint32_t end;
  };

  [[nodiscard]] const Mapping* FindMapping(std::uint32_t address) const;
  [[nodiscard]] const MmioRange* FindMmio(std::uint32_t address, std::size_t width) const;
  [[nodiscard]] bool IntersectsExecutable(std::uint32_t address, std::size_t width) const;
  [[nodiscard]] std::uint64_t CheckedEnd(std::uint32_t address, std::size_t width) const;
  [[nodiscard]] GuestMemoryFault MakeFault(FaultKind kind, std::uint32_t address,
                                           std::size_t width, std::string message) const;

  mutable std::mutex mutex_;
  std::vector<Mapping> mappings_;
  std::unordered_map<BackingId, std::vector<std::byte>> backings_;
  std::vector<MmioRange> mmio_;
  std::vector<AddressRange> executable_;
  FaultContextProvider fault_context_provider_;
};

}  // namespace kartpad::memory
