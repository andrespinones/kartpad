#include "kartpad/translation/scheduled_execution.h"

#include "ppc_runtime.h"

#include <stdexcept>

namespace kartpad::translation {
namespace {

CpuContext LoadScheduledContext(const scheduler::GuestCpuContext& source) {
  CpuContext target{};
  target.gpr = source.gpr;
  for (std::size_t index = 0; index < target.fpr.size(); ++index)
    target.fpr[index].raw = source.fpr_bits[index];
  target.pc = source.pc;
  target.lr = source.lr;
  target.ctr = source.ctr;
  target.xer = source.xer;
  target.cr = source.cr;
  target.fpscr = source.fpscr;
  target.gqr = source.gqr;
  target.srr0 = source.srr0;
  target.srr1 = source.srr1;
  target.hid0 = source.hid0;
  target.hid1 = source.hid1;
  target.hid2 = source.hid2;
  target.msr = source.msr;
  target.time_base = source.time_base;
  return target;
}

void StoreScheduledContext(scheduler::GuestCpuContext& target,
                           const CpuContext& source) {
  target.gpr = source.gpr;
  for (std::size_t index = 0; index < source.fpr.size(); ++index)
    target.fpr_bits[index] = source.fpr[index].raw;
  target.pc = source.pc;
  target.lr = source.lr;
  target.ctr = source.ctr;
  target.xer = source.xer;
  target.cr = source.cr;
  target.fpscr = source.fpscr;
  target.gqr = source.gqr;
  target.srr0 = source.srr0;
  target.srr1 = source.srr1;
  target.hid0 = source.hid0;
  target.hid1 = source.hid1;
  target.hid2 = source.hid2;
  target.msr = source.msr;
  target.time_base = source.time_base;
}

}  // namespace

void RunScheduledTranslatedStep(scheduler::GuestCpuContext& scheduled,
                                const TranslatedStep& step) {
  if (!step)
    throw std::invalid_argument("translated scheduler step is empty");
  CpuContext active = LoadScheduledContext(scheduled);
  {
    CpuContextScope scope(&active);
    step(active);
  }
  StoreScheduledContext(scheduled, active);
}

}  // namespace kartpad::translation
