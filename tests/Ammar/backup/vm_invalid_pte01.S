#################################################################################################           
#                                                                                               #
# Verification Goal: Set PTE.V = 0 and test the Read Acces in Supervisor mode for Level1        #
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

#define IS_CAUSE_EXPECTED   1
#define IS_S_MODE


trap_handler:

    beqz s0, exit               # Jumps to exit if IS_CAUSE_EXPECTED is 0
    csrr t0, macause
    bne  t0, s1, exit           # Jumps to exit if EXPECTED_CAUSE is'nt equal to mcause

handler:

    csrr t3,mepc                # Read the value of MEPC into t3
    bne s2,t3,exit          
    addi t3, t3, 4              # Calculate the address of the next instruction
    #ifdef IS_S_MODE 
    CHANGE_T0_S_MODE(t3)
    #else 
    CHANGE_T0_U_MODE(t3)
    #endif

    li s10,34
    j exit


.text
.global _start
_start:

    li t2, -1		# WHOLE PHYSICAL MEMORY AS SINGLE REGION
	csrw pmpaddr0, t2
	li t2, 0x0F		# TOR MODE WITH LOCK BIT ON; WIll write in terms of MACROS later
	csrw pmpcfg0, t2             
	csrw satp, x0  # write satp with all zeros (bare mode)

    la t1,trap_handler
    csrw mtvec,t1






  .set va_0, 0x90000000
	.set pa_0, 0x80000000 
	.set va_1, 0x91000000

	// PTE setup for Instruction memory 0x90000000 -> 0x80000000
	LA a0, pa_0
	LI a1, (PTE_V | PTE_R | PTE_A | PTE_W | PTE_X | PTE_D | PTE_G)
	PTE_SETUP_RV32(a0, a1, t0, t1, va_0,1)
	
	LA a0, rvtest_data
	LI a1, (PTE_R | PTE_A | PTE_W | PTE_X | PTE_D | PTE_G)
	PTE_SETUP_RV32(a0, a1, t0, t1, va_1,1)




main:

    la a1,code                                                      # loads the address of label code
    GEN_VA(a1, a0, 0x100, 0x000)                                    # generrates the VA for label code
    mv s5,a0                                                        # move VA to s5
    mv s10,s5                                                       # move the VA of label code to s10 that will be compared later
    CLEAR_REG(a2)                                                   # clear the reg a2    
    ori a2, a2, ( PTE_D | PTE_A | PTE_X | PTE_W | PTE_R | PTE_V )   # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1

    la a1,arr                                                       # loads the address of label arr
    CLEAR_REG(a2)                                                   # clear the reg a2
    GEN_VA(a1, a0, 0x200, 0x000)                                    # generrates the VA for label arr
    mv s6,a0                                                        # move VA to s6
    ori a2, a2, ( PTE_D | PTE_A | PTE_X | PTE_W | PTE_R )           # sets the permission bits
 




    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1   

    SATP_SETUP_SV32                                                 # set the SATP for virtualization
    CHANGE_T0_S_MODE(s5)                                            # changes mode M to S and set the MEPC value to s5

code:
    .if( IS_CAUSE_EXPECTED == 1)
        li s0, 1
    .else 
        li s0,0
    .endif
    
    li s1,CAUSE_LOAD_PAGE_FAULT
    la s2, check
check:

    lw t1,0(s6)  
    li s5,0x69
    li s1,CAUSE_LOAD_PAGE_FAULT
    la s2, check1
check1:
    sw t1,0(s6)
    li s5,0x34                          
    j exit

RVTEST_EXIT_LOGIC                                                    # exit logic 
RVTEST_DATA_SECTION                                                  # data section                                                         

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;


