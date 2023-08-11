# Test to show writing {zero, non-zero} value to satp when mode=bare and the behavior follows the design implementation.

#include "macros.h"

.text
.globl rvtest_entry_point
rvtest_entry_point:


#Setting pmp bits for all memory
    PMP_ALL_MEM
###########################################
#    | M-mode Configurations and code |   #
###########################################

    # Setting up the first page table Entry with physical address of code.
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
    SET_PTE_G(a2, NO_FLUSH)
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
    SET_PTE_U(a2, NO_FLUSH)
    PTE_SETUP_RV32(a1, a2, t1, a0, 0)

    # Setting up the Second page table Entry with physical address of code.
    la t1,pgtb2_l0
    mv a1, t1

    GEN_VA(a1, a0, 0x280, 0x002)
    SET_PTE_V(a2, FLUSH)
    PTE2_SETUP_RV32(a1, a2, t1, a0, 1)

    la t1, code1
    mv a1, t1
    GEN_VA(a1, a0, 0x280, 0x000)
    mv s6, a0
    SET_PTE_V(a2, FLUSH)
    SET_PTE_D(a2, NO_FLUSH)
    PTE2_SETUP_RV32(a1, a2, t1, a0, 0)

    #First Process uses the address
    TRAP_HANDLER(trap_handler)            # set mtvec for trap
    WRITE_CSR(mepc, t3)
    li t2, MSTATUS_MPP
    CLEAR_CSR(mstatus, t2)
    li t2, ( MSTATUS_SUM | MSTATUS_MXR | (MSTATUS_MPP & (MSTATUS_MPP >> 1)))
    SET_CSR(mstatus, t2)
    SATP_SETUP_SV32
    MRET


code:
    li t6, 1
    SATP_SETUP2_SV32
    li s7, SSTATUS_SPP
    csrw sstatus, s7
    csrw sepc ,s6
    sret
code1:
    li t6, 1
    csrr s8,mepc

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
    j exit

illegal_instruction_fault:

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
exit:
	slli x1, x1, 1
	addi x1, x1, 1
    mv x30, s1
	sw x1, tohost, x30
	self_loop: j self_loop

arr:
    .word 0x23
.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;
.align 24
pgtb_l1:
    .zero 4096
pgtb_l0:
    .zero 4096
pgtb2_l1:
    .zero 4096
pgtb2_l0:
    .zero 4096