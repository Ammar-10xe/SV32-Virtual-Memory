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

#include "../../../macros1.h"

#define IS_CAUSE_EXPECTED   1
#define IS_S_MODE


trap_handler:

    csrr t0, mcause            # Read the value of mcause 

    li  t1, 0x00000009         # value of mcause when ecall > Supervisor Mode
    beq t0,t1,ecall_instr      # checks for if ecall is occured

    beqz s0, exit               # Jumps to exit if IS_CAUSE_EXPECTED is 0
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

ecall_instr:

    csrr t3,mepc                # Read the value of MEPC into t3
    addi t3,t3,4                # Calculate the address of the next instruction 
    jalr t3
    
.text
.global _start

_start:
    ALL_MEM_PMP
    la t1,trap_handler
    csrw mtvec,t1

main:

    la a1,vm_en                                                     # loads the address of label vm_en
    mv a0, a1                                                       # generrates the VA for label vm_en
    mv s5,a0                                                        # move VA to s5
    ori a2, x0, ( PTE_D | PTE_A | PTE_X | PTE_W | PTE_R | PTE_V )   # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1
 
    la a1,rvtest_data                                               # loads the address of label rvtest_data
    mv a0, a1                                                       # generrates the VA for label rvtest_data
    mv s6,a0                                                        # move VA to s6
    ori a2, x0, ( PTE_D | PTE_A | PTE_X | PTE_W | PTE_R )           # sets the permission bits
 
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1   

    # la a1,check_execute                                           # loads the address of label vm_en
    # GEN_VA(a1, a0, 0x300, 0x000)                                  # generrates the VA for label vm_en
    # ori a2, x0, ( PTE_D | PTE_A | PTE_R | PTE_W | PTE_V )         # sets the permission bits
    # PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                        # setup the PTE for level1
    
    # # la a1,check_execute                                         # loads the address of label vm_en
    # # GEN_VA(a1, a0, 0x100, 0x100)                                # generrates the VA for label vm_en
    # # ori a2, x0, ( PTE_D | PTE_A | PTE_W | PTE_R )               # sets the permission bits
    # # PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL0)                      # setup the PTE for level1

    SATP_SETUP_SV32(pgtb_l1)                                        # set the SATP for virtualization
    CHANGE_T0_S_MODE(s5)                                            # changes mode M to S and set the MEPC value to s5
vm_en:
    .if( IS_CAUSE_EXPECTED == 1)
        li s0, 1
    .else 
        li s0,0
    .endif
    
    li s1,CAUSE_LOAD_PAGE_FAULT
    la s2, check_load

check_load:

    lw t1,0(s6)  
    nop
    li s1,CAUSE_STORE_PAGE_FAULT
    la s2, check_store

check_store:
    sw t1,0(s6)
    nop                          
    ecall

# Setup a new PTE 
    la a1,check_execute                                             # loads the address of label vm_en
    mv a0, a1 
    mv s5,a0                                                        # move VA to s5
    ori a2, x0, ( PTE_D | PTE_A| PTE_W | PTE_R | PTE_V )            # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1

# there is a fault here as the value does not gets updated  afer line 120


    SATP_SETUP_SV32(pgtb_l1)                                        # set the SATP for virtualization
    CHANGE_T0_S_MODE(s5)                                            # changes mode M to S and set the MEPC value to s5

     
    li s1,CAUSE_FETCH_PAGE_FAULT
    la s2, check_execute

    
check_execute:
    li s6, 0x45
    nop
    ecall


RVTEST_EXIT_LOGIC                                                    # exit logic 

.data         
.align 22                                                
    rvtest_data:                                                           
        .word 0xbeefcafe                                                 
        .word 0xdeadcafe                                                 
        .word 0xcafecafe                                                 
        .word 0xbeefdead                                                 
    .align 12                                                      
    pgtb_l1:                                                       
        .zero 4096                                                 
    pgtb_l0:                                                       
        .zero 4096                                                                                                     

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;


