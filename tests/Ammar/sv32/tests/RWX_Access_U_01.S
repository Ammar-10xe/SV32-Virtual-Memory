#################################################################################################           
#                                                                                               #
# Verification Goal: Test the Read acces in Supervisor mode for Level1 such that                #
#                    (PTE.x = 1, PTE.r = 1, PTE.u=1 and mstatus.SUM=1)                          #
#                                                                                               #
# Description:       Read access to the PTE should be successful. So, the load works without    #
#                    page fault and expected data is loaded from the memory                     #
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

#include "macros.h"

.text
.global rvtest_entry_point
rvtest_entry_point:

    ALL_MEM_PMP                                                 # set the PMP permissions
    TRAP_HANDLER(trap_handler)                                  # set mtvec for trap
                
    la a1,code                                                  # loads the address of label code
    GEN_VA(a1, a0, 0x100, 0x000)                                # generrates the VA for label code
    mv s1,a0                                                    # move VA to t2                    
    ori a2, a2, (PTE_D | PTE_A | PTE_X | PTE_V )                # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, 1)                           # setup the PTE for level1
                        
    la a1,arr                                                   # loads the address of label arr
    GEN_VA(a1, a0, 0x200, 0x000)                                # generrates the VA for label arr
    mv s2,a0                                                    # move VA to t3
    ori a2, a2, (PTE_D | PTE_A | PTE_X | PTE_U | PTE_R | PTE_V) # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, 1)                           # setup the PTE for level1   
                           
    SATP_SETUP_SV32                                             # set the SATP for virtualization
    CHANGE_T0_S_MODE(s1)                                        # change mode M to S and set the MEPC value to t2       
         
code:                                         
    lw t1,0(s2)                                                 # test the Read Acces in Supervisor mode for Level1 PTE 
    READ_CSR (mcause, t2)                                       # exception to go back to M mode 
    
    ABit_trap_handler
exit:
    li x1, 0
	slli x1, x1, 1
	addi x1, x1, 1
    mv x30, s1
	sw x1, tohost, x30
	self_loop: j self_loop

.data
arr:
    .word 0x23
.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;
.align 24
pgtb_l1:
    .zero 4096
pgtb_l0:
    .zero 4096
pgtb_l0_1:
    .zero 4096




