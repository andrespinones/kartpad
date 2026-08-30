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
    uint32_t r6_psq_tmp_2 = 0;
    uint32_t r6_psq_tmp_3 = 0;
    uint8_t* guest_range_0 = nullptr;

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
    PPC_FPR f9 = ctx->fpr[9];
    PPC_FPR f10 = ctx->fpr[10];
    PPC_FPR f11 = ctx->fpr[11];
    PPC_FPR f12 = ctx->fpr[12];
    PPC_FPR f13 = ctx->fpr[13];
    PPC_FPR f14 = ctx->fpr[14];
    PPC_FPR f15 = ctx->fpr[15];
    PPC_FPR f16 = ctx->fpr[16];
    PPC_FPR f17 = ctx->fpr[17];
    PPC_FPR f18 = ctx->fpr[18];
    PPC_FPR f19 = ctx->fpr[19];
    PPC_FPR f20 = ctx->fpr[20];
    PPC_FPR f21 = ctx->fpr[21];
    PPC_FPR f22 = ctx->fpr[22];
    PPC_FPR f23 = ctx->fpr[23];
    PPC_FPR f24 = ctx->fpr[24];
    PPC_FPR f25 = ctx->fpr[25];
    PPC_FPR f26 = ctx->fpr[26];
    uint32_t cr = ctx->cr;

    [[maybe_unused]] uint32_t mkw_gqr0 = ctx->gqr[0];

    goto loc_80001000;

[[maybe_unused]] loc_80001000:
{
    r3 = 0x80010000u;
    r3 = (r3 | 0);
    r4 = 32767;
    r5 = (r4 + r4);
    MemoryInline::FlatWriteRam32(r3, r5);
    r6 = 0x80010000u;
    r6 = (r6 | 4096);
    guest_range_0 = MemoryInline::ResolveRangeHost(r6, 0, 48u, true, false);
    {
        const auto resolved_pair = MemoryInline::ReadResolvedPair32(guest_range_0, 0u);
        if (resolved_pair.valid) {
            f1.d = PpcBitCastToFloatInline(resolved_pair.first);
            f2.d = PpcBitCastToFloatInline(resolved_pair.second);
        } else {
            f1.d = MemoryInline::ReadResolvedFloat32(guest_range_0, 0u, r6);
            f2.d = MemoryInline::ReadResolvedFloat32(guest_range_0, 4u, (r6 + 4));
        }
    }
    PpcFaddsStateInline(f3.d, f1.d, f2.d);
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
    f7.d = MemoryInline::ReadResolvedFloat32(guest_range_0, 24u, (r6 + 24));
    PpcFdivsStateInline(f8.d, f1.d, f7.d);
    MemoryInline::FlatWriteRamFloat32((r3 + 16), f8.d);
    {
        const auto resolved_pair = MemoryInline::ReadResolvedPair32(guest_range_0, 28u);
        if (resolved_pair.valid) {
            f9.d = PpcBitCastToFloatInline(resolved_pair.first);
            f10.d = PpcBitCastToFloatInline(resolved_pair.second);
        } else {
            f9.d = MemoryInline::ReadResolvedFloat32(guest_range_0, 28u, (r6 + 28));
            f10.d = MemoryInline::ReadResolvedFloat32(guest_range_0, 32u, (r6 + 32));
        }
    }
    PpcFaddsStateInline(f11.d, f9.d, f10.d);
    MemoryInline::FlatWriteRamFloat32((r3 + 20), f11.d);
    PPC_Mtfsb1(24);
    f12.d = MemoryInline::ReadResolvedFloat32(guest_range_0, 36u, (r6 + 36));
    PpcFaddsStateInline(f12.d, f9.d, f10.d);
    MemoryInline::FlatWriteRamFloat32((r3 + 24), f12.d);
    f13.d = MemoryInline::ReadResolvedFloat32(guest_range_0, 40u, (r6 + 40));
    PpcFctiwzStateInline(f14.d, f13.d);
    PpcFctiwStateInline(f15.d, f13.d);
    PpcFctiwStateInline(f13.d, f9.d);
    f16.d = MemoryInline::ReadResolvedFloat32(guest_range_0, 36u, (r6 + 36));
    PpcFmaddsStateInline(f16.d, f9.d, f7.d, f1.d);
    PPC_Mtfsb1(27);
    f17.d = MemoryInline::ReadResolvedFloat32(guest_range_0, 36u, (r6 + 36));
    PpcSetPairedFprInline(f17, PpcFresValueStateInline(f17.d, f7.d));
    f18.d = MemoryInline::ReadResolvedFloat32(guest_range_0, 36u, (r6 + 36));
    f19.d = MemoryInline::ReadResolvedFloat32(guest_range_0, 12u, (r6 + 12));
    PpcFrsqrteStateInline(f18.d, f19.d);
    // psq_load w=0 quant=0 (using PPC_PsqL)
    r6_psq_tmp_2 = (r6 + 24);
    PpcSetPairedFprInline(f20, PPC_PsqLGqrInline<0u, 0u>(ctx, mkw_gqr0, r6_psq_tmp_2));
    PpcSetPairedFprInline(f21, PPC_PsRes(f20.d));
    PpcSetPairedFprInline(f22, PPC_PsRsqrte(f4.d));
    // psq_load w=0 quant=0 (using PPC_PsqL)
    r6_psq_tmp_3 = (r6 + 28);
    PpcSetPairedFprInline(f24, PPC_PsqLGqrInline<0u, 0u>(ctx, mkw_gqr0, r6_psq_tmp_3));
    PpcSetPairedFprInline(f25, PPC_PsNegInline(f24.d));
    PpcSetPairedFprInline(f26, PPC_PsAddInline(f24.d, f25.d));
    f23.d = MemoryInline::ReadResolvedFloat32(guest_range_0, 44u, (r6 + 44));
    (void)PpcCompareStateInline(true, f23.d, f1.d);
    SetCRFloatResident(cr, 3, f23.d, f1.d);
}

[[maybe_unused]] loc_800010B8:
{
    (void)PpcCompareStateInline(false, f23.d, f1.d);
    SetCRFloatResident(cr, 4, f23.d, f1.d);
}

[[maybe_unused]] loc_800010BC:
{
    (void)PpcCompareStateInline(true, PpcGetPs0Inline(PPC_PsFromScalarInline(f23.d)), PpcGetPs0Inline(PPC_PsFromScalarInline(f1.d)));
    SetCRFloatResident(cr, static_cast<uint32_t>(5) & 7u, PpcGetPs0Inline(PPC_PsFromScalarInline(f23.d)), PpcGetPs0Inline(PPC_PsFromScalarInline(f1.d)));
}

[[maybe_unused]] loc_800010C0:
{
    (void)PpcCompareStateInline(false, PpcGetPs0Inline(PPC_PsFromScalarInline(f23.d)), PpcGetPs0Inline(PPC_PsFromScalarInline(f1.d)));
    SetCRFloatResident(cr, static_cast<uint32_t>(6) & 7u, PpcGetPs0Inline(PPC_PsFromScalarInline(f23.d)), PpcGetPs0Inline(PPC_PsFromScalarInline(f1.d)));
}

[[maybe_unused]] loc_800010C4:
{
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
    ctx->fpr[9] = f9;
    ctx->fpr[10] = f10;
    ctx->fpr[11] = f11;
    ctx->fpr[12] = f12;
    ctx->fpr[13] = f13;
    ctx->fpr[14] = f14;
    ctx->fpr[15] = f15;
    ctx->fpr[16] = f16;
    ctx->fpr[17] = f17;
    ctx->fpr[18] = f18;
    ctx->fpr[19] = f19;
    ctx->fpr[20] = f20;
    ctx->fpr[21] = f21;
    ctx->fpr[22] = f22;
    ctx->fpr[23] = f23;
    ctx->fpr[24] = f24;
    ctx->fpr[25] = f25;
    ctx->fpr[26] = f26;
    ctx->cr = cr;
    return;
}

}

// RECOMP_GUEST_ABI gpr_read=0x00000000 gpr_write=0x00000078 gpr_return=0x00000018 fpr_read=0x00800002 fpr_write=0x07FFFFFE fpr_return=0x00000002 cr_read=0xFF cr_write=0x78 xer_read=1 xer_write=0 fence=0
// RECOMP_REGISTRATION base 0x80001000 func_80001000 preserves=false fpr_mask=0x0777C000
