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

trap_handler:

    csrr t0, mcause                         # read the value of mcause 
    la t1, rvtest_check                     # load the address of trvtest_check
    
    lw t2, 0(t1)                            # if cause expected then load 1 else 0
    lw t3, 4(t1)                            # load the expected value of mepc 
    lw t4, 8(t1)                            # load the expected value of mcause  

    li t5, CAUSE_FETCH_PAGE_FAULT           # load the value of fetch page fault exception 
    beq t0,t5,next_instr                    # if fetch page fault jump to next instr in M mode

    li  t1, CAUSE_SUPERVISOR_ECALL          # load the value of supervisor ecall
    beq t0,t1,next_instr                    # checks if ecall is occured

    li  t1, CAUSE_USER_ECALL                # load the value of user ecall
    beq t0,t1,next_instr                    # checks for ecall is occured

    beqz t2, exit                           # Jumps to exit if cause is not expected
 
    csrr t5,mepc                            # read the value of mepc 
    bne t3,t5,exit                          # check the value of mepc with it's expected value

    bne  t0, t4, exit                       # jumps to exit if EXPECTED_CAUSE is'nt equal to mcause

continue_execution:
    INCREMENT_MEPC                          # update the value of mepc 
    mret

next_instr:

    INCREMENT_MEPC                          # update the value of mepc 
    li t1,MSTATUS_MPP                       # update the MPP to MSTATUS_MPP for M mode
    csrw mstatus,t1                         # update the value mstatus MPP 
    mret

.text
.global _start

_start:
    ALL_MEM_PMP                                                     # PMP permission to all the mem
    la t1,trap_handler                                              # loads the address of trap handler 
    csrw mtvec,t1                                                   # sets the mtvec to trap handler 
    
PTE_LEVEL1_SUPERVISOR:

# ----------------LEVEL 1 PTE Setup for load and store test---------------------

    la a1,vm_en                                                     # loads the address of label vm_en
    mv a0, a1                                                       # generrates the VA for label vm_en
    ori a2, x0, ( PTE_D | PTE_A | PTE_X | PTE_W | PTE_R | PTE_V )   # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1
 
    la a1,rvtest_data                                               # loads the address of label rvtest_data
    mv a0, a1                                                       # generrates the VA for label rvtest_data
    ori a2, x0, ( PTE_D | PTE_A | PTE_X | PTE_W | PTE_R )           # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1   

    la a1,rvtest_check                                              # loads the address of label rvtest_data
    mv a0, a1                                                       # generrates the VA for label rvtest_data                                          
    ori a2, x0, ( PTE_D | PTE_A | PTE_X | PTE_W | PTE_R | PTE_V)    # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1

# ----------------Set the SATP and change the mode---------------------


    SATP_SETUP_SV32(pgtb_l1)                                        # set the SATP for virtualization
    la a1,vm_en                                                     # loads the address of vm_en 
    CHANGE_T0_S_MODE(a1)                                            # changes mode M to S and set the MEPC value to a1

# ----------------Virtualization Enabeled---------------------

vm_en:

    li t1,10
pre_load:

    la t1, rvtest_check
    la t2, check_load
    li t3, CAUSE_LOAD_PAGE_FAULT
    li t4, 1    
    sw t4, 0(t1)                                                    # store 1 to indicate cause is expected   
    sw t2, 4(t1)                                                    # store the address where cause is expected 
    sw t3, 8(t1)                                                    # store the mcause value of expected cause
    la a1, rvtest_data                                              # loads the address of label rvtest_data

check_load:

    lw t1,0(a1)  
    nop

pre_store:

    la t1, rvtest_check
    la t2, check_store
    li t3, CAUSE_STORE_PAGE_FAULT
    li t4, 1    
    sw t4, 0(t1)                                                    # store 1 to indicate cause is expected   
    sw t2, 4(t1)                                                    # store the address where cause is expected 
    sw t3, 8(t1)                                                    # store the mcause value of expected cause
    la a1,rvtest_data                                               # loads the address of label rvtest_data

check_store:
    sw t1,0(a1)
    nop                          
    ecall

# -------------LEVEL 1 PTE Setup for execute test------------------------
                                                                    # Setup a new PTE to test execute 
    la a1,check_execute                                             # loads the address of label vm_en
    mv a0, a1 
    ori a2, x0, ( PTE_D | PTE_A | PTE_X | PTE_W | PTE_R )           # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1

pre_execute:

    la t1, rvtest_check
    la t2, check_execute
    li t3, CAUSE_FETCH_PAGE_FAULT
    li t4, 1    
    sw t4, 0(t1)                                                    # store 1 to indicate cause is expected   
    sw t2, 4(t1)                                                    # store the address where cause is expected 
    sw t3, 8(t1)                                                    # store the mcause value of expected cause
    la a1,rvtest_data                                               # loads the address of label rvtest_data


# ----------------Set the SATP and change the mode---------------------

    SATP_SETUP_SV32(pgtb_l1)                                        # set the SATP for virtualization
    la a1,check_execute                                             # loads the address of check_execute
    CHANGE_T0_S_MODE(a1)                                            # changes mode M to S and set the MEPC 

check_execute:
    li t1, 0x45                                                     # page fault should raise 

    addi s11,s11,1
    li t1,1
    beq s11,t1,PTE_LEVEL1_USER
    j exit

PTE_LEVEL1_USER:

# ----------------LEVEL 1 PTE Setup for load and store test---------------------

    la a1,vm_en                                                     # loads the address of label vm_en
    mv a0, a1                                                       # generrates the VA for label vm_en
    ori a2, x0, ( PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V )   # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1
 
    la a1,rvtest_data                                               # loads the address of label rvtest_data
    mv a0, a1                                                       # generrates the VA for label rvtest_data
    ori a2, x0, ( PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R )           # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1   

    la a1,rvtest_check                                              # loads the address of label rvtest_data
    mv a0, a1                                                       # generrates the VA for label rvtest_data                                          
    ori a2, x0, ( PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V)    # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1

# ----------------Set the SATP and change the mode---------------------


    SATP_SETUP_SV32(pgtb_l1)                                        # set the SATP for virtualization
    la a1,vm_en                                                     # loads the address of vm_en 
    CHANGE_T0_U_MODE(a1)                                            # changes mode M to S and set the MEPC value to a1



RVTEST_EXIT_LOGIC                                                    # Exit logic 

.data  
.align 24
    rvtest_check: 

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