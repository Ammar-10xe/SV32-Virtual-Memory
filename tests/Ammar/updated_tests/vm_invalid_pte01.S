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

#define IS_S_MODE
#define ECALL_CAUSE_CODE    9

trap_handler:

    csrr t0, mcause            # Read the value of mcause 
    la t1, IS_CAUSE_EXPECTED
   
    lw t2, 0(t1)               # if cause expected then 1 else 0
    lw t3, 4(t1)               # expected value of mepc 
    lw t4, 8(t1)               # expected value of mcause  

    li  t1, ECALL_CAUSE_CODE   # value of mcause when ecall > Supervisor Mode
    beq t0,t1,ecall_instr      # checks for if ecall is occured

    beqz t2, exit               # Jumps to exit if IS_CAUSE_EXPECTED is 0
    
    csrr t5,mepc
    bne t3,t5,exit              # check the value of mepc with it's expected value

    bne  t0, t4, exit           # Jumps to exit if EXPECTED_CAUSE is'nt equal to mcause
     
handler:

    addi t5, t5, 4              # Calculate the address of the next instruction

    #ifdef IS_S_MODE 
    CHANGE_T0_S_MODE(t5)
    #else 
    CHANGE_T0_U_MODE(t5)
    #endif

ecall_instr:

    csrr t3,mepc                # Read the value of MEPC into t3
    addi t3,t3,4                # Calculate the address of the next instruction 
    jr t3
    
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



    la a1,IS_CAUSE_EXPECTED                                         # loads the address of label rvtest_data
    mv a0, a1                                                       # generrates the VA for label rvtest_data                                                       # move VA to s6
    ori a2, x0, ( PTE_D | PTE_A | PTE_X | PTE_W | PTE_R | PTE_V)    # sets the permission bits
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
        # .if( IS_CAUSE_EXPECTED == 1)
        #     li s0, 1
        # .else 
        #     li s0,0
        # .endif

    la t1,IS_CAUSE_EXPECTED
    la t2, check_load
    li t3, CAUSE_LOAD_PAGE_FAULT
    li t4, 1    
    sw t4, 0(t1)                                                    # store 1 to indicate cause is expected   
    sw t2, 4(t1)                                                    # store the address where cause is expected 
    sw t3, 8(t1)                                                    # store the mcause value of expected cause

    la a1,rvtest_data                                               # loads the address of label rvtest_data


check_load:

    lw t1,0(s6)  
    nop


    la t1,IS_CAUSE_EXPECTED
    la t2, check_store
    li t3, CAUSE_STORE_PAGE_FAULT
    li t4, 1    
    sw t4, 0(t1)                                                    # store 1 to indicate cause is expected   
    sw t2, 4(t1)                                                    # store the address where cause is expected 
    sw t3, 8(t1)                                                    # store the mcause value of expected cause


check_store:
    sw t1,0(s6)
    nop                          
    ecall

# Setup a new PTE 
    la a1,check_execute                                             # loads the address of label vm_en
    mv a0, a1 
    mv s5,a0                                                        # move VA to s5
    ori a2, x0, ( PTE_D | PTE_A | PTE_X | PTE_W | PTE_R )            # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1

# there is a fault here as the value does not gets updated  afer line 120
    li s11,10
    li s1,CAUSE_FETCH_PAGE_FAULT
    la s2, check_execute

    SATP_SETUP_SV32(pgtb_l1)                                        # set the SATP for virtualization
    # sfence.vma
    CHANGE_T0_S_MODE(s5)                                            # changes mode M to S and set the MEPC value to s5

  
check_execute:
    li s6, 0x45
    ecall
 li s11,0x34


RVTEST_EXIT_LOGIC                                                    # exit logic 

.data  
.align 24
    IS_CAUSE_EXPECTED: 

        .word 0xdeadbeef                                          # 1 for cause expected 0  for no cause 
        .word 0xbeefdead                                          # write the value of mepc here (where  cause is expected)
        .word 0xcafecafe                                          # write the value of expect cause 

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


