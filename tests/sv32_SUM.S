#include "macros.h"
#.include "func1.s"

.text
.globl rvtest_entry_point
rvtest_entry_point:

###########################################
#    | M-mode Configurations and code |   #
###########################################

    la a1, pgtb_l0
    GEN_VA(a1, a0, 0x280, 0x002)
    SET_PTE_V(a2, FLUSH)

    PTE_SETUP_RV32(a1, a2, t1, a0, 1)
    
    la a1, code
    GEN_VA(a1, a0, 0x280, 0x000)
    mv t3, a0
    SET_RWXV_BITS(a2, FLUSH)
    SET_PTE_A(a2, NO_FLUSH)
    SET_PTE_D(a2, NO_FLUSH)
    SET_PTE_U(a2, NO_FLUSH)

    PTE_SETUP_RV32(a1, a2, t1, a0, 0)
    
    la a1, arr
    GEN_VA(a1, a0, 0x280, 0x004)
    mv t4, a0
    SET_RV_BITS(a2, FLUSH)
    SET_PTE_A(a2, NO_FLUSH)
    SET_PTE_D(a2, NO_FLUSH)
    SET_PTE_U(a2, NO_FLUSH)
 
    PTE_SETUP_RV32(a1, a2, t1, a0, 0)
    
    SATP_SETUP_SV32 
    
    la t2, trap_handler
    WRITE_CSR (mtvec, t2)
    WRITE_CSR (mepc, t3)
    li t2, 0x1800
    CLEAR_CSR (mstatus, t2)
    li t2,  0x00800
    SET_CSR (mstatus, t2)
    MRET
###########################################
#    | S-mode Configurations and code |   #
###########################################
code:

    li   t5,      0xA0004000
    lw t6, 0(t5)
    addi t6, t6, 0x23
    sw t6, 0(t5)
    j exit

exit:
    li x1, 0
	slli x1, x1, 1
	addi x1, x1, 1
	sw x1, tohost, x30
	self_loop: j self_loop

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