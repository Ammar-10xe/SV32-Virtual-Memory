#include "../../../macros.h"
#define Test_Access_Bit
.text
    #ifdef Test_Access_Bit
    ABit_trap_handler
    #endif
.globl _start
_start:
    # BitFields
    # MODE:U_MODE LEVEL(PTE):1, R(PTE):1, W(PTE):0, X(PTE):1,A(PTE):1
   TEST_UBIT_SET(0x00, 0, 1, 0, 1, 1)

exit:
    csrr t2,mstatus
	slli x1, x1, 1
	addi x1, x1, 1
    mv x30, s1
	sw x1, 0(x30)
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
