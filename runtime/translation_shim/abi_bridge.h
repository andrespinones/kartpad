#pragma once

#include <cstdint>

struct CpuContext;

// G6's translation-surface compile does not dispatch a game call.  These
// declarations preserve the exact call shapes emitted by WiiCompiled while
// the executable runtime supplies the real registry-backed dispatch.
template <std::uint32_t Target>
void InvokeDirectCpu(CpuContext* context);

void InvokeIndirectCpu(std::uint32_t target, CpuContext* context);
void InvokeIndirectJump(std::uint32_t target, CpuContext* context);

inline constexpr bool MkwStateFreeAbiEnabled(std::uint32_t) noexcept { return true; }

template <std::uint32_t Target>
struct KnownTranslatedCpuCall {
  static constexpr bool kAvailable = false;
  static constexpr bool kMustRemainDynamicallyDispatchable = true;
};

template <std::uint32_t Target>
inline bool IsBaseTranslatedCpuTargetActive() { return false; }
