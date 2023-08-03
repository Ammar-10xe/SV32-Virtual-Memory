#################################################################################################           
#                                                                                               #
# Verification Goal: Test the Execute Acces in Supervisor mode for Level1 such that             #
#                    (PTE.x = 1, PTE.v = 1, PTE.u=1 and mstatus.SUM=1 )                         #
#                                                                                               #
# Description:       Execute access should raise instruction page fault.                        #
#                                                                                               #
#################################################################################################
#                                                                                               #
# Sub Feature:         RWX access on U-mode pages in S-mode with s/mstatus.SUM set              #                
#                                                                                               #   
# Feature Discription: If PTE belongs to user mode i.e. its U permission bit is set (pte.u = 1) #
#                      and m/sstatus.SUM = 1, then RW access to that PTE in supervisor mode     #
#                      would be successful but eXecute access would raise instruction page      #
#                      fault exception in s-mode.                                               #   
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
    mv s1,a0                                                    # move VA to t2                    
    ori a2, a2, (PTE_D | PTE_A | PTE_U | PTE_X | PTE_V )        # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, 1)                           # setup the PTE for level1
                        
    la a1,arr                                                   # loads the address of label arr
    GEN_VA(a1, a0, 0x200, 0x000)                                # generrates the VA for label arr
    mv s2,a0                                                    # move VA to t3
    ori a2, a2, (PTE_D | PTE_A | PTE_U | PTE_W | PTE_R | PTE_V) # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, 1)                           # setup the PTE for level1   
                           
    SATP_SETUP_SV32                                             # set the SATP for virtualization
    CHANGE_T0_S_MODE(s1)                                        # change mode M to S and set the MEPC value to t2       
         
code:       
    li t1, 10                                  
    sw t1,4(s2)                                                 # test the Read Acces in Supervisor mode for Level1 PTE 
    READ_CSR (mcause, t2)                                       # exception to go back to M mode 
    
exit:
    la t0, tohost
    li t1, 1
    sw t1, 0(t0)
    j exit

RVTEST_DATA_SECTION                                                                              

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;




