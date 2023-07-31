###############################################################################################
#                                                                                             #
# Verification Goals:Show that satp is only accessible in M and S mode and illegal            #  
#                   instruction exception is generated when accessed in lower privilege mode  #
# Description:      Access satp in M, S, and U mode using csrrw, csrrc, csrrs                 #
###############################################################################################

.include "./trap_handler.S"
#include "../../macros.h"

.text
.global _start
_start:

###########################################
#    | M-mode Configurations and code |   #
###########################################
    la     t1, trap_handler
    csrw   mtvec, t1
    j      machine_mode

machine_mode:

    li t1, 0x0000ffff
    li t2, 0xffffffff
    li t3, 0x12345678
    csrrs  s1, satp, t1
    csrrc  s2, satp, t2
    csrrw  s3, satp, t3
    la      t4, supervisor_mode // If SATP is accessible change M mode to S
    CHANGE_T0_S_MODE(t4)    

supervisor_mode:

    li t1, 0x0000ffff
    li t2, 0xffffffff
    li t3, 0x12345678
    csrrs  s1, satp, t1
    csrrc  s2, satp, t2
    csrrw  s3, satp, t3
    la t4,user_mode
    CHANGE_T0_U_MODE(t4)  // If SATP is acchnagaecessible change mode to S

user_mode:

    li t1, 0x0000ffff
    li t2, 0xffffffff
    li t3, 0x12345678
    csrrs  s1, satp, t1
    csrrc  s2, satp, t2
    csrrw  s3, satp, t3

exit:
    la t0, tohost
    li t1, 1
    sw t1, 0(t0)
    j exit

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;

