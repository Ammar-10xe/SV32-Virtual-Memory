#################################################################################################           
#                                                                                               #
# Verification Goal: Test the execute Acces in Supervisor mode for Level1 (PTE.x = 1)           #
#                                                                                               #
# Description:       RWX access should be successful if the corresponding permissions           #
#                    are granted in the PTE. Check that load, store and execute works           #
#                    without any page fault.                                                    #
#                                                                                               #
#################################################################################################
#                                                                                               #
# Sub Feature:         RWX access on S-mode pages in S-mode                                     #                
#                                                                                               #   
# Feature Discription: If PTE belongs to supervisor mode i.e. its U permission bit is clear     #
#                      (pte.u = 0),then accessing that PTE in supervisor mode should be         #
#                      successful if the corresponding (r,w,x) permission of PTE is granted.    #   
#                      Otherwise raise a page fault exception of the corresponding access type  #   
#                                                                                               #
#################################################################################################   


#include "macros.h"
.text
.global _start
_start:

    PMP_ALL_MEM                                                         # set the PMP permissions
    TRAP_HANDLER(trap_handler)                                          # set mtvec for trap

main: 

    la a1,code                                                          # loads the address of label code
    GEN_VA(a1, a0, 0x100, 0x000)                                        # generrates the VA for label code
    mv s5,a0                                                            # move VA to s5
    CLEAR_REG(a2)                                                       # clear the reg a2   
    ori a2, a2, ( PTE_D | PTE_A | PTE_X | PTE_W | PTE_R | PTE_V )       # sets the permission bits                  
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                              # setup the PTE for level1
    
    la a1,arr                                                           # loads the address of label arr
    GEN_VA(a1, a0, 0x200, 0x000)                                        # generrates the VA for label arr
    mv s6,a0                                                            # move VA to s6
    CLEAR_REG(a2)                                                       # clear the reg a2 
    ori a2, a2, ( PTE_D | PTE_A | PTE_X | PTE_W | PTE_R | PTE_V )       # sets the permission bits                  
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                              # setup the PTE for level1   
     
    SATP_SETUP_SV32                                                     # set the SATP for virtualization
    CHANGE_T0_S_MODE(s5)                                                # changes mode M to S and set the MEPC value to s5

code:             
    li t1,ALL_F_S                            
    sw t1,4(s6)                                                         # test the Read Acces in Supervisor mode for Level1 PTE 
    lw t2,4(s6)
    j exit

ABit_trap_handler                                                       # trap handler  
COREV_VERIF_EXIT_LOGIC                                                  # exit logic 
RVTEST_DATA_SECTION                                                     # data section                                 
            
.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;


