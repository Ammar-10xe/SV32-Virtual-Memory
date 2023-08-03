#include "macros.h"
#define Test_Access_Bit
.text
.globl rvtest_entry_point
rvtest_entry_point:
    # BitFields
    # MODE:S_MODE LEVEL(PTE):1, R(PTE):1, W(PTE):0, X(PTE):1, XA(PTE):1, A(PTE):0
    #TEST_ACCESS_BIT(0x02, 1, 1, 0, 1, 1, 0)
    TEST_VM_FEATURES(S_MODE, LEVEL1, ENABLE_READ_CHECK, DISABLE_WRITE_CHECK, DISBALE_EXECUTE_CHECK, ACCESS_BIT_TEST)

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
