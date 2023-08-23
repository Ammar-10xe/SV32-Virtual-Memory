#include "macros.h"
.text
.globl rvtest_entry_point
rvtest_entry_point:
    #Supervisor mode-- Level 1 -- Read bit = 1 -- Write Bit = 1 -- Execute Bit = 1 -- Execute Dirty bit = 1 -- Dirty Bit = 0 
    TEST_DIRTY_BIT(0x00, 0, 1, 1, 1)
    ABit_trap_handler

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
.align 24
pgtb_l1:
    .zero 4096
pgtb_l0:
    .zero 4096
pgtb_l0_1:
    .zero 4096