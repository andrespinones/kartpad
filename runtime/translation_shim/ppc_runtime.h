#pragma once

#include <array>
#include <bit>
#include <cstdint>
#include <cstdlib>

#include "kartpad/semantics/ppc_semantics.h"
#include "memory.h"

#if defined(__clang__) || defined(__GNUC__)
#define MKW_RESTRICT __restrict
#else
#define MKW_RESTRICT
#endif

struct CpuContext {
  std::array<std::uint32_t, 32> gpr{};
  struct Fpr { double d{}; };
  std::array<Fpr, 32> fpr{};
  std::uint32_t cr{};
  std::uint32_t lr{};
  std::uint32_t ctr{};
  std::uint32_t xer{};
  std::uint32_t fpscr{};
  std::uint32_t pc{};
  std::array<std::uint32_t,8> gqr{};
};

using PPC_FPR = CpuContext::Fpr;

inline thread_local CpuContext* g_currentCpuContext=nullptr;
class CpuContextScope {
 public:
  explicit CpuContextScope(CpuContext* context):previous_(g_currentCpuContext) {
    g_currentCpuContext=context;
    std::feclearexcept(FE_ALL_EXCEPT);
  }
  ~CpuContextScope() { g_currentCpuContext=previous_; std::feclearexcept(FE_ALL_EXCEPT); }
 private:
  CpuContext* previous_{};
};

inline void PpcApplyHostFpFlags() {
  if(g_currentCpuContext==nullptr) return;
  const auto flags=kartpad::semantics::CaptureFlags();
  std::uint32_t bits=0;
  if(flags.invalid) bits|=0x80000000u|0x20000000u|0x00080000u;
  if(flags.overflow) bits|=0x80000000u|0x10000000u;
  if(flags.underflow) bits|=0x80000000u|0x08000000u;
  if(flags.divide_by_zero) bits|=0x80000000u|0x04000000u;
  if(flags.inexact) bits|=0x80000000u|0x02000000u;
  g_currentCpuContext->fpscr|=bits;
  std::feclearexcept(FE_ALL_EXCEPT);
}

inline float PpcForceSingleValueInline(double value) {
  const auto result=kartpad::semantics::ForceSingle(value,(g_currentCpuContext!=nullptr)&&((g_currentCpuContext->fpscr&4u)!=0));
  PpcApplyHostFpFlags();
  return result;
}

inline std::uint64_t PpcPackedBits(double value) { return std::bit_cast<std::uint64_t>(value); }
inline kartpad::semantics::PairedSingle PpcUnpack(double value) {
  const auto bits=PpcPackedBits(value);
  return {std::bit_cast<float>(static_cast<std::uint32_t>(bits>>32)),
          std::bit_cast<float>(static_cast<std::uint32_t>(bits))};
}
inline double PpcPack(kartpad::semantics::PairedSingle value) {
  const auto bits=(static_cast<std::uint64_t>(std::bit_cast<std::uint32_t>(value.ps0))<<32)|
                  std::bit_cast<std::uint32_t>(value.ps1);
  return std::bit_cast<double>(bits);
}
inline void PpcSetPairedFprInline(PPC_FPR& destination,double value) { destination.d=value; }
inline float PpcGetPs0Inline(double value) { return PpcUnpack(value).ps0; }
inline float PpcGetPs1Inline(double value) { return PpcUnpack(value).ps1; }
inline double PpcPackPairedInline(float ps0,float ps1) { return PpcPack({ps0,ps1}); }
inline double PPC_PsAddInline(double a,double b) { return PpcPack(kartpad::semantics::PsAdd(PpcUnpack(a),PpcUnpack(b))); }
inline double PPC_PsSubInline(double a,double b) { return PpcPack(kartpad::semantics::PsSub(PpcUnpack(a),PpcUnpack(b))); }
inline double PPC_PsMulInline(double a,double b) { return PpcPack(kartpad::semantics::PsMul(PpcUnpack(a),PpcUnpack(b))); }
inline double PPC_PsDivInline(double a,double b) { return PpcPack(kartpad::semantics::PsDiv(PpcUnpack(a),PpcUnpack(b))); }
inline double PPC_PsMaddInline(double a,double c,double b) { return PpcPack(kartpad::semantics::PsMadd(PpcUnpack(a),PpcUnpack(c),PpcUnpack(b))); }
inline double PPC_PsMsubInline(double a,double c,double b) { return PpcPack(kartpad::semantics::PsMsub(PpcUnpack(a),PpcUnpack(c),PpcUnpack(b))); }
inline double PPC_PsNmaddInline(double a,double c,double b) { return PpcPack(kartpad::semantics::PsNmadd(PpcUnpack(a),PpcUnpack(c),PpcUnpack(b))); }
inline double PPC_PsNmsubInline(double a,double c,double b) { return PpcPack(kartpad::semantics::PsNmsub(PpcUnpack(a),PpcUnpack(c),PpcUnpack(b))); }
inline double PPC_PsMadds0Inline(double a,double c,double b) { return PpcPack(kartpad::semantics::PsMadds0(PpcUnpack(a),PpcUnpack(c),PpcUnpack(b))); }
inline double PPC_PsMadds1Inline(double a,double c,double b) { return PpcPack(kartpad::semantics::PsMadds1(PpcUnpack(a),PpcUnpack(c),PpcUnpack(b))); }
inline double PPC_PsMuls0Inline(double a,double c) { return PpcPack(kartpad::semantics::PsMuls0(PpcUnpack(a),PpcUnpack(c))); }
inline double PPC_PsMuls1Inline(double a,double c) { return PpcPack(kartpad::semantics::PsMuls1(PpcUnpack(a),PpcUnpack(c))); }
inline double PPC_PsNegInline(double v) { return PpcPack(kartpad::semantics::PsNeg(PpcUnpack(v))); }
inline double PPC_PsAbsInline(double v) { return PpcPack(kartpad::semantics::PsAbs(PpcUnpack(v))); }
inline double PPC_PsSum0Inline(double a,double b,double c) { return PpcPack(kartpad::semantics::PsSum0(PpcUnpack(a),PpcUnpack(b),PpcUnpack(c))); }
inline double PPC_PsSum1Inline(double a,double b,double c) { return PpcPack(kartpad::semantics::PsSum1(PpcUnpack(a),PpcUnpack(b),PpcUnpack(c))); }
inline double PPC_PsMerge00Inline(double a,double b) { return PpcPack(kartpad::semantics::PsMerge00(PpcUnpack(a),PpcUnpack(b))); }
inline double PPC_PsMerge01Inline(double a,double b) { return PpcPack(kartpad::semantics::PsMerge01(PpcUnpack(a),PpcUnpack(b))); }
inline double PPC_PsMerge10Inline(double a,double b) { return PpcPack(kartpad::semantics::PsMerge10(PpcUnpack(a),PpcUnpack(b))); }
inline double PPC_PsMerge11Inline(double a,double b) { return PpcPack(kartpad::semantics::PsMerge11(PpcUnpack(a),PpcUnpack(b))); }
inline double PPC_PsSelInline(double p,double control,double n) { return PpcPack(kartpad::semantics::PsSelect(PpcUnpack(p),PpcUnpack(control),PpcUnpack(n))); }
inline double PPC_PsFromScalarInline(double value) { const auto lane=static_cast<float>(value); return PpcPack({lane,lane}); }
inline double PPC_PsToScalarInline(double value) { return static_cast<double>(PpcGetPs0Inline(value)); }
inline double PpcFmaddInline(double a,double c,double b) { return std::fma(a,c,b); }
inline double PpcFmsubInline(double a,double c,double b) { return std::fma(a,c,-b); }
inline double PpcFmulsInline(double a,double c) { return static_cast<double>(kartpad::semantics::ForceSingle(a*kartpad::semantics::Force25Bit(c))); }
inline double PpcFmaddsInline(double a,double c,double b) { return static_cast<double>(kartpad::semantics::ForceSingle(std::fma(a,kartpad::semantics::Force25Bit(c),b))); }
inline double PpcFmsubsInline(double a,double c,double b) { return static_cast<double>(kartpad::semantics::ForceSingle(std::fma(a,kartpad::semantics::Force25Bit(c),-b))); }
inline double PPC_Frsqrte(double value) { return kartpad::semantics::ApproximateReciprocalSquareRoot(value); }
inline double PPC_Fctiwz(double value) { return std::bit_cast<double>(static_cast<std::uint64_t>(static_cast<std::uint32_t>(kartpad::semantics::ConvertToIntegerWord(value,FE_TOWARDZERO)))); }

#define PPC_PsAddNoNiInline PPC_PsAddInline
#define PPC_PsSubNoNiInline PPC_PsSubInline
#define PPC_PsMulNoNiInline PPC_PsMulInline
#define PPC_PsMaddNoNiInline PPC_PsMaddInline
#define PPC_PsMsubNoNiInline PPC_PsMsubInline
#define PPC_PsNmsubNoNiInline PPC_PsNmsubInline
#define PPC_PsFromScalarNoNiInline PPC_PsFromScalarInline

template<std::uint32_t W,std::uint32_t I=0u>
inline double PPC_PsqLGqrInline(CpuContext* cpu,std::uint32_t gqr,std::uint32_t address) {
  (void)I;
  if(cpu==nullptr) std::abort();
  std::array<std::uint8_t,8> bytes{};
  for(std::size_t index=0;index<bytes.size();++index) bytes[index]=MemoryInline::FlatReadRam8(address+static_cast<std::uint32_t>(index));
  const auto type=static_cast<kartpad::semantics::QuantizedType>((gqr>>16)&7u);
  const kartpad::semantics::Gqr decoded{type,(gqr>>24)&0x3fu};
  return PpcPack(kartpad::semantics::LoadQuantizedPair(bytes.data(),decoded,W!=0));
}

template<std::uint32_t W,std::uint32_t I=0u>
inline void PPC_PsqStGqrInline(CpuContext* cpu,std::uint32_t gqr,std::uint32_t address,double value) {
  (void)I;
  if(cpu==nullptr) std::abort();
  std::array<std::uint8_t,8> bytes{};
  const auto type=static_cast<kartpad::semantics::QuantizedType>(gqr&7u);
  const kartpad::semantics::Gqr decoded{type,(gqr>>8)&0x3fu};
  kartpad::semantics::StoreQuantizedPair(bytes.data(),decoded,W!=0,PpcUnpack(value));
  std::size_t width=type==kartpad::semantics::QuantizedType::Float?4u:
    (type==kartpad::semantics::QuantizedType::Unsigned16||type==kartpad::semantics::QuantizedType::Signed16?2u:1u);
  if constexpr(W==0u) width*=2u;
  for(std::size_t index=0;index<width;++index) MemoryInline::FlatWriteRam8(address+static_cast<std::uint32_t>(index),bytes[index]);
}
