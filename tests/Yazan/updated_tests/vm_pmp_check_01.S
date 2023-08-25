#################################################################################################   
# Verification Goal:   Remove X PMP Permission of code section, and R and W Permission of data  #
#                      section For Level 1 PTE. For execute, read and write access, fetch,      #
#                      load and store/amo access fault should raise respectively.               #
#                                                                                               # 
# Feature Discription: If PTE has valid and non-reserved RWX permissions, but the translated    #
#                      Physical address (pte.ppn of leaf PTE + offset) does not have (r,w,x)    #
#                      PMP permissions, then accessing the translated Physical address would    #
#                      raise access fault exception.                                            #
#################################################################################################   

#include "../../../macros1.h"

#define NAPOT_RANGE_4KB 0x1FF                                       # Set 4kB range with NAPOT
#define NAPOT_RANGE_32B 0x3                                         # Set 32B range with NAPOT

trap_handler:

    csrr t0, mcause                                                 # read the value of mcause 
    la t1, rvtest_check                                             # load the address of trvtest_check
    
    lw t2, 0(t1)                                                    # if cause expected then load 1 else 0
    lw t3, 4(t1)                                                    # load the expected value of mepc 
    lw t4, 8(t1)                                                    # load the expected value of mcause

    li t5, CAUSE_FETCH_ACCESS                                       # load the value of fetch access fault
    beq t0, t5, next_instr                                          # if fetch access fault jump to next instr in M mode

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
    csrw mstatus,t1                                                 # update the value mstatus MPP 
    mret

.text
.global _start

_start:

# -------------------------------- PMP Configurations --------------------------------

    la t2, vm_en                         					        # Loads the address of vm_en                
    srli t2, t2, PMP_SHIFT									        # Right shift the PA by PMP_Shift(2) 
    ori t2, t2, NAPOT_RANGE_4KB                                     # Selects the range of 4kB    
    csrw pmpaddr0, t2           	                                # Region 1 for the pmp permissions
    sfence.vma  

    la t2, pgtb_l1                                                  # loads the base address of level1 4kbpage table                 
    srli t2, t2, PMP_SHIFT 									        # Right shift the address of level 1 page table  by PMP_Shift(2)
    ori t2, t2, NAPOT_RANGE_4KB                                     # Selects the range of 8kB
    csrw pmpaddr1, t2                                               # Region 2 for the pmp permission
    sfence.vma

    la t2, rvtest_check                                             # loads the base address of rvtest_check label        
    srli t2, t2, PMP_SHIFT                                          # Right shift the address of rvtest_data label by PMP_Shift(2)
    ori t2, t2, NAPOT_RANGE_32B                                     # Selects the range of 32B    
	csrw pmpaddr2, t2       								        # Region 3 for the pmp permission
    sfence.vma

    la t2, rvtest_data                                              # loads the base address of rvtest_data label        
    srli t2, t2, PMP_SHIFT                                          # Right shift the address of rvtest_data label by PMP_Shift(2)
    ori t2, t2, NAPOT_RANGE_32B                                     # Selects the range of 32B    
	csrw pmpaddr3, t2       								        # Region 4 for the pmp permission
    sfence.vma

    # Region 1, 2, 3: NAPOT with RWX PMP Permissions
    # Region 4:     : NAPOT with X PMP Permission only
    li t2, ((PMP_NAPOT | PMP_X) << 24) | ((PMP_NAPOT | PMP_X | PMP_W | PMP_R) << 16) | ((PMP_NAPOT | PMP_X | PMP_W | PMP_R) << 8) | (PMP_NAPOT | PMP_X | PMP_W | PMP_R)
    csrw pmpcfg0, t2                                                # Write PMP Regions Configration
    sfence.vma

    la t1,trap_handler                                              # loads the address of trap handler 
    csrw mtvec,t1                                                   # sets the mtvec to trap handler 
    
PTE_LEVEL1_SUPERVISOR:

# ----------------LEVEL 1 PTE Setup for load and store test---------------------

    la a1,vm_en                                                     # loads the address of label vm_en
    mv a0, a1                                                       # VA = PA - Identity Map
    ori a2, x0, ( PTE_D | PTE_A | PTE_X | PTE_W | PTE_R | PTE_V )   # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1
 
    la a1,rvtest_data                                               # loads the address of label rvtest_data
    mv a0, a1                                                       # VA = PA - Identity Map
    ori a2, x0, ( PTE_D | PTE_A | PTE_X | PTE_W | PTE_R | PTE_V )   # sets the permission bits
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1   

    la a1,rvtest_check                                              # loads the address of label rvtest_data
    mv a0, a1                                                       # VA = PA - Identity Map                                         
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

    la t1, rvtest_check                                             # loads the address of rvtest_check section
    la t2, check_load                                               # Next Exception PC
    li t3, CAUSE_LOAD_ACCESS                                        # Next Expected Cause
    li t4, 1    
    sw t4, 0(t1)                                                    # store 1 to indicate cause is expected   
    sw t2, 4(t1)                                                    # store the address where cause is expected 
    sw t3, 8(t1)                                                    # store the mcause value of expected cause
    la a1, rvtest_data                                              # loads the address of label rvtest_data

check_load:

    lw t1,0(a1)  
    nop

pre_store:

    la t1, rvtest_check                                             # loads the address of rvtest_check section
    la t2, check_store                                              # Next Exception PC
    li t3, CAUSE_STORE_ACCESS                                       # Next Expected Cause
    li t4, 1    
    sw t4, 0(t1)                                                    # store 1 to indicate cause is expected   
    sw t2, 4(t1)                                                    # store the address where cause is expected 
    sw t3, 8(t1)                                                    # store the mcause value of expected cause
    la a1,rvtest_data                                               # loads the address of label rvtest_data

check_store:
    sw t1,0(a1)
    nop                          
    ecall

pre_execute:

    la t1, rvtest_check                                             # loads the address of rvtest_check section
    la t2, check_execute                                            # Next Exception PC
    li t3, CAUSE_FETCH_ACCESS                                       # Next Expected Cause
    li t4, 1    
    sw t4, 0(t1)                                                    # store 1 to indicate cause is expected   
    sw t2, 4(t1)                                                    # store the address where cause is expected 
    sw t3, 8(t1)                                                    # store the mcause value of expected cause
    la a1,rvtest_data                                               # loads the address of label rvtest_data

    addi s10,s10,1
    li s1,1
    li s2,2

    li t2, (PMP_NAPOT | PMP_X | PMP_W | PMP_R)
    csrc pmpcfg0, t2                                                # Clear PMP Region 1 Configration
    li t2, (PMP_NAPOT | PMP_W | PMP_R)
    csrs pmpcfg0, t2                                                # Set PMP Region 1 Configration
    sfence.vma

    la a1,check_execute                                             # loads the address of check_execute

    beq s10,s1,PMP_LEVEL1_SUPERVISOR_EXECUTE
    beq s10,s2,PMP_LEVEL1_USER_EXECUTE

PMP_LEVEL1_SUPERVISOR_EXECUTE: 

    CHANGE_T0_S_MODE(a1)                                            # changes mode M to S and set the MEPC 

PMP_LEVEL1_USER_EXECUTE:

    CHANGE_T0_U_MODE(a1)                                            # changes mode M to S and set the MEPC 

check_execute:
    li t1, 0x45                                                     # page fault should raise 

    bne s11, x0, exit
    addi s11, s11, 1

PTE_LEVEL1_USER:

    li s11, 1

# ----------------LEVEL 1 PTE Setup for load and store test---------------------

    la a1,vm_en                                                     # loads the address of label vm_en
    mv a0, a1                                                       # VA = PA - Identity Map
    # sets the permission bits
    ori a2, x0, ( PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V )
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1
 
    la a1,rvtest_data                                               # loads the address of label rvtest_data
    mv a0, a1                                                       # VA = PA - Identity Map
    # sets the permission bits
    ori a2, x0, ( PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V )
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1   

    la a1,rvtest_check                                              # loads the address of label rvtest_data
    mv a0, a1                                                       # VA = PA - Identity Map  
    # sets the permission bits                                        
    ori a2, x0, ( PTE_D | PTE_A | PTE_U | PTE_X | PTE_W | PTE_R | PTE_V) 
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL1)                          # setup the PTE for level1

    li t2, (PMP_X)
    csrs pmpcfg0, t2                                                # Clear PMP Region 1 Configration
    sfence.vma

# ----------------Set the SATP and change the mode---------------------


    SATP_SETUP_SV32(pgtb_l1)                                        # set the SATP for virtualization
    la a1,vm_en                                                     # loads the address of vm_en 
    CHANGE_T0_U_MODE(a1)                                            # changes mode M to U and set the MEPC value to a1



COREV_VERIF_EXIT_LOGIC                                              # Exit logic 

.data  
.align 24
    rvtest_check: 

        .word 0xdeadbeef                                            # 1 for cause expected 0  for no cause 
        .word 0xbeefdead                                            # write the value of mepc here (where  cause is expected)
        .word 0xcafecafe                                            # write the value of expect cause 
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