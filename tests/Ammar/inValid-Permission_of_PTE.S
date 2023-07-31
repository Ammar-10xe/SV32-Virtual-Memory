###############################################################################################
#                                                                                             #
# Verification Goals:Show that satp is only accessible in M and S mode and illegal            #  
#                   instruction exception is generated when accessed in lower privilege mode  #
# Description:      Access satp in M, S, and U mode using csrrw, csrrc, csrrs                 #
###############################################################################################

.include "./trap_handler.S"
#include "../macros.h"

.text
.global _start
_start:
    la     t1, trap_handler
    csrw   mtvec, t1
    la t4, code
    srli t5, t4, 2
    ori t5, t5, 3
    csrw pmpaddr0, t5
    li t3, 0x1F
    csrw pmpcfg0, t3
    CHANGE_T0_S_MODE(t4)

code:
    li t6, 0x34
    li t6, 0x10

exit:
    la t0, tohost
    li t1, 1
    sw t1, 0(t0)
    j exit

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;

