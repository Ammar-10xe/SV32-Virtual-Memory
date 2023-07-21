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
   li t5 , 0x444
   li t6 ,0x555
   beq t4,t5,Test_handel_1
   beq t4,t6,Test_handel_2
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

Test_handel_1:
la t5,Test_case_2
csrw mepc , t5
li t6,0x1800
csrw mstatus,t6
mret

Test_handel_2:
la t5,Test_case_3
csrw mepc , t5
li t6,0x1800
csrw mstatus,t6
mret