#################################################################################################           
#                                                                                               #
# Verification Goal: Set PTE.V = 0 and test the execute Acces in User mode for Level0           #
#                                                                                               #
# Description:                - Instruction page fault for execute access.                      #    
#                                                                                               #
#################################################################################################
#                                                                                               #
# Sub Feature:         In-Valid Permission of PTE                                               #                
#                                                                                               #   
# Feature Discription: If PTE does not have Valid (pte.V=0) permission, then accessing it would #
#                      raise page fault exception of the corresponding access type.             #
#                                                                                               #
#################################################################################################   


#include "macros.h"

.text
.global rvtest_entry_point
rvtest_entry_point:

    ALL_MEM_PMP                                                     # set the PMP permissions
    TRAP_HANDLER(trap_handler)                                      # set mtvec for trap                         
    li s11, INSTRUCTION_PAGE_FAULT
    
main:
    la a1,pgtb_l0                                                   # loads the address of label code
    GEN_VA(a1, a0, 0x100, 0x000)                                    # generrates the VA for label code
    CLEAR_REG(a2)                                                   # clear the reg a2    
    ori a2, a2, ( PTE_V )                                           # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1

    la a1,code                                                      # loads the address of label code
    GEN_VA(a1, a0, 0x100, 0x000)                                    # generrates the VA for label code
    mv s5,a0                                                        # move VA to s5
    mv s10,s5                                                       # move the VA of label code to s10 that will be compared later
    CLEAR_REG(a2)                                                   # clear the reg a2    
    ori a2, a2, ( PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R )   # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1

    la a1,arr                                                       # loads the address of label arr
    GEN_VA(a1, a0, 0x100, 0x010)                                    # generrates the VA for label arr
    mv s6,a0                                                        # move VA to s6
    CLEAR_REG(a2)                                                   # clear the reg a2    
    ori a2, a2, ( PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R )   # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1   

    SATP_SETUP_SV32                                                 # set the SATP for virtualization
    CHANGE_T0_U_MODE(s5)                                            # changes mode M to U and set the MEPC value to s5

code:
    li t0,ALL_F_S                            
    j exit

ABit_trap_handler                                                    # trap handler      
COREV_VERIF_EXIT_LOGIC                                               # exit logic 
RVTEST_DATA_SECTION                                                  # data section                                                         

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;


