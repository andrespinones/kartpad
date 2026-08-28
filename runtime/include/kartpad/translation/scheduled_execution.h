#pragma once

#include "kartpad/scheduler/guest_scheduler.h"

#include <functional>

struct CpuContext;

namespace kartpad::translation {

using TranslatedStep = std::function<void(CpuContext&)>;

void RunScheduledTranslatedStep(scheduler::GuestCpuContext& scheduled,
                                const TranslatedStep& step);

}  // namespace kartpad::translation
