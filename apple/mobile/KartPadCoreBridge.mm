#import "KartPadCoreBridge.h"

#include "kartpad/memory/checked_guest_memory.h"
#include "kartpad/platform/host_services.h"
#include "kartpad/scheduler/guest_scheduler.h"
#include "kartpad/translation/fixture_runtime.h"
#include "ppc_runtime.h"

#include <exception>
#include <stdexcept>

namespace {

constexpr std::uint32_t kCommandAddress = 0x80010000;

void RunTranslatedFixture() {
  kartpad::memory::CheckedGuestMemory memory;
  memory.Map({.guest_base = 0x80000000, .size = 0x20000, .backing = 1});
  CpuContext context{};
  kartpad::translation::BindFixtureMemory(memory);
  try {
    kartpad::translation::RunG7TranslatedFrame(context);
  } catch (...) {
    kartpad::translation::UnbindFixtureMemory();
    throw;
  }
  kartpad::translation::UnbindFixtureMemory();
  if (memory.LoadUnsigned(kCommandAddress, 4) != 0x4B504758 ||
      memory.LoadUnsigned(kCommandAddress + 4, 4) != 0x102030FF) {
    throw std::runtime_error("translated fixture output mismatch");
  }
}

void RunSchedulerFixture() {
  using kartpad::scheduler::GuestCpuContext;
  using kartpad::scheduler::GuestScheduler;
  using kartpad::scheduler::StepAction;
  GuestScheduler scheduler;
  const auto thread = scheduler.Create(
      1, "mobile-startup", GuestCpuContext{},
      [](GuestCpuContext &context) {
        context.gpr[3] = 0x4B50494F;
        return StepAction::Exit(0);
      },
      false);
  if (scheduler.Run(1) != 1 || !scheduler.Snapshot(thread).has_value() ||
      scheduler.Snapshot(thread)->context.gpr[3] != 0x4B50494F) {
    throw std::runtime_error("scheduler fixture output mismatch");
  }
}

}  // namespace

NSString *KartPadCoreIntegrationSummary(void) {
  try {
    RunTranslatedFixture();
    RunSchedulerFixture();
    if (kartpad::platform::MonotonicNanoseconds() == 0) {
      throw std::runtime_error("host clock unavailable");
    }
    return @"KartPad mobile core checks passed";
  } catch (const std::exception &error) {
    return [NSString stringWithFormat:@"KartPad mobile core check failed: %s", error.what()];
  }
}
