#################################################################################################           
#                                                                                               #
# Verification Goal:   SATP is accessible only in M and S mode not in U mode                    #
#                                                                                               #
# Description:         Satp is only accessible in M and S mode and illegal instruction          #
#                      exception is generated when accessed in lower privilege mode             #
#                                                                                               #
# Sub Feature:         Access permission                                                        #                
#                                                                                               #   
# Feature Discription: Access satp in M, S, and U mode using csrrw, csrrc, csrrs                #   
#                                                                                               #
#################################################################################################   

.include "./trap_handler.S"
#include "../../macros.h"

.text
.global _start
_start:

    PMP_ALL_MEM                    # set the PMP permissions
    TRAP_HANDLER(trap_handler)     # set mtvec for trap 
    li s1, ALL_F_S
    li s2, SATP32_PPN
    li s3, SATP32_ASID

machine_mode:

    CLEAR_CSR (satp,s1)
    SET_CSR   (satp,s2)
    WRITE_CSR (satp,s3)
    la t4, supervisor_mode                             
    CHANGE_T0_S_MODE(t4)           # changes mode from M to S

supervisor_mode:

    CLEAR_CSR (satp,s1)
    SET_CSR   (satp,s2)
    WRITE_CSR (satp,s3)
    la t4, user_mode                
    CHANGE_T0_U_MODE(t4)           # changes mode from S to U

user_mode:

    CLEAR_CSR (satp,s1)            # Illegal instruction exception is generated when accessed in U mode 
    SET_CSR   (satp,s2)
    WRITE_CSR (satp,s3)
    j exit

RVTEST_EXIT_LOGIC               