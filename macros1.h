#include "encoding.h"

#define _start   rvtest_entry_point                            

#define LEVEL0 0x00
#define LEVEL1 0x01

#define OFFSET_SHIFT 12
#define SUPERPAGE_SHIFT 22

#define PTE(PA, PR)                                                ;\
    srli     PA, PA, OFFSET_SHIFT                                  ;\
    slli     PA, PA, PTE_PPN_SHIFT                                 ;\
    or       PA, PA, PR                                            ;

#define PTE_SETUP_RV32(PA, PR, TMP, VA, level)                     ;\
    PTE(PA, PR)                                                    ;\
    .if (level==1)                                                 ;\
        la   TMP, pgtb_l1                                          ;\
        srli VA,  VA, SUPERPAGE_SHIFT                              ;\
    .endif                                                         ;\
    .if (level==0)                                                 ;\
        la   TMP, pgtb_l0                                          ;\
        slli VA,  VA, PTE_PPN_SHIFT                                ;\
        srli VA,  VA, SUPERPAGE_SHIFT                              ;\
    .endif                                                         ;\
    slli     VA,  VA,  2                                           ;\
    add      TMP, TMP, VA                                          ;\
    sw     PA,  0(TMP)                                             ;

#define SATP_SETUP_SV32(PGTB_ADDR)                                 ;\
    la   t6,   PGTB_ADDR                                           ;\
    li   t5,   SATP32_MODE                                         ;\
    srli t6,   t6, OFFSET_SHIFT                                    ;\
    or   t6,   t6, t5                                              ;\
    csrw satp, t6                                                  ;\
    sfence.vma                                                     ;

#define CHANGE_T0_S_MODE(MEPC_ADDR)                                ;\
    li        t0, MSTATUS_MPP                                      ;\
    csrc mstatus, t0                                               ;\
    li  t1, MSTATUS_MPP & ( MSTATUS_MPP >> 1)                      ;\
    csrs mstatus, t1                                               ;\
    csrw mepc, MEPC_ADDR                                           ;\
    mret                                                           ;

#define CHANGE_T0_U_MODE(MEPC_ADDR)                                ;\
    li        t0, MSTATUS_MPP                                      ;\
    csrc mstatus, t0                                               ;\
    csrw mepc, MEPC_ADDR                                           ;\
    mret                                                           ;


#define RVTEST_EXIT_LOGIC                                          ;\
exit:                                                              ;\
    la t0, tohost                                                  ;\
    li t1, 1                                                       ;\
    sw t1, 0(t0)                                                   ;\
    j exit                                                         ;

#define COREV_VERIF_EXIT_LOGIC                                     ;\
exit:                                                              ;\
	slli x1, x1, 1                                                 ;\
    addi x1, x1, 1                                                 ;\
    mv x30, s1                                                     ;\
	sw x1, tohost, x30                                             ;\
	self_loop: j self_loop                                         ;

#define ALL_MEM_PMP                                                ;\
    li t2, -1		                                               ;\
	csrw pmpaddr0, t2                                              ;\
	li t2, 0x0F		                                               ;\
	csrw pmpcfg0, t2                                               ;\
    sfence.vma                                                     ;

#define INCREMENT_MEPC                                             ;\
   csrr t3,mepc                                                    ;\
    addi t3,t3,4                                                   ;\
    csrw mepc,t3                                                   ;
 