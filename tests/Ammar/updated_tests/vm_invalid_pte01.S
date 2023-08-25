#=======================================================================
#   🌟 RWX Access of Level1 PTE in User and Supervisor mode when valid
#      bit is low  🌟
#-----------------------------------------------------------------------
# Test Description:
#
# If PTE does not have the Valid (pte.V=0) permission, accessing it
# would raise a page fault exception of the corresponding access type.
# When satp.mode=sv32 and PTE has (r,w,x) PMP permissions, this test
# covers the following scenarios in both supervisor and user privilege
# modes for level1 PTE.
#
# 💫 Set PTE.V = 0 and test the read access.
# 💫 Set PTE.V = 0 and test the write access.
# 💫 Set PTE.V = 0 and test the execute access.
#
#=======================================================================

#include "../../../macros1.h"

trap_handler:

    csrr t0, mcause                                                        # read the value of mcause 
    la t1, rvtest_check                                                    # load the address of trvtest_check
    
    lw t2, 0(t1)                                                           # if cause expected then load 1 else 0
    lw t3, 4(t1)                                                           # load the expected value of mepc 
    lw t4, 8(t1)                                                           # load the expected value of mcause  

    li  t1, CAUSE_SUPERVISOR_ECALL                                         # load the value of supervisor ecall
    beq t0,t1,next_instr                                                   # checks if ecall is occured

    li  t1, CAUSE_USER_ECALL                                               # load the value of user ecall
    beq t0,t1,next_instr                                                   # checks for ecall is occured

    beqz t2, exit                                                          # Jumps to exit if cause is not expected
 
    csrr t5,mepc                                                           # read the value of mepc 
    bne t3,t5,exit                                                         # check the value of mepc with it's expected value

    bne  t0, t4, exit                                                      # jumps to exit if EXPECTED_CAUSE is'nt equal to mcause

    li t5, CAUSE_FETCH_ACCESS                                              # load the value of fetch access fault
    beq t0, t5, next_instr                                                 # if fetch access fault jump to next instr in M mode  

    li t5, CAUSE_FETCH_PAGE_FAULT                                          # load the value of fetch page fault exception 
    beq t0,t5,next_instr                                                   # if fetch page fault jump to next instr in M mode


continue_execution:

    INCREMENT_MEPC                                                         # update the value of mepc 
    mret

next_instr:

    INCREMENT_MEPC                                                         # update the value of mepc 
    li t1,MSTATUS_MPP                                                      # update the MPP to MSTATUS_MPP for M mode
    csrs mstatus,t1                                                        # update the value mstatus MPP 
    mret

.text
.global _start

_start:
    ALL_MEM_PMP                                                            # PMP permission to all the mem
    la t1,trap_handler                                                     # loads the address of trap handler 
    csrw mtvec,t1                                                          # sets the mtvec to trap handler 
    
PTE_LEVEL1_SUPERVISOR:

# ----------------LEVEL 1 PTE Setup for load and store test------------

    la a1,vm_en                                                            # loads the address of label vm_en
    mv a0, a1                                                              # generrates the VA for label vm_en
    ori a2, x0, ( PTE_D | PTE_A | PTE_X | PTE_V )              as an argument to the test?             # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l1, LEVEL1)                        # setup the PTE for level1
 
    la a1,rvtest_data                                                      # loads the address of label rvtest_data
    mv a0, a1                                                              # generrates the VA for label rvtest_data
    ori a2, x0, ( PTE_D | PTE_A | PTE_X | PTE_W | PTE_R )                  # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l1, LEVEL1)                        # setup the PTE for level1   

    la a1,rvtest_check                                                     # loads the address of label rvtest_data
    mv a0, a1                                                              # generrates the VA for label rvtest_data                                          
    ori a2, x0, ( PTE_D | PTE_A | PTE_W | PTE_R | PTE_V )                  # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l1, LEVEL1)                        # setup the PTE for level1

# ----------------Set the SATP and change the mode---------------------


    SATP_SETUP_SV32(pgtb_l1)                                               # set the SATP for virtualization
    la a1,vm_en                                                            # loads the address of vm_en 
    CHANGE_T0_S_MODE(a1)                                                   # changes mode M to S and set the MEPC value to a1

# ----------------Virtualization Enabeled------------------------------

vm_en:

    li t1,10                                                               
    
pre_load:

    TEST_PROLOG(check_load,CAUSE_LOAD_PAGE_FAULT)                           # load the addr and expected cause 
    la a1, rvtest_data                                                      # loads the address of label rvtest_data

check_load:

    lw t1,0(a1)                                                            # tests the load access 
    nop

pre_store:

    TEST_PROLOG(check_store,CAUSE_STORE_PAGE_FAULT)                         # load the addr and expected cause 
    la a1,rvtest_data                                                       # loads the address of label rvtest_data

check_store:
    sw t1,0(a1)                                                             # test the store access
    nop                          
    ecall

pre_execute:

    TEST_PROLOG(check_execute,CAUSE_FETCH_PAGE_FAULT)                       # load the addr and expected cause 
    la a1,rvtest_data                                                       # loads the address of label rvtest_data

    lw t1,12(a1)                                                            # load the value 4th word of rvtest_data
    bne t1, x0,PTE_LEVEL1_USER_EXECUTE                                      # test if the data load is'nt zero goto PTE_LEVEL1_USER_EXECUTE        
    sw t4,12(a1)                                                            # store a random value
    
PTE_LEVEL1_SUPERVISOR_EXECUTE:

# -------------LEVEL 1 PTE Setup for execute test----------------------
                                                                            # Setup a new PTE to test execute 
    la a1,check_execute                                                     # loads the address of label vm_en
    mv a0, a1 
    ori a2, x0, ( PTE_D | PTE_A | PTE_X | PTE_W | PTE_R )                   # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l1, LEVEL1)                        # setup the PTE for level1

# ----------------Set the SATP and change the mode---------------------

    SATP_SETUP_SV32(pgtb_l1)                                                # set the SATP for virtualization
    la a1,check_execute                                                     # loads the address of check_execute
    CHANGE_T0_S_MODE(a1)                                                    # changes mode M to S and set the MEPC 

PTE_LEVEL1_USER_EXECUTE:

# -------------LEVEL 1 PTE Setup for execute test----------------------
                                                                            # Setup a new PTE to test execute 
    la a1,check_execute                                                     # loads the address of label vm_en
    mv a0, a1 
    ori a2, x0, ( PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R )           # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l1, LEVEL1)                         # setup the PTE for level1

# ----------------Set the SATP and change the mode---------------------

    SATP_SETUP_SV32(pgtb_l1)                                                # set the SATP for virtualization
    la a1,check_execute                                                     # loads the address of check_execute
    CHANGE_T0_U_MODE(a1)                                                    # changes mode M to S and set the MEPC 


check_execute:
    li t1, 0x45                                                             # page fault should raise 

    la a1, rvtest_data                                                      # loads the address of rvtest_data
    lw t1,8(a1)                                                             # load the value in t1    
    bne t1,x0,exit                                                          # test the branch condition 
    sw t4,8(a1)                                                             # store a random value 
    

PTE_LEVEL1_USER:

# ----------------LEVEL 1 PTE Setup for load and store test------------

    la a1,vm_en                                                             # loads the address of label vm_en
    mv a0, a1                                                               # generrates the VA for label vm_en
    ori a2, x0, ( PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V )   # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l1, LEVEL1)                         # setup the PTE for level1
 
    la a1,rvtest_data                                                       # loads the address of label rvtest_data
    mv a0, a1                                                               # generrates the VA for label rvtest_data
    ori a2, x0, ( PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R )           # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l1, LEVEL1)                         # setup the PTE for level1

    la a1,rvtest_check                                                      # loads the address of label rvtest_data
    mv a0, a1                                                               # generrates the VA for label rvtest_data                                          
    ori a2, x0, ( PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V)    # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, pgtb_l1, LEVEL1)                         # setup the PTE for level1

# ----------------Set the SATP and change the mode---------------------


    SATP_SETUP_SV32(pgtb_l1)                                                # set the SATP for virtualization
    la a1,vm_en                                                             # loads the address of vm_en 
    CHANGE_T0_U_MODE(a1)                                                    # changes mode M to S and set the MEPC value to a1



RVTEST_EXIT_LOGIC                                                           # Exit logic 

.data  
.align 24
    rvtest_check: 

        .word 0xdeadbeef                                                    # 1 for cause expected 0  for no cause 
        .word 0xbeefdead                                                    # write the value of mepc here (where  cause is expected)
        .word 0xcafecafe                                                    # write the value of expect cause 
.align 22                                     
    rvtest_data:   
        .word 0xbeefcafe                                                 
        .word 0xdeadcafe                                                 
        .word 0x00000000                                                 
        .word 0x00000000 
.align 12                                                      
    pgtb_l1:                                                       
        .zero 4096                                                 
    pgtb_l0:                                                       
        .zero 4096                                                                                                     

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;