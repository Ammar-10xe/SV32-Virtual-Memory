#=======================================================================
#   🌟 SATP mode =Bare for Level1 PTE 🌟
#-----------------------------------------------------------------------
# Test Description:
#
# If PTE does not have the SATP setuped then, accessing it
# would raise a ILLEGAL_INSTRUCTION fault exception.
# When satp.mode=Bare and PTE has (r,w,x) PMP permissions, this test
# covers the following scenarios in both supervisor and user privilege
# modes for level1 PTE.
#
# 💫 Set SATP = Bare and rest bits to zeros and test the access to PTE.
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

    li t5, CAUSE_ILLEGAL_INSTRUCTION                                       # load the value of illegal instruction fault 
    beq t0,t5,Back_to_check_access                                         # if illegal instruction fault jump to check access in M mode


continue_execution:

    INCREMENT_MEPC                                                         # update the value of mepc 
    mret

next_instr:
    INCREMENT_MEPC                                                         # update the value of mepc 
    li t1,MSTATUS_MPP                                                      # update the MPP to MSTATUS_MPP for M mode
    csrs mstatus,t1                                                        # update the value mstatus MPP 
    mret

Back_to_check_access:
    la t3,check_access                                                     # loads the address of check_access
    csrw mepc,t3                                                           # update the value of mepc with check_access address
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

# -------------LEVEL 1 PTE Setup for execute test----------------------
                                                                            # Setup a new PTE to test execute 
    la a1,check_access                                                     # loads the address of label vm_en
    li a0 , 0x82000000                                                      # loads the address of label vm_en 
    ori a2, x0, ( PTE_D | PTE_A | PTE_X | PTE_W | PTE_R | PTE_V )           # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                                  # setup the PTE for level1

# -------------------Pre_Access-------------------------------------
    la t1, rvtest_check
    li t2 , 0x82000000
    li t3, CAUSE_ILLEGAL_INSTRUCTION
    li t4, 1    
    sw t4, 0(t1)                                                            # store 1 to indicate cause is expected   
    sw t2, 4(t1)                                                            # store the address where cause is expected 
    sw t3, 8(t1)                                                            # store the mcause value of expected cause
    la a1,rvtest_data                                                       # loads the address of label rvtest_data

# ----------------Set the SATP and change the mode---------------------

    csrw satp, x0           	                                            # Write satp with all zeros (bare mode)
    li a1 , 0x82000000                                                      # loads the address of check_access
    CHANGE_T0_S_MODE(a1)                                                    # changes mode M to S and set the MEPC 

PTE_LEVEL1_USER:

# -------------LEVEL 1 PTE Setup for execute test----------------------
                                                                            # Setup a new PTE to test execute 
    la a1,check_access                                                     # loads the address of label vm_en
    li a0 , 0x82000000 
    ori a2, x0, ( PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V )   # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                                  # setup the PTE for level1

# -------------------Pre_Access-------------------------------------
    la t1, rvtest_check
    li t2 , 0x82000000
    li t3, CAUSE_ILLEGAL_INSTRUCTION
    li t4, 1    
    sw t4, 0(t1)                                                            # store 1 to indicate cause is expected   
    sw t2, 4(t1)                                                            # store the address where cause is expected 
    sw t3, 8(t1)                                                            # store the mcause value of expected cause
    la a1,rvtest_data                                                       # loads the address of label rvtest_data

# ----------------Set the SATP to Bare_Mode and change the mode---------------------

    csrw satp, x0           	                                            # Write satp with all zeros (bare mode)
    li a1 , 0x82000000                                                      # loads the address of check_access
    CHANGE_T0_U_MODE(a1)                                                    # changes mode M to S and set the MEPC  


check_access:
    li t1, 0x45                                                             # Illegal instruction fault Should raise 
    la a1, rvtest_data
    lw t1,8(a1)
    bne t1, x0,exit 
    sw t4,8(a1)
    j PTE_LEVEL1_USER
  
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