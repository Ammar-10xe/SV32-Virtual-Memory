#################################################################################################           
#                                                                                               #
# Verification Goal: Test the Read acces in User mode for Level1                                #
#                                                                                               #
# Description:       Read access to the PTE should raise load page fault for read access        #
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

.include "./trap_handler.S"
#include "../../../macros.h"

.text
.global _start
_start:
    PMP_ALL_MEM                                                 # set the PMP permissions
    TRAP_HANDLER(trap_handler)                                  # set mtvec for trap
                
    la a1,code                                                  # loads the address of label code
    GEN_VA(a1, a0, 0x100, 0x000)                                # generrates the VA for label code
    mv s1,a0                                                    # move VA to s1                    
    ori a2, a2, ( PTE_D | PTE_A | PTE_U | PTE_X | PTE_V )       # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, 1)                           # setup the PTE for level1
                        
    la a1,arr                                                   # loads the address of label arr
    GEN_VA(a1, a0, 0x200, 0x000)                                # generrates the VA for label arr
    mv s2,a0                                                    # move VA to t3
    ori a2, a2, (PTE_D | PTE_A | PTE_U | PTE_W | PTE_R | PTE_V) # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, 1)                           # setup the PTE for level1   
                           
    SATP_SETUP_SV32                                             # set the SATP for virtualization
    CHANGE_T0_U_MODE(s1)                                        # change mode M to U and set the MEPC value to s1      
         
code:                                         
    lw t1,0(s2)                                                 # test the Read Acces in User mode for Level1 PTE 
    READ_CSR (mcause, t2)                                       # exception to go back to M mode 
    
exit:
    la t0, tohost
    li t1, 1
    sw t1, 0(t0)
    j exit
                                                    
 RVTEST_DATA_SECTION_MISALIGNED                                 # ppn[0]!=0 for Misaligned Superpage 

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;
