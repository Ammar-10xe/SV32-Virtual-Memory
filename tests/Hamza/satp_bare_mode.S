# Test to show writing {zero, non-zero} value to satp when mode=bare and the behavior follows the design implementation.

#include "../../macros.h"



.text
.globl rvtest_entry_point
rvtest_entry_point:
#Setting pmp bits for all memory
    PMP_ALL_MEM
############################
#    | M-mode Configurations and code |   #
###########################################

    # Setting up page table with SV32 translation scheme
    la t1, pgtb_l0
    mv a1, t1

    GEN_VA(a1, a0, 0x280, 0x002)
    SET_PTE_V(a2, FLUSH)
    PTE_SETUP_RV32(a1, a2, t1, a0, 1)

    la t1, code
    mv a1, t1
    GEN_VA(a1, a0, 0x280, 0x000)
    mv t3, a0
    SET_PTE_V(a2, FLUSH)
    SET_PTE_X(a2, NO_FLUSH)
    SET_PTE_A(a2, NO_FLUSH)
    SET_PTE_W(a2, NO_FLUSH)
    SET_PTE_R(a2, NO_FLUSH)
    SET_PTE_D(a2, NO_FLUSH)
    PTE_SETUP_RV32(a1, a2, t1, a0, 0)

    la t1, arr
    mv a1, t1
    GEN_VA(a1, a0, 0x280, 0x004)
    mv t4, a0
    SET_PTE_V(a2, FLUSH)
    SET_PTE_X(a2, NO_FLUSH)
    SET_PTE_A(a2, NO_FLUSH)
    SET_PTE_W(a2, NO_FLUSH)
    SET_PTE_R(a2, NO_FLUSH)
    SET_PTE_D(a2, NO_FLUSH)
    PTE_SETUP_RV32(a1, a2, t1, a0, 0)

    # Test case 1: Write zero to satp in "bare" mode (should be ignored)
    li t2,SATP32_MODE<<1        # Write zero to satp
    WRITE_CSR(satp, t2)

    la t2,trap_handler            # set mtvec for trap
    WRITE_CSR(mtvec, t2)
    WRITE_CSR(mepc, t3)
    li t2, MSTATUS_MPP
    CLEAR_CSR(mstatus, t2)
    li t2, ( MSTATUS_SUM | MSTATUS_MXR | (MSTATUS_MPP & (MSTATUS_MPP >> 1)))
    SET_CSR(mstatus, t2)
    li s10, ERROR1
    MRET

    # Test case 2: Write non-zero value to satp in "bare" mode (should be ignored)
Test_case_2:
    # Test case 1: Write zero to satp in "bare" mode (should be ignored)
    li t2,SATP32_MODE<<1        # Write zero to satp
    WRITE_CSR(satp, t2)

    WRITE_CSR(mepc, t3)
    li t2, MSTATUS_MPP
    CLEAR_CSR(mstatus, t2)
    li t2, ( MSTATUS_SUM | MSTATUS_MXR | (MSTATUS_MPP & (MSTATUS_MPP >> 1)))
    SET_CSR(mstatus, t2)
    li s10, ERROR2
    MRET

# Test case 3:
Test_case_3:
    # Test case 1: Write zero to satp in "bare" mode (should be ignored)
    li t2,SATP32_MODE<<1        # Write zero to satp
    WRITE_CSR(satp, t2)

    la t3, code
    WRITE_CSR(mepc, t3)
    li t2, MSTATUS_MPP
    CLEAR_CSR(mstatus, t2)
    li t2, ( MSTATUS_SUM | MSTATUS_MXR | (MSTATUS_MPP & (MSTATUS_MPP >> 1)))
    SET_CSR(mstatus, t2)
    li s10, ERROR3
    MRET

code:
    csrr s8,mepc
    li t6, 1
    j exit

trap_handler:

    csrr  t0,    mcause
    csrr  t4,    mtval
    li    t1,   1
    beq   t0,   t1, instruction_access_fault
    li    t1,   2
    beq   t0,   t1, illegal_instruction_fault
    li    t1,   5
    beq   t0,   t1, load_access_fault
    li    t1,   7
    beq   t0,   t1, store_access_fault
    li    t1,   12
    beq   t0,   t1, instruction_page_fault
    li    t1,   13
    beq   t0,   t1, load_page_fault
    li    t1,   15
    beq   t0,   t1, store_page_fault
    j     trap_handler_end

instruction_access_fault:
   li t5 , ERROR1
   li t6 ,ERROR2
   beq s10,t5,Test_handel_1
   beq s10,t6,Test_handel_2
    j exit

illegal_instruction_fault:
    li t5 , ERROR1
   li t6 ,ERROR2
   beq s10,t5,Test_handel_1
   beq s10,t6,Test_handel_2
    j exit

load_access_fault:
    j exit

store_access_fault:
    j exit

instruction_page_fault:
    j exit

load_page_fault:
    j exit

store_page_fault:
    j exit

trap_handler_end:
    mret

Test_handel_1:
# la t5,Test_case_2
# csrw mepc , t5
# li t6,MSTATUS_MPP
# csrw mstatus,t6
# mret
j Test_case_2

Test_handel_2:
# la t5,Test_case_3
# csrw mepc , t5
# li t6,MSTATUS_MPP
# csrw mstatus,t6
j Test_case_3


exit:
	slli x1, x1, 1
	addi x1, x1, 1
    mv x30, s1
	sw x1, tohost, x30
	self_loop: j self_loop

.data

pgtb_l1:
    .zero 4096
.align 12
pgtb_l0:
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
