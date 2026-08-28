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
std::uint8_t FlatReadRam8(std::uint32_t address) {
  return static_cast<std::uint8_t>(guest_memory->LoadUnsigned(address,1));
}
std::uint16_t FlatReadRam16(std::uint32_t address) {
  return static_cast<std::uint16_t>(guest_memory->LoadUnsigned(address,2));
}
std::uint32_t FlatReadRam32(std::uint32_t address) {
  return static_cast<std::uint32_t>(guest_memory->LoadUnsigned(address,4));
}
void FlatWriteRam8(std::uint32_t address,std::uint8_t value) {
  guest_memory->Store(address,1,value);
}
void FlatWriteRam16(std::uint32_t address,std::uint16_t value) {
  guest_memory->Store(address,2,value);
}
void FlatWriteRam32(std::uint32_t address, std::uint32_t value) {
  guest_memory->Store(address, 4, value);
}
float FlatReadFloat32(std::uint32_t address) {
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
  memory.Store(0x80011008u,4,0x3fc00000u);
  memory.Store(0x8001100cu,4,0xc0000000u);
  memory.Store(0x80011010u,4,0x40200000u);
  memory.Store(0x80011014u,4,0x40800000u);
  memory.Store(0x80011018u,4,0u);
  memory.Store(0x8001101cu,4,0x7f800000u);
  memory.Store(0x80011020u,4,0xff800000u);
  memory.Store(0x80011024u,4,0x42280000u);
  memory.Store(0x80011028u,4,0x40300000u);
  guest_memory=&memory;
  CpuContext context{};
  { CpuContextScope scope(&context);
    func_80001000(&context);
    const auto invalidBits=memory.LoadUnsigned(0x80010014u,4);
    const auto suppressedBits=memory.LoadUnsigned(0x80010018u,4);
    if(invalidBits!=0x7fc00000u || suppressedBits!=0x42280000u){
      std::cerr<<"invalidBits=0x"<<std::hex<<invalidBits
               <<" suppressedBits=0x"<<suppressedBits
               <<" fpscr=0x"<<context.fpscr<<'\n';
      throw std::runtime_error("translated invalid-result suppression mismatch");
    }
    constexpr std::uint32_t invalidState=kartpad::semantics::fpscr::FX|
      kartpad::semantics::fpscr::FEX|kartpad::semantics::fpscr::VX|
      kartpad::semantics::fpscr::VXISI|kartpad::semantics::fpscr::VE;
    if((context.fpscr&invalidState)!=invalidState)
      throw std::runtime_error("translated invalid FPSCR mismatch");
    if(context.fpr[14].raw!=0xfff8000000000002ULL ||
       context.fpr[15].raw!=0xfff8000000000003ULL ||
       context.fpr[13].raw!=0x4006000000000000ULL ||
       (context.fpscr&kartpad::semantics::fpscr::VXCVI)==0)
      throw std::runtime_error("translated fctiw state mismatch");
    if(context.fpr[16].raw!=0x4045000000000000ULL ||
       (context.fpscr&kartpad::semantics::fpscr::VXIMZ)==0)
      throw std::runtime_error("translated fused invalid suppression mismatch");
    if(context.fpr[17].raw!=0x4045000000000000ULL ||
       context.fpr[18].raw!=0x4045000000000000ULL ||
       (context.fpscr&kartpad::semantics::fpscr::VXSQRT)==0 ||
       (context.fpscr&kartpad::semantics::fpscr::ZE)==0)
      throw std::runtime_error("translated estimate suppression mismatch");
    if(context.fpr[21].raw!=0x7f80000000000000ULL ||
       (context.fpr[22].raw&0xffffffffULL)!=0x7fc00000ULL ||
       (context.fpscr&kartpad::semantics::fpscr::ZX)==0 ||
       (context.fpscr&kartpad::semantics::fpscr::FPRF)!=0x00004000u)
      throw std::runtime_error("translated paired estimate state mismatch");
    const auto overflow=PPC_Addo(0x7fffffffu,1u);
    if(overflow!=0x80000000u||(context.xer&0xc0000000u)!=0xc0000000u)
      throw std::runtime_error("XER overflow mismatch");
    PPC_UpdateCarryAdd(0xffffffffu,1u,0u);
    if(PPC_GetCarry()!=1u) throw std::runtime_error("XER carry mismatch");
    context.cr=0;
    PPC_CrSetBit(0,1); PPC_CrSetBit(31,1); PPC_CrLogical(7,1,0,31);
    if(context.cr!=0xc0000001u) throw std::runtime_error("CR logical mismatch");
    memory.Store(0x80010100u,4,0x11223344u);
    if(PPC_LoadWordByteReverse(0x80010100u)!=0x44332211u)
      throw std::runtime_error("byte reverse mismatch");
    if(PPC_Lwarx(0x80010100u)!=0x11223344u||PPC_Stwcx(0x80010100u,0xaabbccddu)!=1u||
       memory.LoadUnsigned(0x80010100u,4)!=0xaabbccddu)
      throw std::runtime_error("reservation mismatch");
    PPC_WriteSpr(8,0x12345678u); PPC_WriteSpr(9,0x87654321u);
    PPC_WriteSpr(912,0x3d040000u);
    if(PPC_ReadSpr(8)!=0x12345678u||PPC_ReadSpr(9)!=0x87654321u||
       PPC_ReadSpr(912)!=0x3d040000u)
      throw std::runtime_error("SPR mismatch");
    context.gpr[10]=0x11223344u; context.gpr[11]=0x55667788u;
    PPC_Stswi(10,0x80010120u,7u);
    context.gpr[12]=0; context.gpr[13]=0;
    PPC_Lswi(12,0x80010120u,7u);
    if(context.gpr[12]!=0x11223344u||context.gpr[13]!=0x55667700u)
      throw std::runtime_error("string load/store mismatch");
    PPC_Mtfsb1(6); PPC_Mtfsfi(7,3);
    if((context.fpscr&0x02000003u)!=0x02000003u||
       static_cast<std::uint32_t>(std::bit_cast<std::uint64_t>(PPC_Mffs()))!=context.fpscr)
      throw std::runtime_error("FPSCR move mismatch");
    const double signaling=std::bit_cast<double>(0x7ff0000000000001ULL);
    PPC_Fcmp(2,signaling,0.0);
    if(((context.cr>>20)&0xfu)!=1u||(context.fpscr&0xa1000000u)!=0xa1000000u)
      throw std::runtime_error("FP compare state mismatch");
  }
  guest_memory=nullptr;
  const auto integer=memory.LoadUnsigned(0x80010000u,4);
  const auto single=memory.LoadUnsigned(0x80010004u,4);
  const auto paired=memory.LoadUnsigned(0x80010008u,8);
  const auto division=memory.LoadUnsigned(0x80010010u,4);
  if(integer!=65534u || single!=0x40700000u || paired!=0x4080000040000000ULL ||
     division!=0x7f800000u || (context.fpscr&0x84000000u)!=0x84000000u)
    throw std::runtime_error("translated semantic fixture result mismatch");
  std::cout<<"translatedFunction=0x80001000 integer="<<integer
           <<" faddsBits=0x"<<std::hex<<single<<" psAddBits=0x"<<paired
           <<" divideBits=0x"<<division<<" fpscr=0x"<<context.fpscr
           <<" checkedMemory=pass\n";
}
