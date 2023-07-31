#include "../macros.h"
.include "./trap_handler.S"
.section .text
.global _start

_start:

###########################################
#    | M-mode Configurations and code |   #
###########################################

    la t2, trap_handler
    WRITE_CSR (mtvec, t2)

    li t0, 0x1FF
    slli t0, t0, 22
    WRITE_CSR(satp, t0)
    READ_CSR(satp, t0)
    li t1, 1
    j exit

###########################################
#    | S-mode Configurations and code |   #
###########################################


###########################################
#    | U-mode Configurations and code |   #
###########################################


###########################################
#           | EXIT LOGIC |                #
###########################################

exit:
    la t0, tohost
    EXIT_LOGIC(t0, t1)
    j exit

.data


.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;