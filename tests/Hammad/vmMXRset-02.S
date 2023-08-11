#include "macros.h"
.text
.globl rvtest_entry_point
rvtest_entry_point:
    # BitFields
    # MODE:S_MODE LEVEL(PTE):0, R(PTE):0, W(PTE):0, X(PTE):1, XA(PTE):1, A(PTE):1
    TEST_MXR_SET(0x00, 1, 0, 0, 1)
    nop
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
