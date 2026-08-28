#include "kartpad/translation/fixture_runtime.h"

#include "ppc_runtime.h"

#include <cstdint>
#include <stdexcept>

extern "C" void func_80001000(CpuContext* context);

namespace {
thread_local kartpad::memory::CheckedGuestMemory* g_memory = nullptr;
}

namespace MemoryInline {

void FlatWriteRam32(const std::uint32_t address, const std::uint32_t value) {
  if (g_memory == nullptr) {
    throw std::logic_error("translated fixture memory is not bound");
  }
  g_memory->Store(address, 4, value);
}

std::uint8_t* ResolveRangeHost(const std::uint32_t base, const std::int32_t min_offset,
                               const std::uint32_t length, const bool needs_read,
                               const bool needs_write) {
  (void)base;
  (void)min_offset;
  (void)length;
  (void)needs_read;
  (void)needs_write;
  if (g_memory == nullptr) {
    throw std::logic_error("translated fixture memory is not bound");
  }
  // The checked fixture backend intentionally never exposes raw backing
  // pointers. A non-null token keeps the translator's resolved-range fast
  // path while each access below remains checked by its guest address.
  return reinterpret_cast<std::uint8_t*>(1);
}

void WriteResolved32(std::uint8_t* host, const std::uint32_t range_offset,
                     const std::uint32_t address, const std::uint32_t value) {
  (void)host;
  (void)range_offset;
  FlatWriteRam32(address, value);
}

}  // namespace MemoryInline

namespace kartpad::translation {

void BindFixtureMemory(memory::CheckedGuestMemory& memory) {
  if (g_memory != nullptr) {
    throw std::logic_error("translated fixture memory is already bound");
  }
  g_memory = &memory;
}

void UnbindFixtureMemory() {
  g_memory = nullptr;
}

void RunG7TranslatedFrame(CpuContext& context) {
  CpuContextScope scope(&context);
  func_80001000(&context);
}

}  // namespace kartpad::translation
