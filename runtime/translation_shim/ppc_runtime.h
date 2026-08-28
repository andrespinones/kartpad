#pragma once

#include <array>
#include <bit>
#include <cstdint>

#include "kartpad/semantics/ppc_semantics.h"

#if defined(__clang__) || defined(__GNUC__)
#define MKW_RESTRICT __restrict
#else
#define MKW_RESTRICT
#endif

struct CpuContext {
  std::array<std::uint32_t, 32> gpr{};
  struct Fpr { double d{}; };
  std::array<Fpr, 32> fpr{};
};

using PPC_FPR = CpuContext::Fpr;

inline float PpcForceSingleValueInline(double value) {
  return kartpad::semantics::ForceSingle(value);
}
