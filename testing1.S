#include "macros.h"
.include "trap_handler.S"
#.include "func1.s"
.equiv PMP_REG0_TOR, 0x80000800
.equiv PMP_REG1_NAPOT, 0x80004000
.text
.global _start
_start:
    la t1, pgtb_l1
    la t1, code 
    mv   a1,      t1
    GEN_VA(a1, a0, 0x280, 0x000)
    mv t3, a0
    li a2, 0xCF

    PTE_SETUP_RV32(a1, a2, t1, a0, 1)

    la t1, arr
    mv a1, t1
    GEN_VA(a1, a0, 0x281, 0x004)
    mv t4, a0
    li a2, 0x0CF
 
    PTE_SETUP_RV32(a1, a2, t1, a0, 1)
    SATP_SETUP_SV32 
    

    la t2, trap_handler
    WRITE_CSR (mtvec, t2)
    WRITE_CSR (mepc, t3)
    li t2, 0x1800
    CLEAR_CSR (mstatus, t2)
    li t2,  0xC0800
    SET_CSR (mstatus, t2)

    MRET

code:
    li t0, 2;
    li t1, 3;
    add t0, t0, t1;
    #mv   t5,      t4
    lw   t6,      0(t4)
    sw   t6,      0(t5)
exit:
    la t0, tohost
    li t1, 1
    EXIT_LOGIC(t0, t1)
    j exit

.data


pgtb_l1:
    .zero 4096

pgtb_l0:
    .zero 4096

arr:
.word 0x23

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;
