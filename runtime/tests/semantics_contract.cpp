#include "kartpad/semantics/ppc_semantics.h"

#include <array>
#include <bit>
#include <cfenv>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <limits>
#include <random>
#include <string_view>

#pragma STDC FENV_ACCESS ON

using namespace kartpad::semantics;

namespace {
std::uint64_t g_hash = 1469598103934665603ULL;
std::uint64_t g_checks = 0;
void Mix(std::uint64_t value) { for (unsigned s=0;s<64;s+=8) { g_hash^=(value>>s)&0xffu; g_hash*=1099511628211ULL; } }
[[noreturn]] void Fail(std::string_view name,std::uint64_t expected,std::uint64_t actual) { std::cerr<<"FAIL "<<name<<" expected=0x"<<std::hex<<expected<<" actual=0x"<<actual<<'\n'; std::exit(1); }
void Check(std::string_view name,std::uint64_t expected,std::uint64_t actual) { ++g_checks; Mix(actual); if(expected!=actual) Fail(name,expected,actual); }

std::uint32_t ReferenceRotate(std::uint32_t value,std::uint32_t shift) { shift&=31u; return shift==0?value:(value<<shift)|(value>>(32u-shift)); }
std::uint32_t ReferenceMask(std::uint32_t mb,std::uint32_t me) { std::uint32_t result=0; for(std::uint32_t bit=0;bit<32;++bit) { const bool selected=mb<=me?(bit>=mb&&bit<=me):(bit>=mb||bit<=me); if(selected) result|=1u<<(31u-bit); } return result; }

void IntegerSuite() {
  Check("rotl zero",0x12345678u,RotateLeft32(0x12345678u,0));
  Check("rotl eight",0x34567812u,RotateLeft32(0x12345678u,8));
  Check("slw out",0u,ShiftLeftWord(0xffffffffu,32));
  Check("srw out",0u,ShiftRightWord(0xffffffffu,63));
  Check("sraw negative",0xffffffffu,ShiftRightAlgebraic(0x80000000u,32));
  Check("divw zero negative",0xffffffffu,static_cast<std::uint32_t>(DivideWord(-3,0)));
  Check("divw overflow",0xffffffffu,static_cast<std::uint32_t>(DivideWord(std::numeric_limits<std::int32_t>::min(),-1)));
  Check("divwu zero",0u,DivideWordUnsigned(42,0));
  Check("cntlzw zero",32u,CountLeadingZero(0));
  Check("cntlzw",8u,CountLeadingZero(0x00800000u));
  Check("cr signed",9u,ConditionFieldSigned(-1,2,0x80000000u));
  Check("cr unordered",1u,ConditionFieldFloat(std::numeric_limits<double>::quiet_NaN(),0.0));
  const auto add=AddWord(0xffffffffu,1u);
  Check("add value",0u,add.value); Check("add carry",1u,add.carry?1u:0u);
  const auto addOverflow=AddWord(0x7fffffffu,1u);
  Check("add overflow value",0x80000000u,addOverflow.value);
  Check("add overflow",1u,addOverflow.overflow?1u:0u);
  const auto subtract=SubtractWord(1u,0u);
  Check("sub value",0xffffffffu,subtract.value);
  Check("sub borrow",0u,subtract.carry?1u:0u);
  const auto subOverflow=SubtractWord(0xffffffffu,0x7fffffffu);
  Check("sub overflow value",0x80000000u,subOverflow.value);
  Check("sub overflow",1u,subOverflow.overflow?1u:0u);
  std::mt19937_64 rng(0x4b617274506164ULL);
  for(std::uint32_t i=0;i<100000;++i) { const auto value=static_cast<std::uint32_t>(rng()); const auto shift=static_cast<std::uint32_t>(rng()); Check("rotl random",ReferenceRotate(value,shift),RotateLeft32(value,shift)); const auto mb=shift&31u; const auto me=static_cast<std::uint32_t>(rng())&31u; Check("mask random",ReferenceMask(mb,me),Mask32(mb,me)); }
}

void ScalarSuite() {
  Check("force single 1/3",0x3eaaaaabu,std::bit_cast<std::uint32_t>(ForceSingle(1.0/3.0)));
  Check("force single negative zero",0x80000000u,std::bit_cast<std::uint32_t>(ForceSingle(-0.0)));
  Check("NI positive subnormal",0u,std::bit_cast<std::uint32_t>(ForceSingle(0x1p-149,true)));
  Check("NI negative subnormal",0x80000000u,std::bit_cast<std::uint32_t>(ForceSingle(-0x1p-149,true)));
  Check("fctiwz NaN",0x80000000u,static_cast<std::uint32_t>(ConvertToIntegerWord(std::numeric_limits<double>::quiet_NaN(),FE_TOWARDZERO)));
  Check("fctiw nearest even",2u,static_cast<std::uint32_t>(ConvertToIntegerWord(2.5,FE_TONEAREST)));
  Check("fctiw up",3u,static_cast<std::uint32_t>(ConvertToIntegerWord(2.1,FE_UPWARD)));
  Check("fctiw down",0xfffffffdu,static_cast<std::uint32_t>(ConvertToIntegerWord(-2.1,FE_DOWNWARD)));
  const auto divideZero=EvaluateScalar([] { volatile double one=1.0,zero=0.0; return one/zero; });
  Check("divide zero result",0x7ff0000000000000ULL,std::bit_cast<std::uint64_t>(divideZero.value));
  Check("divide zero flag",1u<<3,divideZero.flags.bits());
  const auto invalid=EvaluateScalar([] { volatile double zero=0.0; return zero/zero; });
  Check("invalid class",1u,std::isnan(invalid.value)?1u:0u);
  Check("invalid flag",1u,invalid.flags.bits()&1u);
  const auto overflow=EvaluateScalar([] { volatile double value=std::numeric_limits<double>::max(); return value*2.0; });
  Check("overflow class",1u,std::isinf(overflow.value)?1u:0u);
  Check("overflow flag",1u,overflow.flags.overflow?1u:0u);
  const auto underflow=EvaluateScalar([] { volatile double value=std::numeric_limits<double>::min(); return value*value; });
  Check("underflow result",0u,std::bit_cast<std::uint64_t>(underflow.value));
  Check("underflow flag",1u,underflow.flags.underflow?1u:0u);
  Check("underflow inexact",1u,underflow.flags.inexact?1u:0u);
  const auto inexact=EvaluateScalar([] { volatile double one=1.0,three=3.0; return one/three; });
  Check("inexact flag",1u,inexact.flags.inexact?1u:0u);
  Check("fma single rounding",0x3f800000u,std::bit_cast<std::uint32_t>(std::fma(0x1.000002p0f,0x1.fffffep-1f,-0x1p-24f)));
  Check("force25",0x3ff0000010000000ULL,std::bit_cast<std::uint64_t>(Force25Bit(0x1.0000008000001p0)));

  Check("FPSCR first invalid",0xa0800000u,
        SetFpscrException(0u,fpscr::VXISI));
  Check("FPSCR repeated invalid sticky FX",0xa0800000u,
        SetFpscrException(0xa0800000u,fpscr::VXISI));
  Check("FPSCR invalid enabled summary",0xe0800080u,
        SetFpscrException(fpscr::VE,fpscr::VXISI));
  Check("FPSCR divide enabled summary",0xc4000010u,
        SetFpscrException(fpscr::ZE,fpscr::ZX));
  Check("FPSCR mixed summaries",0xfe8000f8u,
        SetFpscrException(fpscr::VE|fpscr::OE|fpscr::UE|fpscr::ZE|fpscr::XE,
                          fpscr::VXISI|fpscr::OX|fpscr::UX|fpscr::ZX|fpscr::XX));
  Check("FPSCR invalid write suppressed",1u,
        FpscrExceptionEnabled(fpscr::VE,fpscr::VXIMZ)?1u:0u);
  Check("FPSCR disabled write allowed",0u,
        FpscrExceptionEnabled(0u,fpscr::VXIMZ)?1u:0u);
  Check("FPRF qnan",0x00011000u,SetFprf(0u,ClassifyDouble(
        std::numeric_limits<double>::quiet_NaN())));
  Check("FPRF negative infinity",0x00009000u,SetFprf(0u,ClassifyDouble(
        -std::numeric_limits<double>::infinity())));
  Check("FPRF negative normal",0x00008000u,SetFprf(0u,ClassifyDouble(-1.0)));
  Check("FPRF negative denormal",0x00018000u,SetFprf(0u,ClassifyDouble(
        -std::numeric_limits<double>::denorm_min())));
  Check("FPRF negative zero",0x00012000u,SetFprf(0u,ClassifyDouble(-0.0)));
  Check("FPRF positive zero",0x00002000u,SetFprf(0u,ClassifyDouble(0.0)));
  Check("FPRF positive denormal",0x00014000u,SetFprf(0u,ClassifyFloat(
        std::numeric_limits<float>::denorm_min())));
  Check("FPRF positive normal",0x00004000u,SetFprf(0u,ClassifyFloat(1.0f)));
  Check("FPRF positive infinity",0x00005000u,SetFprf(0u,ClassifyFloat(
        std::numeric_limits<float>::infinity())));
  const auto snan=std::bit_cast<double>(0x7ff0000000000042ULL);
  Check("sNaN detect",1u,IsSignalingNan(snan)?1u:0u);
  Check("sNaN quiet payload",0x7ff8000000000042ULL,
        std::bit_cast<std::uint64_t>(QuietNan(snan)));

  const auto invalidAdd=EvaluatePpcScalarBinary(
      0u,ScalarFpBinaryOperation::Add,
      std::numeric_limits<double>::infinity(),
      -std::numeric_limits<double>::infinity(),false);
  Check("fadd invalid cause",fpscr::FX|fpscr::VX|fpscr::VXISI,
        invalidAdd.fpscr&~fpscr::FPRF);
  Check("fadd canonical NaN",0x7ff8000000000000ULL,
        std::bit_cast<std::uint64_t>(invalidAdd.value));
  Check("fadd disabled writes",1u,invalidAdd.write_destination?1u:0u);
  const auto suppressedAdd=EvaluatePpcScalarBinary(
      fpscr::VE,ScalarFpBinaryOperation::Add,
      std::numeric_limits<double>::infinity(),
      -std::numeric_limits<double>::infinity(),false);
  Check("fadd enabled suppresses",0u,suppressedAdd.write_destination?1u:0u);
  Check("fadd enabled summary",fpscr::FX|fpscr::FEX|fpscr::VX|fpscr::VXISI|fpscr::VE,
        suppressedAdd.fpscr);
  const auto invalidMultiply=EvaluatePpcScalarBinary(
      0u,ScalarFpBinaryOperation::Multiply,
      std::numeric_limits<double>::infinity(),0.0,false);
  Check("fmul invalid cause",fpscr::VXIMZ,invalidMultiply.exception&fpscr::VX_ANY);
  const auto invalidZeroDivide=EvaluatePpcScalarBinary(
      0u,ScalarFpBinaryOperation::Divide,0.0,0.0,false);
  Check("fdiv zero zero cause",fpscr::VXZDZ,
        invalidZeroDivide.exception&fpscr::VX_ANY);
  const auto invalidInfinityDivide=EvaluatePpcScalarBinary(
      0u,ScalarFpBinaryOperation::Divide,
      std::numeric_limits<double>::infinity(),
      std::numeric_limits<double>::infinity(),false);
  Check("fdiv infinity cause",fpscr::VXIDI,
        invalidInfinityDivide.exception&fpscr::VX_ANY);
  const auto divideEnabled=EvaluatePpcScalarBinary(
      fpscr::ZE,ScalarFpBinaryOperation::Divide,1.0,0.0,false);
  Check("fdiv zero cause",fpscr::ZX,divideEnabled.exception&fpscr::ZX);
  Check("fdiv enabled suppresses",0u,divideEnabled.write_destination?1u:0u);
  const auto snanAdd=EvaluatePpcScalarBinary(
      0u,ScalarFpBinaryOperation::Add,snan,1.0,false);
  Check("fadd sNaN cause",fpscr::VXSNAN,snanAdd.exception&fpscr::VX_ANY);
  Check("fadd sNaN payload",0x7ff8000000000042ULL,
        std::bit_cast<std::uint64_t>(snanAdd.value));
  const auto negativeSqrt=EvaluatePpcSqrt(fpscr::VE,-1.0);
  Check("fsqrt cause",fpscr::VXSQRT,negativeSqrt.exception&fpscr::VX_ANY);
  Check("fsqrt enabled suppresses",0u,negativeSqrt.write_destination?1u:0u);
  const auto positiveSingle=EvaluatePpcScalarBinary(
      0u,ScalarFpBinaryOperation::Add,1.0,2.0,true);
  Check("single result FPRF",0x00004000u,
        positiveSingle.fpscr&fpscr::FPRF);
  const auto convertExact=EvaluatePpcConvertToInteger(
      0x00005000u,2.0,FE_TONEAREST);
  Check("fctiw exact bits",0xfff8000000000002ULL,
        std::bit_cast<std::uint64_t>(convertExact.value));
  Check("fctiw preserves FPRF",0x00005000u,
        convertExact.fpscr&fpscr::FPRF);
  const auto convertInexact=EvaluatePpcConvertToInteger(0u,2.75,FE_TOWARDZERO);
  Check("fctiw inexact word",0x00000002u,
        static_cast<std::uint32_t>(std::bit_cast<std::uint64_t>(convertInexact.value)));
  Check("fctiw FI XX",fpscr::FX|fpscr::FI|fpscr::XX,
        convertInexact.fpscr&(fpscr::FX|fpscr::FI|fpscr::FR|fpscr::XX));
  const auto convertUp=EvaluatePpcConvertToInteger(0u,2.25,FE_UPWARD);
  Check("fctiw FR",fpscr::FR,convertUp.fpscr&fpscr::FR);
  const auto convertNegativeZero=EvaluatePpcConvertToInteger(0u,-0.0,FE_TOWARDZERO);
  Check("fctiw negative zero tag",0xfff8000100000000ULL,
        std::bit_cast<std::uint64_t>(convertNegativeZero.value));
  const auto convertInvalid=EvaluatePpcConvertToInteger(
      fpscr::VE,std::numeric_limits<double>::infinity(),FE_TONEAREST);
  Check("fctiw invalid cause",fpscr::VXCVI,
        convertInvalid.exception&fpscr::VX_ANY);
  Check("fctiw invalid suppress",0u,convertInvalid.write_destination?1u:0u);
  const auto convertSnan=EvaluatePpcConvertToInteger(0u,snan,FE_TONEAREST);
  Check("fctiw sNaN causes",fpscr::VXSNAN|fpscr::VXCVI,
        convertSnan.exception&fpscr::VX_ANY);
  const auto fusedProductInvalid=EvaluatePpcFused(
      0u,std::numeric_limits<double>::infinity(),0.0,1.0,false,false,false);
  Check("fmadd product invalid",fpscr::VXIMZ,
        fusedProductInvalid.exception&fpscr::VX_ANY);
  const auto fusedAddInvalid=EvaluatePpcFused(
      0u,std::numeric_limits<double>::infinity(),1.0,
      -std::numeric_limits<double>::infinity(),false,false,false);
  Check("fmadd add invalid",fpscr::VXISI,
        fusedAddInvalid.exception&fpscr::VX_ANY);
  const auto fusedSuppressed=EvaluatePpcFused(
      fpscr::VE,std::numeric_limits<double>::infinity(),0.0,1.0,
      false,true,false);
  Check("fmadds enabled suppress",0u,fusedSuppressed.write_destination?1u:0u);
  const auto fusedNanOrder=EvaluatePpcFused(
      0u,std::bit_cast<double>(0x7ff8000000000011ULL),2.0,
      std::bit_cast<double>(0x7ff8000000000022ULL),false,false,false);
  Check("fmadd NaN operand order",0x7ff8000000000011ULL,
        std::bit_cast<std::uint64_t>(fusedNanOrder.value));
  const auto fusedNegated=EvaluatePpcFused(0u,2.0,3.0,1.0,false,false,true);
  Check("fnmadd negated",0xc01c000000000000ULL,
        std::bit_cast<std::uint64_t>(fusedNegated.value));
}

void EstimateSuite() {
  const std::array<std::uint64_t,14> values={0x0000000000000000ULL,0x8000000000000000ULL,0x3ff0000000000000ULL,0x4000000000000000ULL,0x3fd5555555555555ULL,0x0010000000000000ULL,0x0000000000000001ULL,0x7fefffffffffffffULL,0x7ff0000000000000ULL,0xfff0000000000000ULL,0x7ff0000000000001ULL,0x7ff8000012345678ULL,0xbff0000000000000ULL,0x4010000000000000ULL};
  const std::array<std::uint64_t,14> fres={0x7ff0000000000000ULL,0xfff0000000000000ULL,0x3fefff0000000000ULL,0x3fdfff0000000000ULL,0x40080042e0000000ULL,0x47efffffe0000000ULL,0x47efffffe0000000ULL,0x0000000000000000ULL,0x0000000000000000ULL,0x8000000000000000ULL,0x7ff8000000000001ULL,0x7ff8000012345678ULL,0xbfefff0000000000ULL,0x3fcfff0000000000ULL};
  const std::array<std::uint64_t,14> frsqrte={0x7ff0000000000000ULL,0xfff0000000000000ULL,0x3feffe8000000000ULL,0x3fe69fa000000000ULL,0x3ffbb6f860000000ULL,0x5fdffe8000000000ULL,0x617ffe8000000000ULL,0x1ff000082c000000ULL,0x0000000000000000ULL,0x7ff8000000000000ULL,0x7ff8000000000001ULL,0x7ff8000012345678ULL,0x7ff8000000000000ULL,0x3fdffe8000000000ULL};
  for(std::size_t i=0;i<values.size();++i) { const double input=std::bit_cast<double>(values[i]); Check("Dolphin fres oracle",fres[i],std::bit_cast<std::uint64_t>(ApproximateReciprocal(input))); Check("Dolphin frsqrte oracle",frsqrte[i],std::bit_cast<std::uint64_t>(ApproximateReciprocalSquareRoot(input))); }
}

std::uint64_t PairBits(PairedSingle value) { return (static_cast<std::uint64_t>(std::bit_cast<std::uint32_t>(value.ps0))<<32)|std::bit_cast<std::uint32_t>(value.ps1); }
void PairedAndQuantizedSuite() {
  const PairedSingle a{1.5f,-0.0f},b{2.0f,-4.0f};
  Check("ps add",0x40600000c0800000ULL,PairBits(PsAdd(a,b)));
  Check("ps sub",0xbf00000040800000ULL,PairBits(PsSub(a,b)));
  Check("ps mul",0x4040000000000000ULL,PairBits(PsMul(a,b)));
  Check("ps div",0x3f40000000000000ULL,PairBits(PsDiv(a,b)));
  Check("ps madd",0x40a0000041800000ULL,PairBits(PsMadd(a,b,PairedSingle{2.0f,16.0f})));
  Check("ps msub",0x3f800000c1800000ULL,PairBits(PsMsub(a,b,PairedSingle{2.0f,16.0f})));
  Check("ps madds0",0x40a0000041800000ULL,PairBits(PsMadds0(a,b,PairedSingle{2.0f,16.0f})));
  Check("ps madds1",0xc080000041800000ULL,PairBits(PsMadds1(a,b,PairedSingle{2.0f,16.0f})));
  Check("ps muls0",0x4040000080000000ULL,PairBits(PsMuls0(a,b)));
  Check("ps muls1",0xc0c0000000000000ULL,PairBits(PsMuls1(a,b)));
  Check("ps neg",0xbfc0000000000000ULL,PairBits(PsNeg(a)));
  Check("ps abs",0x3fc0000000000000ULL,PairBits(PsAbs(a)));
  Check("ps nabs",0xbfc0000080000000ULL,PairBits(PsNabs(a)));
  Check("ps sum0",0xc020000041800000ULL,PairBits(PsSum0(a,b,PairedSingle{2.0f,16.0f})));
  Check("ps sum1",0x40000000c0200000ULL,PairBits(PsSum1(a,b,PairedSingle{2.0f,16.0f})));
  Check("ps merge00",0x3fc0000040000000ULL,PairBits(PsMerge00(a,b)));
  Check("ps merge01",0x3fc00000c0800000ULL,PairBits(PsMerge01(a,b)));
  Check("ps merge10",0x8000000040000000ULL,PairBits(PsMerge10(a,b)));
  Check("ps merge11",0x80000000c0800000ULL,PairBits(PsMerge11(a,b)));
  Check("ps select",0x3fc00000c0800000ULL,PairBits(PsSelect(a,PairedSingle{0.0f,-1.0f},b)));
  Check("dequant signed16",0xc2480000u,std::bit_cast<std::uint32_t>(Dequantize(-100,1)));
  Check("dequant wrapped scale",0x43000000u,std::bit_cast<std::uint32_t>(Dequantize(1,57)));
  Check("quant signed8 clamp",0x7fu,static_cast<std::uint8_t>(Quantize<std::int8_t>(100.0f,1)));
  Check("quant unsigned16",0x180u,Quantize<std::uint16_t>(1.5f,8));
  Check("ps compare less",8u,ComparePairedLane(-1.0f,1.0f));
  Check("ps compare unordered",1u,ComparePairedLane(std::numeric_limits<float>::quiet_NaN(),1.0f));
  std::array<std::uint8_t,8> quantized{};
  const std::array<QuantizedType,5> types={QuantizedType::Float,QuantizedType::Unsigned8,
    QuantizedType::Unsigned16,QuantizedType::Signed8,QuantizedType::Signed16};
  for(const auto type:types) for(const std::uint32_t scale:{0u,1u,31u,32u,57u,63u}) {
    quantized.fill(0xccu);
    const PairedSingle source=type==QuantizedType::Unsigned8||type==QuantizedType::Unsigned16
      ? PairedSingle{1.0f,2.0f}:PairedSingle{-1.0f,2.0f};
    StoreQuantizedPair(quantized.data(),{type,scale},false,source);
    const auto loaded=LoadQuantizedPair(quantized.data(),{type,scale},false);
    if(type==QuantizedType::Float) Check("GQR float roundtrip",PairBits(source),PairBits(loaded));
    else { Mix(PairBits(loaded)); ++g_checks; }
    quantized.fill(0xccu);
    StoreQuantizedPair(quantized.data(),{type,scale},true,source);
    const auto single=LoadQuantizedPair(quantized.data(),{type,scale},true);
    Check("GQR W=1 second lane",0x3f800000u,std::bit_cast<std::uint32_t>(single.ps1));
  }

  // Differential/property corpus. Inputs stay finite so NaN payload selection
  // does not obscure a genuine host-architecture mismatch.
  std::mt19937 rng(0x504f5745u);
  for(std::uint32_t i=0;i<50000;++i) {
    const auto finite=[](std::uint32_t bits) {
      bits=(bits&0x807fffffu)|(((bits>>23)%254u+1u)<<23);
      return std::bit_cast<float>(bits);
    };
    const PairedSingle x{finite(rng()),finite(rng())};
    const PairedSingle y{finite(rng()),finite(rng())};
    const PairedSingle z{finite(rng()),finite(rng())};
    Mix(PairBits(PsAdd(x,y)));
    Mix(PairBits(PsMul(x,y)));
    Mix(PairBits(PsMadd(x,y,z)));
    Mix(PairBits(PsMsub(x,y,z)));
    Mix(PairBits(PsNmadd(x,y,z)));
    Mix(PairBits(PsNmsub(x,y,z)));
    Mix(PairBits(PsMadds0(x,y,z)));
    Mix(PairBits(PsMadds1(x,y,z)));
    Mix(PairBits(PsMuls0(x,y)));
    Mix(PairBits(PsMuls1(x,y)));
    ++g_checks;
  }
}

extern "C" std::uint64_t AbiHostCall(std::uint32_t a,std::uint64_t b,double c,PairedSingle d) { return static_cast<std::uint64_t>(a)+b+static_cast<std::uint64_t>(c)+std::bit_cast<std::uint32_t>(d.ps0)+std::bit_cast<std::uint32_t>(d.ps1); }
void AbiSuite() { Check("host ABI",0x801000008000000bULL,AbiHostCall(7,0x8010000000000000ULL,4.0,{0.0f,-0.0f})); }
}

int main() {
  IntegerSuite(); ScalarSuite(); EstimateSuite(); PairedAndQuantizedSuite(); AbiSuite();
#if defined(__aarch64__)
  constexpr std::string_view architecture="arm64";
#elif defined(__x86_64__)
  constexpr std::string_view architecture="x86_64";
#else
  constexpr std::string_view architecture="unknown";
#endif
  std::cout<<"architecture="<<architecture<<" checks="<<std::dec<<g_checks<<" stateHash=0x"<<std::hex<<std::setw(16)<<std::setfill('0')<<g_hash<<" fpContract=off fastMath=off\n";
}
