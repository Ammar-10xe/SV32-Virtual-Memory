#include "macros.h"
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
    j exit