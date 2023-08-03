#################################################################################################           
#                                                                                               #
# Verification Goal: Test the Read Acces in Supervisor mode for Level1 (PTE.x = 1, PTE.r = 0)   #
#                                                                                               #
# Description:       Execute access should raise load page fault for read access.               # 
#                                                                                               #
#################################################################################################
#                                                                                               #
# Sub Feature:         RWX access on S-mode pages in S-mode                                     #                
#                                                                                               #   
# Feature Discription: When satp.mode=sv32, PTE has (r,w,x) PMP permissions, PTE has            #
#                      non-reserved RWX encoding, pte.u=0 and pte.v=1, then test the following  #
#                      in supervisor privilege mode level 1 PTE.                                #   
#                                                                                               #
#################################################################################################   

.include "./trap_handler.S"
#include "../../../macros.h"

.text
.global _start
_start:

    PMP_ALL_MEM                           # set the PMP permissions
    TRAP_HANDLER(trap_handler)            # set mtvec for trap

    la a1,code                            # loads the address of label code
    GEN_VA(a1, a0, 0x100, 0x000)          # generrates the VA for label code
    mv t2,a0                              # move VA to t2
    li a2, 0x0C9                          # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, 1)     # setup the PTE for level1
    
    la a1,arr                             # loads the address of label arr
    GEN_VA(a1, a0, 0x200, 0x000)          # generrates the VA for label arr
    mv t3,a0                              # move VA to t3
    li a2, 0x0C9                          # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, 1)     # setup the PTE for level1   
     
    SATP_SETUP_SV32                       # set the SATP for virtualization
    CHANGE_T0_S_MODE(t2)                  # change mode M to S and set the MEPC value to t2

code:
    lw t1,0(t3)                           # test the Read Acces in Supervisor mode for Level1 PTE 
    READ_CSR (mcause, t2)                 # exception to go back to M mode 
    
exit:
    la t0, tohost
    li t1, 1
    sw t1, 0(t0)
    j exit

RVTEST_DATA_SECTION                                                                              

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;

