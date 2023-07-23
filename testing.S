#include "macros.h"
.include "trap_handler.S"
#.include "func1.s"
.equiv PMP_REG0_TOR, 0x80000800

.equiv PMP_REG1_NAPOT, 0x80002000
.text
.global _start
_start:

    
    la t1, pgtb_l0
    mv a1, t1

    GEN_VA(a1, a0, 0x280, 0x002)
    li a2, 0x001

    PTE_SETUP_RV32(a1, a2, t1, a0, 1)

    la t1, code 
    mv   a1,      t1
    GEN_VA(a1, a0, 0x280, 0x000)
    mv t3, a0
    li a2, 0x0CF

    PTE_SETUP_RV32(a1, a2, t1, a0, 0)

    la t1, arr
    mv a1, t1
    GEN_VA(a1, a0, 0x280, 0x004)
    mv t4, a0
    li a2, 0x0C3
 
    PTE_SETUP_RV32(a1, a2, t1, a0, 0)
    SATP_SETUP_SV32 
    

    la t2, trap_handler
    WRITE_CSR (mtvec, t2)
    WRITE_CSR (mepc, t3)
    li t2, 0x1800
    CLEAR_CSR (mstatus, t2)
    li t2,  0xC0800
    SET_CSR (mstatus, t2)
    
    # # TOR upto 0x80000800
    li t0, PMP_REG0_TOR;
    srli t0, t0, 2;
    csrw pmpaddr0, t0;
    sfence.vma

    # # 32 Bytes NAPOT from 0x80001000
    # li t0, PMP_REG1_NAPOT;
    # srli t0, t0, 2;
    # ori t0, t0, 3;
    # csrw pmpaddr1, t0; 

    li t0, 0x07071988;
    csrw pmpcfg0, t0;

    sfence.vma

    MRET

code:
    li   t5,      0xA0004000
    lw   t6,      0(t5)
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
