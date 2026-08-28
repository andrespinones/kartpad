#include <cstdint>
#include "ppc_runtime.h"
#include "abi_bridge.h"
#include "memory.h"
#include "recomp_mod_loader.h"

extern "C" void func_80001000(CpuContext* MKW_RESTRICT ctx)
{
    uint32_t r3 = ctx->gpr[3];
    uint32_t r4 = ctx->gpr[4];

    goto loc_80001000;

loc_80001000:
{
    r3 = 0x80010000u;
    r3 = (r3 | 0);
    r4 = 1263534080;
    r4 = (r4 | 17478);
    MemoryInline::FlatWriteRam32(r3, r4);
    r4 = 0;
    r4 = (r4 | 256);
    MemoryInline::FlatWriteRam32((r3 + 4), r4);
    r4 = 0;
    r4 = (r4 | 192);
    MemoryInline::FlatWriteRam32((r3 + 8), r4);
    r4 = 609746944;
    r4 = (r4 | 43263);
    MemoryInline::FlatWriteRam32((r3 + 12), r4);
    ctx->gpr[3] = r3;
    ctx->gpr[4] = r4;
    return;
}

}

// RECOMP_GUEST_ABI gpr_read=0x00000000 gpr_write=0x00000018 gpr_return=0x00000018 fpr_read=0x00000000 fpr_write=0x00000000 fpr_return=0x00000000 cr_read=0x00 cr_write=0x00 xer_read=0 xer_write=0 fence=0
// RECOMP_REGISTRATION base 0x80001000 func_80001000 preserves=true fpr_mask=0x00000000
