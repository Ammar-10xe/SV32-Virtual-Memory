#include "macros.h"
.text
.globl rvtest_entry_point
rvtest_entry_point:
    # MODE:S_Mode LEVEL(PTE):0, R(PTE):0, W(PTE):0, X(PTE):1, XS(PTE):1, op_check:1
    TEST_Reserved_RWX(0x02, 1, 0, 1, 0, 1, 0x01)

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
