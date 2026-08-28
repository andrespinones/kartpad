#include <cstdint>
#include "ppc_runtime.h"
#include "abi_bridge.h"
#include "memory.h"
#include "recomp_mod_loader.h"

extern "C" void func_80001000(CpuContext* MKW_RESTRICT ctx)
{
    uint32_t r3_psq_tmp_0 = 0;
    uint32_t r6_psq_tmp_0 = 0;
    uint32_t r6_psq_tmp_1 = 0;

    uint32_t r3 = ctx->gpr[3];
    uint32_t r4 = ctx->gpr[4];
    uint32_t r5 = ctx->gpr[5];
    uint32_t r6 = ctx->gpr[6];
    PPC_FPR f1 = ctx->fpr[1];
    PPC_FPR f2 = ctx->fpr[2];
    PPC_FPR f3 = ctx->fpr[3];
    PPC_FPR f4 = ctx->fpr[4];
    PPC_FPR f5 = ctx->fpr[5];
    PPC_FPR f6 = ctx->fpr[6];
    PPC_FPR f7 = ctx->fpr[7];
    PPC_FPR f8 = ctx->fpr[8];

    [[maybe_unused]] uint32_t mkw_gqr0 = ctx->gqr[0];

    goto loc_80001000;

loc_80001000:
{
    r3 = 0x80010000u;
    r3 = (r3 | 0);
    r4 = 32767;
    r5 = (r4 + r4);
    MemoryInline::FlatWriteRam32(r3, r5);
    r6 = 0x80010000u;
    r6 = (r6 | 4096);
    f1.d = MemoryInline::FlatReadFloat32(r6);
    f2.d = MemoryInline::FlatReadFloat32((r6 + 4));
    f3.d = static_cast<double>(PpcForceSingleValueInline(f1.d + f2.d));
    MemoryInline::FlatWriteRamFloat32((r3 + 4), f3.d);
    // psq_load w=0 quant=0 (using PPC_PsqL)
    r6_psq_tmp_0 = (r6 + 8);
    PpcSetPairedFprInline(f4, PPC_PsqLGqrInline<0u, 0u>(ctx, mkw_gqr0, r6_psq_tmp_0));
    // psq_load w=0 quant=0 (using PPC_PsqL)
    r6_psq_tmp_1 = (r6 + 16);
    PpcSetPairedFprInline(f5, PPC_PsqLGqrInline<0u, 0u>(ctx, mkw_gqr0, r6_psq_tmp_1));
    PpcSetPairedFprInline(f6, PPC_PsAddInline(f4.d, f5.d));
    // psq_store w=0 quant=0 (using PPC_PsqSt)
    r3_psq_tmp_0 = (r3 + 8);
    PPC_PsqStGqrInline<0u, 0u>(ctx, mkw_gqr0, r3_psq_tmp_0, f6.d);
    f7.d = MemoryInline::FlatReadFloat32((r6 + 24));
    f8.d = static_cast<double>(PpcForceSingleValueInline(f1.d / f7.d));
    MemoryInline::FlatWriteRamFloat32((r3 + 16), f8.d);
    ctx->gpr[3] = r3;
    ctx->gpr[4] = r4;
    ctx->gpr[5] = r5;
    ctx->gpr[6] = r6;
    ctx->fpr[1] = f1;
    ctx->fpr[2] = f2;
    ctx->fpr[3] = f3;
    ctx->fpr[4] = f4;
    ctx->fpr[5] = f5;
    ctx->fpr[6] = f6;
    ctx->fpr[7] = f7;
    ctx->fpr[8] = f8;
    return;
}

}

// RECOMP_GUEST_ABI gpr_read=0x00000000 gpr_write=0x00000078 gpr_return=0x00000018 fpr_read=0x00000000 fpr_write=0x000001FE fpr_return=0x00000002 cr_read=0x00 cr_write=0x00 xer_read=0 xer_write=0 fence=0
// RECOMP_REGISTRATION base 0x80001000 func_80001000 preserves=true fpr_mask=0x00000000
