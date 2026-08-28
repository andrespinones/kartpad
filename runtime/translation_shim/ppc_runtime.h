#pragma once

#include <array>
#include <bit>
#include <cstdint>
#include <cstdlib>

#include "kartpad/semantics/ppc_semantics.h"
#include "memory.h"

#if defined(__clang__) || defined(__GNUC__)
#define MKW_RESTRICT __restrict
#define MKW_PPC_NO_INLINE __attribute__((noinline))
#define MKW_PPC_ALWAYS_INLINE_BODY __attribute__((always_inline))
#else
#define MKW_RESTRICT
#define MKW_PPC_NO_INLINE
#define MKW_PPC_ALWAYS_INLINE_BODY
#endif

using MkwStateFreeResult2 = std::uint64_t __attribute__((ext_vector_type(2)));

struct CpuContext {
  std::array<std::uint32_t, 32> gpr{};
  union Fpr {
    double d;
    std::uint64_t raw;
    constexpr Fpr():raw{} {}
  };
  std::array<Fpr, 32> fpr{};
  std::uint32_t cr{};
  std::uint32_t lr{};
  std::uint32_t ctr{};
  std::uint32_t xer{};
  std::uint32_t fpscr{};
  std::uint32_t pc{};
  std::array<std::uint32_t,8> gqr{};
  std::uint32_t srr0{},srr1{},hid0{},hid1{},hid2{},msr{};
  std::uint64_t time_base{};
};

using PPC_FPR = CpuContext::Fpr;

inline std::uint32_t PpcRotl32Inline(std::uint32_t value,std::uint32_t shift) {
  return std::rotl(value,static_cast<int>(shift&31u));
}
inline std::uint64_t PpcBitCastToU64Inline(double value) { return std::bit_cast<std::uint64_t>(value); }
inline std::uint32_t PPC_FprLowWordInline(double value) { return static_cast<std::uint32_t>(PpcBitCastToU64Inline(value)); }
inline double PpcBitCastToDoubleInline(std::uint64_t value) { return std::bit_cast<double>(value); }
inline std::uint32_t PpcBitCastToU32Inline(float value) { return std::bit_cast<std::uint32_t>(value); }
inline float PpcBitCastToFloatInline(std::uint32_t value) { return std::bit_cast<float>(value); }

inline void SetCRResident(std::uint32_t& cr, std::uint32_t xer, int field,
                          std::int32_t a, std::int32_t b) noexcept {
  const std::uint32_t value=(a<b?0x8u:0u)|(a>b?0x4u:0u)|(a==b?0x2u:0u)|((xer>>31)&1u);
  const auto shift=(7-field)*4;
  cr=(cr&~(0xfu<<shift))|(value<<shift);
}
inline void SetCRResident(std::uint32_t& cr, std::uint32_t xer, int field,
                          std::uint32_t a, std::uint32_t b) noexcept {
  const std::uint32_t value=(a<b?0x8u:0u)|(a>b?0x4u:0u)|(a==b?0x2u:0u)|((xer>>31)&1u);
  const auto shift=(7-field)*4;
  cr=(cr&~(0xfu<<shift))|(value<<shift);
}
inline void SetCRFloatResident(std::uint32_t& cr,int field,double a,double b) noexcept {
  const std::uint32_t value=(std::isnan(a)||std::isnan(b))?0x1u:
    ((a<b?0x8u:0u)|(a>b?0x4u:0u)|(a==b?0x2u:0u));
  const auto shift=(7-field)*4;
  cr=(cr&~(0xfu<<shift))|(value<<shift);
}
inline bool GetCRBitResident(std::uint32_t cr,int field,int bit) noexcept {
  return ((cr>>((7-field)*4+(3-bit)))&1u)!=0u;
}

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
  if(flags.invalid) bits|=kartpad::semantics::fpscr::VXVC;
  if(flags.overflow) bits|=kartpad::semantics::fpscr::OX;
  if(flags.underflow) bits|=kartpad::semantics::fpscr::UX;
  if(flags.divide_by_zero) bits|=kartpad::semantics::fpscr::ZX;
  if(flags.inexact) bits|=kartpad::semantics::fpscr::XX;
  if(bits!=0)g_currentCpuContext->fpscr=kartpad::semantics::SetFpscrException(
    g_currentCpuContext->fpscr,bits);
  std::feclearexcept(FE_ALL_EXCEPT);
}

inline void PpcUpdateOverflow(bool overflow) {
  if(g_currentCpuContext==nullptr) return;
  if(overflow) g_currentCpuContext->xer|=0xc0000000u;
  else g_currentCpuContext->xer&=~0x40000000u;
}
extern "C" inline std::uint32_t PPC_UpdateCarryAdd(std::uint32_t lhs,std::uint32_t rhs,std::uint32_t carry) {
  const auto result=kartpad::semantics::AddWord(lhs,rhs,(carry&1u)!=0);
  if(g_currentCpuContext) g_currentCpuContext->xer=(g_currentCpuContext->xer&~0x20000000u)|(result.carry?0x20000000u:0u);
  return g_currentCpuContext?g_currentCpuContext->xer:(result.carry?0x20000000u:0u);
}
extern "C" inline std::uint32_t PPC_UpdateCarrySub(std::uint32_t lhs,std::uint32_t rhs) {
  const bool carry=lhs>=rhs;
  if(g_currentCpuContext) g_currentCpuContext->xer=(g_currentCpuContext->xer&~0x20000000u)|(carry?0x20000000u:0u);
  return g_currentCpuContext?g_currentCpuContext->xer:(carry?0x20000000u:0u);
}
extern "C" inline std::uint32_t PPC_GetCarry() { return g_currentCpuContext?(g_currentCpuContext->xer>>29)&1u:0u; }
inline std::uint32_t PpcAddWithXer(std::uint32_t lhs,std::uint32_t rhs,std::uint32_t carry,bool updateCarry) {
  const auto result=kartpad::semantics::AddWord(lhs,rhs,(carry&1u)!=0);
  if(updateCarry) PPC_UpdateCarryAdd(lhs,rhs,carry);
  PpcUpdateOverflow(result.overflow); return result.value;
}
inline std::uint32_t PpcSubWithXer(std::uint32_t sub,std::uint32_t min,std::uint32_t carry,bool extended,bool updateCarry) {
  const auto result=kartpad::semantics::SubtractWord(sub,min,extended?(carry&1u)!=0:true);
  if(updateCarry&&g_currentCpuContext) g_currentCpuContext->xer=(g_currentCpuContext->xer&~0x20000000u)|(result.carry?0x20000000u:0u);
  PpcUpdateOverflow(result.overflow); return result.value;
}
extern "C" inline std::uint32_t PPC_Addo(std::uint32_t a,std::uint32_t b){return PpcAddWithXer(a,b,0,false);}
extern "C" inline std::uint32_t PPC_Addco(std::uint32_t a,std::uint32_t b){return PpcAddWithXer(a,b,0,true);}
extern "C" inline std::uint32_t PPC_Addeo(std::uint32_t a,std::uint32_t b){return PpcAddWithXer(a,b,PPC_GetCarry(),true);}
extern "C" inline std::uint32_t PPC_Subfo(std::uint32_t a,std::uint32_t b){return PpcSubWithXer(a,b,0,false,false);}
extern "C" inline std::uint32_t PPC_Subfco(std::uint32_t a,std::uint32_t b){return PpcSubWithXer(a,b,0,false,true);}
extern "C" inline std::uint32_t PPC_Subfeo(std::uint32_t a,std::uint32_t b){return PpcSubWithXer(a,b,PPC_GetCarry(),true,true);}
extern "C" inline std::uint32_t PPC_Addmeo(std::uint32_t v){return PpcAddWithXer(v,0xffffffffu,PPC_GetCarry(),true);}
extern "C" inline std::uint32_t PPC_Addzeo(std::uint32_t v){return PpcAddWithXer(v,0u,PPC_GetCarry(),true);}
extern "C" inline std::uint32_t PPC_Subfmeo(std::uint32_t v){return PpcSubWithXer(v,0xffffffffu,PPC_GetCarry(),true,true);}
extern "C" inline std::uint32_t PPC_Subfzeo(std::uint32_t v){return PpcSubWithXer(v,0u,PPC_GetCarry(),true,true);}
extern "C" inline std::uint32_t PPC_Nego(std::uint32_t v){return PpcSubWithXer(v,0u,0,false,false);}
extern "C" inline std::uint32_t PPC_Mullwo(std::uint32_t a,std::uint32_t b){const auto product=static_cast<std::int64_t>(static_cast<std::int32_t>(a))*static_cast<std::int64_t>(static_cast<std::int32_t>(b));PpcUpdateOverflow(product<std::numeric_limits<std::int32_t>::min()||product>std::numeric_limits<std::int32_t>::max());return static_cast<std::uint32_t>(product);}
extern "C" inline std::uint32_t PPC_Divwo(std::uint32_t a,std::uint32_t b){const auto lhs=static_cast<std::int32_t>(a),rhs=static_cast<std::int32_t>(b);const bool overflow=rhs==0||(lhs==std::numeric_limits<std::int32_t>::min()&&rhs==-1);PpcUpdateOverflow(overflow);return overflow?(lhs<0?0xffffffffu:0u):static_cast<std::uint32_t>(lhs/rhs);}
extern "C" inline std::uint32_t PPC_Divwuo(std::uint32_t a,std::uint32_t b){PpcUpdateOverflow(b==0);return b==0?0u:a/b;}
extern "C" inline std::uint32_t PPC_UpdateCarryShiftRight(std::uint32_t value,std::uint32_t shift){const bool negative=(value&0x80000000u)!=0;bool carry=false;if((shift&0x20u)!=0)carry=negative;else{const auto count=shift&31u;if(count&&negative)carry=(value&((1u<<count)-1u))!=0;}if(g_currentCpuContext)g_currentCpuContext->xer=(g_currentCpuContext->xer&~0x20000000u)|(carry?0x20000000u:0u);return g_currentCpuContext?g_currentCpuContext->xer:(carry?0x20000000u:0u);}
extern "C" inline std::uint32_t PPC_Cntlzw(std::uint32_t value){return kartpad::semantics::CountLeadingZero(value);}
inline std::uint32_t PPC_CntlzwInline(std::uint32_t value){return kartpad::semantics::CountLeadingZero(value);}
extern "C" inline std::uint32_t OSSystemCall(){return 0u;}
extern "C" inline std::int32_t memset_zero_32(std::int32_t address){
  const auto aligned=static_cast<std::uint32_t>(address)&~31u;
  for(std::uint32_t offset=0;offset<32u;offset+=4u)MemoryInline::FlatWriteRam32(aligned+offset,0u);
  return address;
}
extern "C" inline void PPC_TrapWord(std::uint32_t options,std::uint32_t lhs,std::uint32_t rhs){
  const auto slhs=static_cast<std::int32_t>(lhs),srhs=static_cast<std::int32_t>(rhs);
  const bool trap=((options&0x10u)&&slhs<srhs)||((options&0x08u)&&slhs>srhs)||
    ((options&0x04u)&&lhs==rhs)||((options&0x02u)&&lhs<rhs)||((options&0x01u)&&lhs>rhs);
  if(trap)std::abort();
}
extern "C" inline std::uint32_t PPC_Mftb(){return g_currentCpuContext?static_cast<std::uint32_t>(g_currentCpuContext->time_base):0u;}
extern "C" inline std::uint32_t PPC_Mftbu(){return g_currentCpuContext?static_cast<std::uint32_t>(g_currentCpuContext->time_base>>32):0u;}

inline std::uint32_t PpcCrSetBitResident(std::uint32_t cr,std::uint32_t bit,std::uint32_t value) {
  const auto mask=1u<<(31u-(bit&31u)); return (value&1u)?cr|mask:cr&~mask;
}
inline std::uint32_t PpcCrLogicalResident(std::uint32_t cr,std::uint32_t op,std::uint32_t bt,std::uint32_t ba,std::uint32_t bb) {
  const auto read=[cr](std::uint32_t bit){return (cr>>(31u-(bit&31u)))&1u;};
  const auto a=read(ba),b=read(bb); std::uint32_t result=0;
  switch(op&7u){case 0:result=~(a|b)&1u;break;case 1:result=a&(~b&1u);break;case 2:result=a^b;break;case 3:result=~(a&b)&1u;break;case 4:result=a&b;break;case 5:result=~(a^b)&1u;break;case 6:result=(~a&1u)|b;break;default:result=a|b;break;}
  return PpcCrSetBitResident(cr,bt,result);
}
inline std::uint32_t PpcMcrfResident(std::uint32_t cr,std::uint32_t dst,std::uint32_t src) {
  const auto ds=(7u-(dst&7u))*4u,ss=(7u-(src&7u))*4u; return (cr&~(0xfu<<ds))|(((cr>>ss)&0xfu)<<ds);
}
extern "C" inline std::uint32_t PPC_CrSetBit(std::uint32_t bit,std::uint32_t value){if(g_currentCpuContext)g_currentCpuContext->cr=PpcCrSetBitResident(g_currentCpuContext->cr,bit,value);return g_currentCpuContext?g_currentCpuContext->cr:0;}
extern "C" inline std::uint32_t PPC_CrLogical(std::uint32_t op,std::uint32_t bt,std::uint32_t ba,std::uint32_t bb){if(g_currentCpuContext)g_currentCpuContext->cr=PpcCrLogicalResident(g_currentCpuContext->cr,op,bt,ba,bb);return g_currentCpuContext?g_currentCpuContext->cr:0;}
extern "C" inline std::uint32_t PPC_Mcrf(std::uint32_t dst,std::uint32_t src){if(g_currentCpuContext)g_currentCpuContext->cr=PpcMcrfResident(g_currentCpuContext->cr,dst,src);return g_currentCpuContext?g_currentCpuContext->cr:0;}
extern "C" inline std::uint32_t PPC_Mcrxr(std::uint32_t field){if(!g_currentCpuContext)return 0;const auto shift=(7u-(field&7u))*4u;g_currentCpuContext->cr=(g_currentCpuContext->cr&~(0xfu<<shift))|(((g_currentCpuContext->xer>>28)&0xfu)<<shift);g_currentCpuContext->xer&=~0xf0000000u;return g_currentCpuContext->cr;}

inline thread_local bool g_ppcHasReservation=false;
inline thread_local std::uint32_t g_ppcReservationAddress=0;
extern "C" inline std::uint32_t PPC_Lwarx(std::uint32_t address){g_ppcHasReservation=true;g_ppcReservationAddress=address;return MemoryInline::FlatReadRam32(address);}
extern "C" inline std::uint32_t PPC_Stwcx(std::uint32_t address,std::uint32_t value){const bool ok=g_ppcHasReservation&&g_ppcReservationAddress==address;g_ppcHasReservation=false;if(ok)MemoryInline::FlatWriteRam32(address,value);if(g_currentCpuContext){const auto so=(g_currentCpuContext->xer>>31)&1u;g_currentCpuContext->cr=(g_currentCpuContext->cr&0x0fffffffu)|(((ok?2u:0u)|so)<<28);}return ok?1u:0u;}

extern "C" inline std::uint32_t PPC_LoadWordByteReverse(std::uint32_t address){return __builtin_bswap32(MemoryInline::FlatReadRam32(address));}
extern "C" inline void PPC_StoreWordByteReverse(std::uint32_t address,std::uint32_t value){MemoryInline::FlatWriteRam32(address,__builtin_bswap32(value));}
extern "C" inline std::uint32_t PPC_LoadHalfwordByteReverse(std::uint32_t address){return __builtin_bswap16(MemoryInline::FlatReadRam16(address));}
extern "C" inline void PPC_StoreHalfwordByteReverse(std::uint32_t address,std::uint32_t value){MemoryInline::FlatWriteRam16(address,__builtin_bswap16(static_cast<std::uint16_t>(value)));}

inline void PpcLoadString(std::uint32_t reg,std::uint32_t address,std::uint32_t count){if(!g_currentCpuContext)return;reg&=31u;std::uint32_t current=0;for(std::uint32_t index=0;index<count;++index){current=(current<<8)|MemoryInline::FlatReadRam8(address+index);if((index&3u)==3u){g_currentCpuContext->gpr[reg]=current;reg=(reg+1u)&31u;current=0;}}if((count&3u)!=0)g_currentCpuContext->gpr[reg]=current<<((4u-(count&3u))*8u);}
inline void PpcStoreString(std::uint32_t reg,std::uint32_t address,std::uint32_t count){if(!g_currentCpuContext)return;reg&=31u;for(std::uint32_t index=0;index<count;++index){MemoryInline::FlatWriteRam8(address+index,static_cast<std::uint8_t>(g_currentCpuContext->gpr[reg]>>(24u-((index&3u)*8u))));if((index&3u)==3u)reg=(reg+1u)&31u;}}
extern "C" inline void PPC_Lswi(std::uint32_t reg,std::uint32_t address,std::uint32_t count){PpcLoadString(reg,address,count==0?32u:count);}
extern "C" inline void PPC_Lswx(std::uint32_t reg,std::uint32_t address){PpcLoadString(reg,address,g_currentCpuContext?g_currentCpuContext->xer&0x7fu:0u);}
extern "C" inline void PPC_Stswi(std::uint32_t reg,std::uint32_t address,std::uint32_t count){PpcStoreString(reg,address,count==0?32u:count);}
extern "C" inline void PPC_Stswx(std::uint32_t reg,std::uint32_t address){PpcStoreString(reg,address,g_currentCpuContext?g_currentCpuContext->xer&0x7fu:0u);}

inline float PpcGetPs0Inline(double value);
inline float PpcGetPs1Inline(double value);
inline double PpcFmulsInline(double a,double c);
inline float PpcForceSingleValueInline(double value);

inline void PpcUpdateFpscrSummary() {
  if(!g_currentCpuContext)return;
  g_currentCpuContext->fpscr=kartpad::semantics::UpdateFpscrSummaries(
    g_currentCpuContext->fpscr);
}
extern "C" inline void PPC_Mtfsb1(std::uint32_t bit){if(!g_currentCpuContext)return;bit&=31u;if(bit!=1&&bit!=2)g_currentCpuContext->fpscr|=1u<<(31u-bit);PpcUpdateFpscrSummary();}
extern "C" inline void PPC_Mtfsb0(std::uint32_t bit){if(!g_currentCpuContext)return;g_currentCpuContext->fpscr&=~(1u<<(31u-(bit&31u)));PpcUpdateFpscrSummary();}
extern "C" inline void PPC_Mtfsfi(std::uint32_t field,std::uint32_t value){if(!g_currentCpuContext)return;field&=7u;const auto shift=(7u-field)*4u;auto mask=0xfu<<shift;if(field==0)mask&=~0x60000000u;g_currentCpuContext->fpscr=(g_currentCpuContext->fpscr&~mask)|((value&0xfu)<<shift);PpcUpdateFpscrSummary();}
extern "C" inline void PPC_Mtfsf(std::uint32_t fieldMask,double source){if(!g_currentCpuContext)return;const auto incoming=static_cast<std::uint32_t>(std::bit_cast<std::uint64_t>(source));for(std::uint32_t field=0;field<8;++field){if((fieldMask&(1u<<(7u-field)))==0)continue;const auto shift=(7u-field)*4u;auto mask=0xfu<<shift;if(field==0)mask&=~0x60000000u;g_currentCpuContext->fpscr=(g_currentCpuContext->fpscr&~mask)|(incoming&mask);}PpcUpdateFpscrSummary();}
extern "C" inline double PPC_Mffs(){return std::bit_cast<double>(static_cast<std::uint64_t>(g_currentCpuContext?g_currentCpuContext->fpscr:0u));}
extern "C" inline std::uint32_t PPC_Mcrfs(std::uint32_t dst,std::uint32_t src){if(!g_currentCpuContext)return 0;const auto ds=(7u-(dst&7u))*4u,ss=(7u-(src&7u))*4u;const auto value=(g_currentCpuContext->fpscr>>ss)&0xfu;g_currentCpuContext->cr=(g_currentCpuContext->cr&~(0xfu<<ds))|(value<<ds);g_currentCpuContext->fpscr&=~((0xfu<<ss)&0x9ff80700u);PpcUpdateFpscrSummary();return g_currentCpuContext->cr;}

inline bool PpcIsSignalingNan(double value){const auto bits=std::bit_cast<std::uint64_t>(value);return (bits&0x7ff0000000000000ULL)==0x7ff0000000000000ULL&&(bits&0x000fffffffffffffULL)!=0&&(bits&0x0008000000000000ULL)==0;}
inline void PpcSetCrField(std::uint32_t field,std::uint32_t value){if(!g_currentCpuContext)return;const auto shift=(7u-(field&7u))*4u;g_currentCpuContext->cr=(g_currentCpuContext->cr&~(0xfu<<shift))|((value&0xfu)<<shift);}
extern "C" inline void PPC_Fcmp(std::uint32_t field,double a,double b){PpcSetCrField(field,kartpad::semantics::ConditionFieldFloat(a,b));if(g_currentCpuContext&&(PpcIsSignalingNan(a)||PpcIsSignalingNan(b))){g_currentCpuContext->fpscr|=0xa1000000u;PpcUpdateFpscrSummary();}}
extern "C" inline void PPC_PsCmpo0(std::uint32_t field,double a,double b){PpcSetCrField(field,kartpad::semantics::ComparePairedLane(PpcGetPs0Inline(a),PpcGetPs0Inline(b)));}
extern "C" inline void PPC_PsCmpu0(std::uint32_t field,double a,double b){PPC_PsCmpo0(field,a,b);}
extern "C" inline void PPC_PsCmpo1(std::uint32_t field,double a,double b){PpcSetCrField(field,kartpad::semantics::ComparePairedLane(PpcGetPs1Inline(a),PpcGetPs1Inline(b)));}
extern "C" inline void PPC_PsCmpu1(std::uint32_t field,double a,double b){PPC_PsCmpo1(field,a,b);}

inline bool PpcCommitScalarFpInline(double& destination,
                                    kartpad::semantics::ScalarFpResult result){
  if(g_currentCpuContext)g_currentCpuContext->fpscr=result.fpscr;
  if(result.write_destination)destination=result.value;
  return result.write_destination;
}
inline bool PpcFaddsStateInline(double& destination,double a,double b){return PpcCommitScalarFpInline(destination,kartpad::semantics::EvaluatePpcScalarBinary(g_currentCpuContext?g_currentCpuContext->fpscr:0u,kartpad::semantics::ScalarFpBinaryOperation::Add,a,b,true));}
inline bool PpcFsubsStateInline(double& destination,double a,double b){return PpcCommitScalarFpInline(destination,kartpad::semantics::EvaluatePpcScalarBinary(g_currentCpuContext?g_currentCpuContext->fpscr:0u,kartpad::semantics::ScalarFpBinaryOperation::Subtract,a,b,true));}
inline bool PpcFmulsStateInline(double& destination,double a,double b){return PpcCommitScalarFpInline(destination,kartpad::semantics::EvaluatePpcScalarBinary(g_currentCpuContext?g_currentCpuContext->fpscr:0u,kartpad::semantics::ScalarFpBinaryOperation::Multiply,a,kartpad::semantics::Force25Bit(b),true));}
inline bool PpcFdivsStateInline(double& destination,double a,double b){return PpcCommitScalarFpInline(destination,kartpad::semantics::EvaluatePpcScalarBinary(g_currentCpuContext?g_currentCpuContext->fpscr:0u,kartpad::semantics::ScalarFpBinaryOperation::Divide,a,b,true));}
inline bool PpcFaddStateInline(double& destination,double a,double b){return PpcCommitScalarFpInline(destination,kartpad::semantics::EvaluatePpcScalarBinary(g_currentCpuContext?g_currentCpuContext->fpscr:0u,kartpad::semantics::ScalarFpBinaryOperation::Add,a,b,false));}
inline bool PpcFsubStateInline(double& destination,double a,double b){return PpcCommitScalarFpInline(destination,kartpad::semantics::EvaluatePpcScalarBinary(g_currentCpuContext?g_currentCpuContext->fpscr:0u,kartpad::semantics::ScalarFpBinaryOperation::Subtract,a,b,false));}
inline bool PpcFmulStateInline(double& destination,double a,double b){return PpcCommitScalarFpInline(destination,kartpad::semantics::EvaluatePpcScalarBinary(g_currentCpuContext?g_currentCpuContext->fpscr:0u,kartpad::semantics::ScalarFpBinaryOperation::Multiply,a,b,false));}
inline bool PpcFdivStateInline(double& destination,double a,double b){return PpcCommitScalarFpInline(destination,kartpad::semantics::EvaluatePpcScalarBinary(g_currentCpuContext?g_currentCpuContext->fpscr:0u,kartpad::semantics::ScalarFpBinaryOperation::Divide,a,b,false));}
inline bool PpcFsqrtStateInline(double& destination,double value){return PpcCommitScalarFpInline(destination,kartpad::semantics::EvaluatePpcSqrt(g_currentCpuContext?g_currentCpuContext->fpscr:0u,value,false));}
inline bool PpcFsqrtsStateInline(double& destination,double value){return PpcCommitScalarFpInline(destination,kartpad::semantics::EvaluatePpcSqrt(g_currentCpuContext?g_currentCpuContext->fpscr:0u,value,true));}
inline bool PpcFctiwWithModeStateInline(double& destination,double value,bool towardZero){const auto fpscrValue=g_currentCpuContext?g_currentCpuContext->fpscr:0u;const auto mode=towardZero?FE_TOWARDZERO:((fpscrValue&3u)==1u?FE_TOWARDZERO:(fpscrValue&3u)==2u?FE_UPWARD:(fpscrValue&3u)==3u?FE_DOWNWARD:FE_TONEAREST);return PpcCommitScalarFpInline(destination,kartpad::semantics::EvaluatePpcConvertToInteger(fpscrValue,value,mode));}
inline bool PpcFctiwStateInline(double& destination,double value){return PpcFctiwWithModeStateInline(destination,value,false);}
inline bool PpcFctiwzStateInline(double& destination,double value){return PpcFctiwWithModeStateInline(destination,value,true);}
extern "C" inline double PPC_Fadds(double a,double b){double result=0;PpcFaddsStateInline(result,a,b);return result;}
extern "C" inline double PPC_Fsubs(double a,double b){double result=0;PpcFsubsStateInline(result,a,b);return result;}
extern "C" inline double PPC_Fmuls(double a,double b){return PpcFmulsInline(a,b);}
extern "C" inline double PPC_Fdivs(double a,double b){double result=0;PpcFdivsStateInline(result,a,b);return result;}
extern "C" inline double PPC_Fmadd(double a,double c,double b){const auto v=std::fma(a,c,b);PpcApplyHostFpFlags();return v;}
extern "C" inline double PPC_Fmsub(double a,double c,double b){const auto v=std::fma(a,c,-b);PpcApplyHostFpFlags();return v;}
extern "C" inline double PPC_Fsqrt(double value){double result=0;PpcFsqrtStateInline(result,value);return result;}
extern "C" inline double PPC_Fctiw(double value){double result=0;PpcFctiwStateInline(result,value);return result;}

inline thread_local std::array<std::uint32_t,1024> g_ppcSprShadow{};
extern "C" inline std::uint32_t PPC_ReadSpr(std::uint32_t spr){if(spr>=912u&&spr<=919u)return g_currentCpuContext?g_currentCpuContext->gqr[spr-912u]:0u;if(!g_currentCpuContext)return spr<g_ppcSprShadow.size()?g_ppcSprShadow[spr]:0u;switch(spr){case 1:return g_currentCpuContext->xer;case 8:return g_currentCpuContext->lr;case 9:return g_currentCpuContext->ctr;case 26:return g_currentCpuContext->srr0;case 27:return g_currentCpuContext->srr1;case 920:return g_currentCpuContext->hid2;case 1008:return g_currentCpuContext->hid0;case 1009:return g_currentCpuContext->hid1;default:return spr<g_ppcSprShadow.size()?g_ppcSprShadow[spr]:0u;}}
extern "C" inline void PPC_WriteSpr(std::uint32_t spr,std::uint32_t value){if(spr>=912u&&spr<=919u){if(g_currentCpuContext)g_currentCpuContext->gqr[spr-912u]=value;return;}if(g_currentCpuContext)switch(spr){case 1:g_currentCpuContext->xer=value;return;case 8:g_currentCpuContext->lr=value;return;case 9:g_currentCpuContext->ctr=value;return;case 26:g_currentCpuContext->srr0=value;return;case 27:g_currentCpuContext->srr1=value;return;case 920:g_currentCpuContext->hid2=value;return;case 1008:g_currentCpuContext->hid0=value;return;case 1009:g_currentCpuContext->hid1=value;return;default:break;}if(spr<g_ppcSprShadow.size())g_ppcSprShadow[spr]=value;}

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
inline double PpcFnmaddInline(double a,double c,double b) { const auto value=std::fma(a,c,b); return std::isnan(value)?value:-value; }
inline double PpcFnmsubInline(double a,double c,double b) { const auto value=std::fma(a,c,-b); return std::isnan(value)?value:-value; }
inline double PpcFmulsInline(double a,double c) { return static_cast<double>(kartpad::semantics::ForceSingle(a*kartpad::semantics::Force25Bit(c))); }
inline double PpcFmaddsInline(double a,double c,double b) { return static_cast<double>(kartpad::semantics::ForceSingle(std::fma(a,kartpad::semantics::Force25Bit(c),b))); }
inline double PpcFmsubsInline(double a,double c,double b) { return static_cast<double>(kartpad::semantics::ForceSingle(std::fma(a,kartpad::semantics::Force25Bit(c),-b))); }
inline double PPC_Frsqrte(double value) { return kartpad::semantics::ApproximateReciprocalSquareRoot(value); }
inline double PPC_Fctiwz(double value) { double result=0;PpcFctiwzStateInline(result,value);return result; }

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

template<std::uint32_t W,std::uint32_t I>
inline double PPC_PsqLInline(CpuContext* cpu,std::uint32_t address) {
  return PPC_PsqLGqrInline<W,I>(cpu,cpu?cpu->gqr[I]:0u,address);
}
template<std::uint32_t W,std::uint32_t I>
inline double PPC_PsqLStackInline(CpuContext* cpu,std::uint32_t address) {
  return PPC_PsqLInline<W,I>(cpu,address);
}
template<std::uint32_t W,std::uint32_t I>
inline void PPC_PsqStInline(CpuContext* cpu,std::uint32_t address,double value) {
  PPC_PsqStGqrInline<W,I>(cpu,cpu?cpu->gqr[I]:0u,address,value);
}
template<std::uint32_t W,std::uint32_t I>
inline void PPC_PsqStStackInline(CpuContext* cpu,std::uint32_t address,double value) {
  PPC_PsqStInline<W,I>(cpu,address,value);
}
template<std::uint32_t W,std::uint32_t I,bool Stack>
inline double PPC_PsqLStateInline(std::uint32_t gqr,std::uint32_t address) {
  (void)Stack; return PPC_PsqLGqrInline<W,I>(g_currentCpuContext,gqr,address);
}
template<std::uint32_t W,std::uint32_t I,bool Stack>
inline void PPC_PsqStStateInline(std::uint32_t gqr,std::uint32_t address,double value) {
  (void)Stack; PPC_PsqStGqrInline<W,I>(g_currentCpuContext,gqr,address,value);
}
template<std::uint32_t W,std::uint32_t I>
inline double PPC_PsqLResolvedInline(CpuContext* cpu,std::uint8_t*,std::uint32_t,
                                     std::uint32_t address) {
  return PPC_PsqLInline<W,I>(cpu,address);
}
template<std::uint32_t W,std::uint32_t I>
inline void PPC_PsqStResolvedInline(CpuContext* cpu,std::uint8_t*,std::uint32_t,
                                    std::uint32_t address,double value) {
  PPC_PsqStInline<W,I>(cpu,address,value);
}
template<std::uint32_t W,std::uint32_t I,std::uint32_t Gqr>
inline double PPC_PsqLKnownResolvedInline(CpuContext* cpu,std::uint8_t*,std::uint32_t,
                                          std::uint32_t address) {
  return PPC_PsqLGqrInline<W,I>(cpu,Gqr,address);
}
template<std::uint32_t W,std::uint32_t I,std::uint32_t Gqr>
inline void PPC_PsqStKnownResolvedInline(CpuContext* cpu,std::uint8_t*,std::uint32_t,
                                         std::uint32_t address,double value) {
  PPC_PsqStGqrInline<W,I>(cpu,Gqr,address,value);
}

extern "C" inline double PPC_PsAdd(double a,double b){return PPC_PsAddInline(a,b);}
extern "C" inline double PPC_PsSub(double a,double b){return PPC_PsSubInline(a,b);}
extern "C" inline double PPC_PsMul(double a,double b){return PPC_PsMulInline(a,b);}
extern "C" inline double PPC_PsDiv(double a,double b){return PPC_PsDivInline(a,b);}
extern "C" inline double PPC_PsMadd(double a,double c,double b){return PPC_PsMaddInline(a,c,b);}
extern "C" inline double PPC_PsMsub(double a,double c,double b){return PPC_PsMsubInline(a,c,b);}
extern "C" inline double PPC_PsNmadd(double a,double c,double b){return PPC_PsNmaddInline(a,c,b);}
extern "C" inline double PPC_PsNmsub(double a,double c,double b){return PPC_PsNmsubInline(a,c,b);}
extern "C" inline double PPC_PsMadds0(double a,double c,double b){return PPC_PsMadds0Inline(a,c,b);}
extern "C" inline double PPC_PsMadds1(double a,double c,double b){return PPC_PsMadds1Inline(a,c,b);}
extern "C" inline double PPC_PsMuls0(double a,double c){return PPC_PsMuls0Inline(a,c);}
extern "C" inline double PPC_PsMuls1(double a,double c){return PPC_PsMuls1Inline(a,c);}
extern "C" inline double PPC_PsNeg(double value){return PPC_PsNegInline(value);}
extern "C" inline double PPC_PsAbs(double value){return PPC_PsAbsInline(value);}
extern "C" inline double PPC_PsNabs(double value){return PpcPack(kartpad::semantics::PsNabs(PpcUnpack(value)));}
extern "C" inline double PPC_PsMr(double value){return value;}
extern "C" inline double PPC_PsSum0(double a,double b,double c){return PPC_PsSum0Inline(a,b,c);}
extern "C" inline double PPC_PsSum1(double a,double b,double c){return PPC_PsSum1Inline(a,b,c);}
extern "C" inline double PPC_PsMerge00(double a,double b){return PPC_PsMerge00Inline(a,b);}
extern "C" inline double PPC_PsMerge01(double a,double b){return PPC_PsMerge01Inline(a,b);}
extern "C" inline double PPC_PsMerge10(double a,double b){return PPC_PsMerge10Inline(a,b);}
extern "C" inline double PPC_PsMerge11(double a,double b){return PPC_PsMerge11Inline(a,b);}
extern "C" inline double PPC_PsSel(double p,double c,double n){return PPC_PsSelInline(p,c,n);}
extern "C" inline double PPC_PsFromScalar(double v){return PPC_PsFromScalarInline(v);}
extern "C" inline double PPC_PsToScalar(double v){return PPC_PsToScalarInline(v);}
extern "C" inline double PPC_PsRes(double v){return PpcPack(kartpad::semantics::PsReciprocal(PpcUnpack(v)));}
extern "C" inline double PPC_PsRsqrte(double v){return PpcPack(kartpad::semantics::PsReciprocalSquareRoot(PpcUnpack(v)));}
extern "C" inline double PPC_Fres(double v){const auto r=static_cast<float>(kartpad::semantics::ApproximateReciprocal(PpcGetPs0Inline(v)));return PpcPack({r,r});}
extern "C" inline double PPC_Fsel(double control,double negative,double positive){return control>=-0.0?positive:negative;}
extern "C" inline double PPC_Fnmadd(double a,double c,double b){const auto v=PPC_Fmadd(a,c,b);return std::isnan(v)?v:-v;}
extern "C" inline double PPC_Fnmsub(double a,double c,double b){const auto v=PPC_Fmsub(a,c,b);return std::isnan(v)?v:-v;}
extern "C" inline double PPC_Fmadds(double a,double c,double b){return PpcFmaddsInline(a,c,b);}
extern "C" inline double PPC_Fmsubs(double a,double c,double b){return PpcFmsubsInline(a,c,b);}
extern "C" inline double PPC_Fnmadds(double a,double c,double b){const auto v=PpcFmaddsInline(a,c,b);return std::isnan(v)?v:-v;}
extern "C" inline double PPC_Fnmsubs(double a,double c,double b){const auto v=PpcFmsubsInline(a,c,b);return std::isnan(v)?v:-v;}
extern "C" inline void PPC_Stfiwx(std::uint32_t address,double value){MemoryInline::FlatWriteRam32(address,static_cast<std::uint32_t>(std::bit_cast<std::uint64_t>(value)));}
extern "C" inline double PPC_PsqL(std::uint32_t address,std::uint32_t w,std::uint32_t i){const auto gqr=g_currentCpuContext?g_currentCpuContext->gqr[i&7u]:0u;return w?PPC_PsqLGqrInline<1u>(g_currentCpuContext,gqr,address):PPC_PsqLGqrInline<0u>(g_currentCpuContext,gqr,address);}
extern "C" inline void PPC_PsqSt(std::uint32_t address,double value,std::uint32_t w,std::uint32_t i){const auto gqr=g_currentCpuContext?g_currentCpuContext->gqr[i&7u]:0u;if(w)PPC_PsqStGqrInline<1u>(g_currentCpuContext,gqr,address,value);else PPC_PsqStGqrInline<0u>(g_currentCpuContext,gqr,address,value);}
inline std::uint32_t PPC_Slw(std::uint32_t v,std::uint32_t s){return kartpad::semantics::ShiftLeftWord(v,s);}
inline std::uint32_t PPC_Srw(std::uint32_t v,std::uint32_t s){return kartpad::semantics::ShiftRightWord(v,s);}
inline std::uint32_t PPC_Sraw(std::uint32_t v,std::uint32_t s){return kartpad::semantics::ShiftRightAlgebraic(v,s);}
inline std::uint32_t PPC_Divwu(std::uint32_t a,std::uint32_t b){return kartpad::semantics::DivideWordUnsigned(a,b);}
inline std::int32_t PPC_Divw(std::int32_t a,std::int32_t b){return kartpad::semantics::DivideWord(a,b);}
