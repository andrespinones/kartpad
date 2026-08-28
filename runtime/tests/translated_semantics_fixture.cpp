#include "kartpad/memory/checked_guest_memory.h"
#include "memory.h"
#include "ppc_runtime.h"

#include <bit>
#include <cstdint>
#include <iostream>
#include <stdexcept>

extern "C" void func_80001000(CpuContext* context);

namespace {
kartpad::memory::CheckedGuestMemory* guest_memory = nullptr;
}

namespace MemoryInline {
void FlatWriteRam32(std::uint32_t address, std::uint32_t value) {
  guest_memory->Store(address, 4, value);
}
double FlatReadFloat32(std::uint32_t address) {
  const auto bits=static_cast<std::uint32_t>(guest_memory->LoadUnsigned(address,4));
  return static_cast<double>(std::bit_cast<float>(bits));
}
void FlatWriteRamFloat32(std::uint32_t address,double value) {
  guest_memory->Store(address,4,std::bit_cast<std::uint32_t>(static_cast<float>(value)));
}
}

int main() {
  kartpad::memory::CheckedGuestMemory memory;
  memory.Map({.guest_base=0x80010000u,.size=0x2000,.backing=1,.backing_offset=0});
  memory.Store(0x80011000u,4,0x3fc00000u);
  memory.Store(0x80011004u,4,0x40100000u);
  guest_memory=&memory;
  CpuContext context{};
  func_80001000(&context);
  guest_memory=nullptr;
  const auto integer=memory.LoadUnsigned(0x80010000u,4);
  const auto single=memory.LoadUnsigned(0x80010004u,4);
  if(integer!=65534u || single!=0x40700000u)
    throw std::runtime_error("translated semantic fixture result mismatch");
  std::cout<<"translatedFunction=0x80001000 integer="<<integer
           <<" faddsBits=0x"<<std::hex<<single<<" checkedMemory=pass\n";
}
