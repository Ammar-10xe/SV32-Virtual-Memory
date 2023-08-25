#################################################################################################   
# Verification Goal:   Set mstatus.MXR = 0 and check the load access on the valid PTE with      #
#                      only PTE.X = 1 should raise load page fault in supervisor/user mode.     #
#                      PTE is at level 0                                                        #
#                                                                                               # 
# Feature Discription: If PTE has only execute permission (pte.x = 1) and s/mstatus.MXR=0,      #
#                      then read access on that PTE should raise load page fault exception.     #
#################################################################################################


#===============================================================================
#   🌟 Make Executable Page Readable with s/mstatus.MXR unset at Level0 PTE 🌟
#-------------------------------------------------------------------------------
# Test Description:
#
# If PTE has only execute permission (pte.x = 1) and s/mstatus.MXR=0,
# then read access on that PTE should raise load page fault exception.
#
# 💫 Set only the PTE.X = 1 and mstatus.MXR = 0 and test the read access
#
#================================================================================

#include "../../../macros1.h"

trap_handler:

    csrr t0, mcause                                                 # read the value of mcause 
    la t1, rvtest_check                                             # load the address of trvtest_check
    
    lw t2, 0(t1)                                                    # if cause expected then load 1 else 0
    lw t3, 4(t1)                                                    # load the expected value of mepc 
    lw t4, 8(t1)                                                    # load the expected value of mcause  

    li t5, CAUSE_FETCH_PAGE_FAULT                                   # load the value of fetch page fault exception 
    beq t0,t5,next_instr                                            # if fetch page fault jump to next instr in M mode

    li  t1, CAUSE_SUPERVISOR_ECALL                                  # load the value of supervisor ecall
    beq t0,t1,next_instr                                            # checks if ecall is occured

    li  t1, CAUSE_USER_ECALL                                        # load the value of user ecall
    beq t0,t1,next_instr                                            # checks for ecall is occured

    beqz t2, exit                                                   # Jumps to exit if cause is not expected
 
    csrr t5,mepc                                                    # read the value of mepc 
    bne t3,t5,exit                                                  # check the value of mepc with it's expected value

    bne  t0, t4, exit                                               # jumps to exit if EXPECTED_CAUSE is'nt equal to mcause

continue_execution:
    INCREMENT_MEPC                                                  # update the value of mepc 
    mret

next_instr:

    INCREMENT_MEPC                                                  # update the value of mepc 
    li t1,MSTATUS_MPP                                               # update the MPP to MSTATUS_MPP for M mode
    csrs mstatus,t1                                                 # update the value mstatus MPP 
    mret

.text
.global _start

_start:
    ALL_MEM_PMP                                                     # PMP permission to all the mem
    la t1,trap_handler                                              # loads the address of trap handler 
    csrw mtvec,t1                                                   # sets the mtvec to trap handler 
    
PTE_LEVEL0_SUPERVISOR:

# ----------------LEVEL 0 PTE Setup for load and store test---------------------

    la a1,pgtb_l0                                                   # loads the address of label vm_en
    la a0, _start                                                   # VA = PA - Identity Map
    ori a2, x0, ( PTE_V )                                           # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1 

    la a1,vm_en                                                     # loads the address of label vm_en
    mv a0, a1                                                       # VA = PA - Identity Map
    ori a2, x0, ( PTE_D | PTE_A | PTE_X | PTE_W | PTE_R | PTE_V )   # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL0)                          # setup the PTE for LEVEL0
 
    la a1,rvtest_data                                               # loads the address of label rvtest_data
    mv a0, a1                                                       # VA = PA - Identity Map
    ori a2, x0, ( PTE_D | PTE_A | PTE_X | PTE_W | PTE_V )           # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL0)                          # setup the PTE for LEVEL0   

    la a1,rvtest_check                                              # loads the address of label rvtest_data
    mv a0, a1                                                       # VA = PA - Identity Map                                         
    ori a2, x0, ( PTE_D | PTE_A | PTE_X | PTE_W | PTE_R | PTE_V)    # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL0)                          # setup the PTE for LEVEL0

# ----------------Set the SATP and change the mode---------------------


    SATP_SETUP_SV32(pgtb_l1)                                        # set the SATP for virtualization
    li a1, MSTATUS_MXR
    csrc mstatus, a1                                                # Clear mstatus.MXR
    la a1,vm_en                                                     # loads the address of vm_en 
    CHANGE_T0_S_MODE(a1)                                            # changes mode M to S and set the MEPC value to a1

# ----------------Virtualization Enabeled---------------------

vm_en:

    li t1,10
pre_load:

    la t1, rvtest_check                                             # loads the address of rvtest_check section
    la t2, check_load                                               # Next Exception PC
    li t3, CAUSE_LOAD_PAGE_FAULT                                    # Next Expected Cause
    li t4, 1    
    sw t4, 0(t1)                                                    # store 1 to indicate cause is expected   
    sw t2, 4(t1)                                                    # store the address where cause is expected 
    sw t3, 8(t1)                                                    # store the mcause value of expected cause
    la a1, rvtest_data                                              # loads the address of label rvtest_data

check_load:

    lw t1,0(a1)  
    nop
    ecall
    lw  t1, 12(a1)
    bne t1, x0, exit 

PTE_LEVEL0_USER:

    sw t4, 12(a1)

# ----------------LEVEL 0 PTE Setup for load and store test---------------------

    la a1,vm_en                                                     # loads the address of label vm_en
    mv a0, a1                                                       # VA = PA - Identity Map
    ori a2, x0, ( PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V )   # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL0)                          # setup the PTE for LEVEL0
 
    la a1,rvtest_data                                               # loads the address of label rvtest_data
    mv a0, a1                                                       # VA = PA - Identity Map
    ori a2, x0, ( PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_V )           # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL0)                          # setup the PTE for LEVEL0   

    la a1,rvtest_check                                              # loads the address of label rvtest_data
    mv a0, a1                                                       # VA = PA - Identity Map                                          
    ori a2, x0, ( PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V)    # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL0)                          # setup the PTE for LEVEL0

# ----------------Set the SATP and change the mode---------------------


    SATP_SETUP_SV32(pgtb_l1)                                        # set the SATP for virtualization
    li a1, MSTATUS_MXR
    csrc mstatus, a1                                                # Clear mstatus.MXR
    la a1,vm_en                                                     # loads the address of vm_en 
    CHANGE_T0_U_MODE(a1)                                            # changes mode M to U and set the MEPC value to a1


COREV_VERIF_EXIT_LOGIC                                              # Exit logic 

.data
rvtest_check: 

    .word 0xdeadbeef                                                # 1 for cause expected 0  for no cause 
    .word 0xbeefdead                                                # write the value of mepc here (where  cause is expected)
    .word 0xcafecafe                                                # write the value of expect cause 
.align 12                                  
rvtest_data:   
    .word 0xbeefcafe                                                 
    .word 0xdeadcafe                                                 
    .word 0xcafecafe                                                 
    .word 0x00000000  
.align 12                                                      
    pgtb_l1:                                                       
        .zero 4096                                                 
    pgtb_l0:                                                       
        .zero 4096                                                                                                     

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;