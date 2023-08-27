#include "macros.h"
.section .text
.text
.globl rvtest_entry_point
rvtest_entry_point:
    ALL_MEM_PMP
    li t0, SATP32_MODE
    WRITE_CSR(satp, t0)
    READ_CSR(satp, t1)
    beq t1, t0, exit
    li x1, 1
    j exit

exit:
	slli x1, x1, 1
	addi x1, x1, 1
    mv x30, s1
	sw x1, tohost, x30
	self_loop: j self_loop
.data
test_seg:
    .word 0x23
.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;
