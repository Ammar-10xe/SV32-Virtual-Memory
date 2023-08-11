#################################################################################################           
#                                                                                               #
# Verification Goal: Test the Read Acces in Supervisor mode for Level1 (PTE.r = 0)              #
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

#include "macros.h"

.text
.global _start
_start:

    PMP_ALL_MEM                                          # set the PMP permissions
    TRAP_HANDLER(trap_handler)                           # set mtvec for trap
    li s11, LOAD_PAGE_FAULT                             
    
main: 

    la a1,code                                           # loads the address of label code
    GEN_VA(a1, a0, 0x100, 0x000)                         # generrates the VA for label code
    mv s5,a0                                             # move VA to s5
    mv s10,s5                                            # loads the VA in s10 which will be compared in trap handler
    CLEAR_REG(a2)                                        # clear the reg a2   
    ori a2, a2, ( PTE_D | PTE_A | PTE_X | PTE_V )        # sets the permission bits                  
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)               # setup the PTE for level1
    
    la a1,arr                                            # loads the address of label arr
    GEN_VA(a1, a0, 0x200, 0x000)                         # generrates the VA for label arr
    mv s6,a0                                             # move VA to s6
    CLEAR_REG(a2)                                        # clear the reg a2 
    ori a2, a2, ( PTE_D | PTE_A | PTE_X | PTE_V )        # sets the permission bits                  
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)               # setup the PTE for level1   
     
    SATP_SETUP_SV32                                      # set the SATP for virtualization
    CHANGE_T0_S_MODE(s5)                                 # changes mode M to S and set the MEPC value to s5

code:   
    lw t1,0(s6)                                          # test the Read Acces in Supervisor mode for Level1 PTE 

ABit_trap_handler                                        # trap handler  
COREV_VERIF_EXIT_LOGIC                                   # exit logic 
RVTEST_DATA_SECTION                                      # data section                                 
            
.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;


