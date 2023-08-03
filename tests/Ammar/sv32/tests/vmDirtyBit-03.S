#include "macros1.h"
#define Test_Access_Bit
.text

.globl rvtest_entry_point
rvtest_entry_point:
    #User mode-- Level 1 -- Read bit = 1 -- Write Bit = 1 -- Execute Bit = 1 -- Execute Dirty bit = 1 -- Dirty Bit = 0 
    TEST_DIRTY_BIT(0x02, 1, 1, 1, 1, 0, 0)
#ifdef Test_Access_Bit
    ABit_trap_handler
    #endif
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