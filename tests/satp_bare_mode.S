# Test to show writing {zero, non-zero} value to satp when mode=bare and the behavior follows the design implementation.

#include "../macros.h"
.include "./trap_handler.S"

.text
.globl _start
_start:

    # Setting up page table with SV32 translation scheme
    la t1, pgtb_l0
    mv a1, t1

    GEN_VA(a1, a0, 0x280, 0x002)
    li a2, 0x001
    PTE_SETUP_RV32(a1, a2, t1, a0, 1)

    la t1, code
    mv a1, t1
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

    # Test case 1: Write zero to satp in "bare" mode (should be ignored)
    li t2, 0        # Write zero to satp
    WRITE_CSR(satp, t2)

    la t2, trap_handler
    WRITE_CSR(mtvec, t2)
    WRITE_CSR(mepc, t3)
    li t2, 0x1800
    CLEAR_CSR(mstatus, t2)
    li t2, 0xC0800
    SET_CSR(mstatus, t2)
    li t4, 0x444
    MRET

    # Test case 2: Write non-zero value to satp in "bare" mode (should be ignored)
Test_case_2:
    li t2, 0x123    # Write non-zero value to satp
    WRITE_CSR(satp, t2)

    WRITE_CSR(mepc, t3)
    li t2, 0x1800
    CLEAR_CSR(mstatus, t2)
    li t2, 0xC0800
    SET_CSR(mstatus, t2)
    li t4, 0x555
    MRET

# Test case 3:
Test_case_3:
    li t2, 0x123    # Write non-zero value to satp
    WRITE_CSR(satp, t2)

    la t3, code
    WRITE_CSR(mepc, t3)
    li t2, 0x1800
    CLEAR_CSR(mstatus, t2)
    li t2, 0xC0800
    SET_CSR(mstatus, t2)
    li t4, 0x666
    MRET

code:
    li t6, 1

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

.align 4
.globl tohost
tohost:
    .dword 0

.align 4
.globl fromhost
fromhost:
    .dword 0