#include "macros.h"
.include "trap_handler.S"
#.include "func1.s"
.text
.global _start
_start:

    
    la   t1,      pgtb_l0
    mv   a1,      t1
    # li   a0,      0xA0002000
    GEN_VA(a1, a0, 0x280, 0x002)
    li   a2,      0x001
    # jal  func_pte
    PTE_SETUP_RV32(a1, a2, t1, a0, 1)

    la   t1,      code 
    mv   a1,      t1
    GEN_VA(a1, a0, 0x280, 0x000)
    mv t3, a0
    li   a2,      0x0CF
    # jal  func_pte
    PTE_SETUP_RV32(a1, a2, t1, a0, 0)

    la   t1,      arr
    mv   a1,      t1
    GEN_VA(a1, a0, 0x280, 0x004)
    mv t4, a0
    li   a2,      0x0C3
    # jal  func_pte
    PTE_SETUP_RV32(a1, a2, t1, a0, 0)

    SATP_SETUP_SV32 

    la   t2,      trap_handler
    csrw mtvec,   t2
    csrw mepc,    t3
    li   t2,      0x1800
    csrc mstatus, t2
    li   t2,      0xC0800
    csrs mstatus, t2
    mret

code:
    lw   t6,      0(t4)
exit:
    la t0, tohost
    EXIT_LOGIC(t0)
    j exit


.data

pgtb_l1:
    .zero 4096
.align 12
pgtb_l0:
    .zero 4096
pgtb_l0_1:
    .zero 4096
arr:
.word 0x23


.align 4; .global tohost;  tohost: .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;
