#pragma once

#include "kartpad/memory/checked_guest_memory.h"

struct CpuContext;

namespace kartpad::translation {

void BindFixtureMemory(memory::CheckedGuestMemory& memory);
void UnbindFixtureMemory();
void RunG7TranslatedFrame(CpuContext& context);

}  // namespace kartpad::translation
