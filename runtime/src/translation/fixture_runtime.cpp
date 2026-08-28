#include "kartpad/translation/fixture_runtime.h"

#include "ppc_runtime.h"

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
