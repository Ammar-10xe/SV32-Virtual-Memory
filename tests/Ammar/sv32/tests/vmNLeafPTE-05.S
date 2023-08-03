#include "macros.h"
#define Test_Access_Bit
.text
.globl _start
_start:
    #Write Test
    # MODE:U_Mode LEVEL(PTE):0, R(PTE):0, W(PTE):0, X(PTE):1, XS(PTE):1, op_check:0
    TEST_Nonleaf_PTE(0x00, 0, 0, 0, 0, 1, 0x01)

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
