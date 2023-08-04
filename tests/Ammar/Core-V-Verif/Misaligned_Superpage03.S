#################################################################################################           
#                                                                                               #
# Verification Goal: Test the Execute acces in Supervisor mode for Level1                       #
#                                                                                               #
# Description:       Execute access to the PTE should raise instruction page fault              #
#                                                                                               #
#################################################################################################
#                                                                                               #
# Sub Feature:         Misaligned Superpage                                                     #                
#                                                                                               #   
# Feature Discription: If PTE at level1 is leaf PTE (superpage) and its pte.ppn[0]=0, then it   # 
#                      is a misaligned superpage and accessing that PTE would raise page fault  # 
#                      exception of the corresponding access type.                              #   
#                                                                                               #
#################################################################################################   

#include "macros.h"

.text
.global _start
_start:

    ALL_MEM_PMP                                               # set the PMP permissions
    TRAP_HANDLER(trap_handler)                                # set mtvec for trap                         
    li s11, INSTRUCTION_PAGE_FAULT   
main:     

    la a1,code                                                # loads the address of label code
    GEN_VA(a1, a0, 0x100, 0x000)                              # generrates the VA for label code
    mv s5,a0                                                  # move VA to s5
    mv s10,s5                                                 # move the VA of label code to s10 that will be compared later
    CLEAR_REG(a2)                                             # clear the reg a2    
    ori a2, a2, ( PTE_D | PTE_A | PTE_X | PTE_V )             # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                    # setup the PTE for level1

    la a1,arr                                                 # loads the address of label arr
    CLEAR_REG(a2)                                             # clear the reg a2
    GEN_VA(a1, a0, 0x200, 0x000)                              # generrates the VA for label arr
    mv s6,a0                                                  # move VA to s6
    CLEAR_REG(a2)                                             # clear the reg a2    
    ori a2, a2, (PTE_D | PTE_A | PTE_W | PTE_R | PTE_V)       # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                    # setup the PTE for level1   

    SATP_SETUP_SV32                                           # set the SATP for virtualization
    CHANGE_T0_S_MODE(s5)                                      # changes mode M to U and set the MEPC value to s5
    .align 16                                                 # to make the ppn[0] of code misalligned

code:
    li t1, ALL_F_S                                            # test the Execute Acces in Supervisor mode for Level1 PTE 

end:

ABit_trap_handler                                             # trap handler      
COREV_VERIF_EXIT_LOGIC                                        # exit logic 
RVTEST_DATA_SECTION_MISALIGNED                                # ppn[0]!=0 for Misaligned Superpage 

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;

