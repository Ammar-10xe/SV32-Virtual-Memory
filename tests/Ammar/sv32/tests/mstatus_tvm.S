#include "macros.h"
#.include "func1.s"
#define mstatus_tvm
.text
.globl rvtest_entry_point
rvtest_entry_point:

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

    la a1, code_jump_back
    GEN_VA(a1, a0, 0x280, 0x004)
    mv a5, a0  #virtual address of code_jump_back
    SET_RWXV_BITS(a2, FLUSH)
    SET_PTE_A(a2, NO_FLUSH)
    SET_PTE_D(a2, NO_FLUSH)
    PTE_SETUP_RV32(a1, a2, t1, a0, 0)

    SATP_SETUP_SV32 
    
    la t2, trap_handler
    WRITE_CSR (mtvec, t2)
    WRITE_CSR (mepc , t3)
    li t2, 0x1800
    CLEAR_CSR (mstatus, t2)
    li t2,  0x100800
    SET_CSR (mstatus, t2)
    MRET

###########################################
#    | S-mode Configurations and code |   #
###########################################
S_Mode:
    li   t5     ,  0xA0004000
    li   t4     ,  0x80000000
    li t6,1
    csrw satp   ,  t4

###########################################
#    | U-mode Configurations and code |   #
###########################################


code_jump_back:
    li t6,1
    sfence.vma a3, a4
    j csr_pass
Passed:
    addi t6, zero, 0x1
    j csr_pass
Failed:
    addi t6, zero, 0x0
csr_pass:
    li x1, 0
    slli x1, x1, 1
    addi x1, x1, 1
    sw x1, tohost, x30
    self_loop: j self_loop

trap_handler:

    csrr  t0,    mcause
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
    j code_jump_back

illegal_instruction_fault:
    #it will return in machine mode but we need supervisor mode
    li t2,1
    li t3,2
    beq t6,t2,trap_code
    beq t6,t3,trap_code_jump_back
load_access_fault:
    j csr_pass

store_access_fault:
    j csr_pass

instruction_page_fault:
    j csr_pass

load_page_fault:
    j csr_pass

store_page_fault:
    j csr_pass

trap_handler_end:
    mret

trap_code:
    la t2, trap_handler
    csrw mtvec, t2
    csrw mepc , a5
    li t2, 0x1800
    csrc mstatus, t2
    li t2,  0x100800
    csrs mstatus, t2
    MRET
trap_code_jump_back:
    li t6, 1
    j csr_pass

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
