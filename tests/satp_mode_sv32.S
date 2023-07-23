#include "../macros.h"
.include "./trap_handler.S"
#.include "func1.s"

.text
.global _start
_start:

###########################################
#    | M-mode Configurations and code |   #
###########################################
M_Mode:

    la a1, pgtb_l0
    GEN_VA(a1, a0, 0x280, 0x002)
    SET_PTE_V(a2, FLUSH)

    PTE_SETUP_RV32(a1, a2, t1, a0, 1)

    la a1, S_Mode
    GEN_VA(a1, a0, 0x280, 0x000)
    mv t3, a0
    SET_RWXV_BITS(a2, FLUSH)
    SET_PTE_A(a2, NO_FLUSH)
    SET_PTE_D(a2, NO_FLUSH)

    PTE_SETUP_RV32(a1, a2, t1, a0, 0)

    la a1, arr
    GEN_VA(a1, a0, 0x280, 0x004)
    mv t4, a0
    SET_RV_BITS(a2, FLUSH)
    SET_PTE_A(a2, NO_FLUSH)
    SET_PTE_D(a2, NO_FLUSH)
 
    PTE_SETUP_RV32(a1, a2, t1, a0, 0)
    SATP_SETUP_SV32 

    la t2, trap_handler
    WRITE_CSR (mtvec, t2)
    WRITE_CSR (mepc, t3)
    li t2, 0x1800
    CLEAR_CSR (mstatus, t2)
    li t2,  0xC0800
    SET_CSR (mstatus, t2)
    MRET

###########################################
#    | S-mode Configurations and code |   #
###########################################
S_Mode:

    li   t5,      0xA0004000
    CHECK_SV32_MODE(t0)

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


.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;
