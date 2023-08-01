###############################################################################################
#                                                                                             #
# Verification Goals:Show that satp is only accessible in M and S mode and illegal            #  
#                   instruction exception is generated when accessed in lower privilege mode  #
# Description:      Access satp in M, S, and U mode using csrrw, csrrc, csrrs                 #
###############################################################################################

.include "./trap_handler.S"
#include "../../../macros.h"

.text
.global _start
_start:
    PMP_ALL_MEM                 # set the PMP permissions
    la     t1, trap_handler     # set mtvec for trap
    csrw   mtvec, t1

    la a1,pgtb_l0                  # set the PTE on l1
    GEN_VA(a1, a0, 0x100, 0x000)
    li a2, 0x011   
    PTE_SETUP_RV32(a1, a2, t1, a0, 1)
    
    
    la a1,code                 # set the PTE on l1
    GEN_VA(a1, a0, 0x100, 0x000)
    mv t4,a0
    li a2, 0x0DF    # user mode 
    PTE_SETUP_RV32(a1, a2, t1, a0, 0)
    
    la a1,arr                 # set the PTE on l1
    GEN_VA(a1, a0, 0x100, 0x004)
    mv t5,a0
    li a2, 0x0DE    # user mode 
    PTE_SETUP_RV32(a1, a2, t1, a0, 0)


    
    SATP_SETUP_SV32            # set the SATP for virtualization
    CHANGE_T0_U_MODE(t4)       # changes mode M to S


code:
    # li t6, 0x34
    # li t6, 0x10
    lw t1,0(t5)
exit:
    la t0, tohost
    li t1, 1
    sw t1, 0(t0)
    j exit

.data

pgtb_l1:
    .zero 4096
.align 12
pgtb_l0:
    .zero 4096
pgtb_l0_1:
    .zero 4096
arr:
.word 0x23


.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;


