#################################################################################################           
#                                                                                               #
# Verification Goal: Set PTE.V = 0 and test the Read Acces in User mode for Level10             #
#                                                                                               #
# Description:                - load page fault for read access.                                #    
#                                                                                               #
#################################################################################################
#                                                                                               #
# Sub Feature:         In-Valid Permission of PTE                                               #                
#                                                                                               #   
# Feature Discription: If PTE does not have Valid (pte.V=0) permission, then accessing it would #
#                      raise page fault exception of the corresponding access type.             #
#                                                                                               #
#################################################################################################   


#include "../../../macros.h"

.text
.global _start
_start:

    ALL_MEM_PMP                                                            # set the PMP permissions
    TRAP_HANDLER(trap_handler)                                             # set mtvec for trap                         
    li s11, LOAD_PAGE_FAULT    
main:      
    
    la a1,pgtb_l0                                                          # loads the address of label code
    GEN_VA(a1, a0, 0x100, 0x000)                                           # generrates the VA for label code
    ori a2, a2, ( PTE_V )                                                  # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                                 # setup the PTE for level1

    la a1,code                                                             # loads the address of label code
    GEN_VA(a1, a0, 0x100, 0x000)                                           # generrates the VA for label code
    mv s5,a0                                                               # move VA to s5
    mv s10,s5                                                              # move the VA of label code to s10 that will be compared later
    ori a2, a2, ( PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V )  # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL0)                                 # setup the PTE for level1
    
    la a1,arr                                                              # loads the address of label arr
    CLEAR_REG(a2)                                                          # clear the reg a2
    GEN_VA(a1, a0, 0x100, 0x010)                                           # generrates the VA for label arr
    mv s6,a0                                                               # move VA to s6
    ori a2, a2, ( PTE_D | PTE_A | PTE_U  | PTE_X | PTE_W | PTE_R )         # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL0)                                 # setup the PTE for level1   
    
    SATP_SETUP_SV32                                                        # set the SATP for virtualization
    CHANGE_T0_U_MODE(s5)                                                   # changes mode M to U and set the MEPC value to s5

code:
    lw t1,0(s6)                            
    j exit

ABit_trap_handler                                                    # trap handler      
RVTEST_EXIT_LOGIC                                                    # exit logic 
RVTEST_DATA_SECTION                                                  # data section                                                         

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;


