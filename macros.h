#include "encoding.h"

#define MSTATUS_MPS 0x00000800
#define pgtb_le1 0x80001000
#define pgtb_le0 0x80002000

#define SATP_SV32_MODE_VAL 0x01

#define SREG sw
#define LREG lw
#define MRET mret
#define S_MODE 0x02
#define U_MODE 0x00

#define FLUSH 0x1
#define NO_FLUSH 0x0

#define _ARG5(_1ST,_2ND, _3RD,_4TH,_5TH,...) _5TH
#define _ARG4(_1ST,_2ND, _3RD,_4TH,...) _4TH
#define _ARG3(_1ST,_2ND, _3RD, ...) _3RD
#define _ARG2(_1ST,_2ND, ...) _2ND
#define _ARG1(_1ST,...) _1ST
#define NARG(...) _ARG5(__VA_OPT__(__VA_ARGS__,)4,3,2,1,0)

#define WRITE_MEPC(_TR1, LABEL)                                    ;\
    la _TR1, LABEL                                                 ;\
    WRITE_CSR(mepc, _TR1)                                          ;

#define SET_RWX_PERMISSION(REG, ZERO)                              ;\
    .if(ZERO==FLUSH)                                               ;\
        SET_PTE_R(REG, FLUSH)                                      ;\
    .else                                                          ;\
        SET_PTE_R(REG, NO_FLUSH)                                   ;\
    .endif                                                         ;\
    SET_PTE_W(REG, NO_FLUSH)                                       ;\
    SET_PTE_X(REG, NO_FLUSH)                                       ;

#define SET_RWXV_BITS(REG, ZERO)                                   ;\
    .if(ZERO==FLUSH)                                               ;\
        SET_PTE_R(REG, FLUSH)                                      ;\
    .else                                                          ;\
        SET_PTE_R(REG, NO_FLUSH)                                   ;\
    .endif                                                         ;\
    SET_PTE_W(REG, NO_FLUSH)                                       ;\
    SET_PTE_X(REG, NO_FLUSH)                                       ;\
    SET_PTE_V(REG, NO_FLUSH)                                       ;

#define SET_RW_BITS(REG, ZERO)                                     ;\
    .if(ZERO==FLUSH)                                               ;\
        SET_PTE_R(REG, FLUSH)                                      ;\
    .else                                                          ;\
        SET_PTE_R(REG, NO_FLUSH)                                   ;\
    .endif                                                         ;\
    SET_PTE_W(REG, NO_FLUSH)                                       ;\

#define SET_RV_BITS(REG, ZERO)                                     ;\
    .if(ZERO==FLUSH)                                               ;\
        SET_PTE_R(REG, FLUSH)                                      ;\
    .else                                                          ;\
        SET_PTE_R(REG, NO_FLUSH)                                   ;\
    .endif                                                         ;\
    SET_PTE_V(REG, NO_FLUSH)                                       ;\

#define SET_WV_BITS(REG, ZERO)                                     ;\
    .if(ZERO==FLUSH)                                               ;\
        SET_PTE_W(REG, FLUSH)                                      ;\
    .else                                                          ;\
        SET_PTE_W(REG, NO_FLUSH)                                   ;\
    .endif                                                         ;\
    SET_PTE_V(REG, NO_FLUSH)                                       ;\

#define SET_PTE_R(REG, ZERO)                                       ;\
    .if(ZERO==FLUSH)                                               ;\
        li REG, 0                                                  ;\
    .endif                                                         ;\
    ori REG, REG, PTE_R                                            ;

#define SET_PTE_W(REG, ZERO)                                       ;\
    .if(ZERO==FLUSH)                                               ;\
        li REG, 0                                                  ;\
    .endif                                                         ;\
    ori REG, REG, PTE_W                                            ;

#define SET_PTE_X(REG, ZERO)                                       ;\
    .if(ZERO==FLUSH)                                               ;\
        li REG, 0                                                  ;\
    .endif                                                         ;\
    ori REG, REG, PTE_X                                            ;

#define SET_PTE_U(REG, ZERO)                                       ;\
    .if(ZERO==FLUSH)                                               ;\
        li REG, 0                                                  ;\
    .endif                                                         ;\
    ori REG, REG, PTE_U                                            ;

#define SET_PTE_G(REG, ZERO)                                       ;\
    .if(ZERO==FLUSH)                                               ;\
        li REG, 0                                                  ;\
    .endif                                                         ;\
    ori REG, REG, PTE_G                                            ;

#define SET_PTE_A(REG, ZERO)                                       ;\
    .if(ZERO==FLUSH)                                               ;\
        li REG, 0                                                  ;\
    .endif                                                         ;\
    ori REG, REG, PTE_A                                            ;

#define SET_PTE_D(REG, ZERO)                                       ;\
    .if(ZERO==FLUSH)                                               ;\
        li REG, 0                                                  ;\
    .endif                                                         ;\
    ori REG, REG, PTE_D                                            ;

#define SET_PTE_V(REG, ZERO)                                       ;\
    .if(ZERO==FLUSH)                                               ;\
        li REG, 0                                                  ;\
    .endif                                                         ;\
    ori REG, REG, PTE_V                                            ;

#define CHECK_SV32_MODE(REG)                                       ;\
    GET_SATP_MODE(REG)                                             ;

#define GET_SATP_MODE(DST_REG)                                     ;\
    READ_CSR(satp, DST_REG)                                        ;\
    srli DST_REG, DST_REG, 31                                      ;\

#define WRITE_CSR(CSR_REG, SRC_REG)                                ;\
    csrw CSR_REG, SRC_REG                                          ;

#define CLEAR_CSR(CSR_REG, SRC_REG)                                ;\
    csrc CSR_REG, SRC_REG                                          ;

#define SET_CSR(CSR_REG, SRC_REG)                                  ;\
    csrs CSR_REG, SRC_REG                                          ;

#define READ_CSR(CSR_REG, DST_REG)                                 ;\
    csrr DST_REG, CSR_REG                                          ;

#define PTE(PA, PR)                                                ;\
    srli     PA, PA, 12                                            ;\
    slli     PA, PA, PTE_PPN_SHIFT                                 ;\
    or       PA, PA, PR                                            ;

#define PTE_SETUP_RV32(PA, PR, TMP, VA, level)                     ;\
    PTE(PA, PR)                                                    ;\
    .if (level==1)                                                 ;\
        la   TMP, pgtb_l1                                          ;\
        srli VA,  VA, 22                                           ;\
    .endif                                                         ;\
    .if (level==0)                                                 ;\
        la   TMP, pgtb_l0                                          ;\
        slli VA,  VA, 10                                           ;\
        srli VA,  VA, 22                                           ;\
    .endif                                                         ;\
    slli     VA,  VA,  2                                           ;\
    add      TMP, TMP, VA                                          ;\
    SREG     PA,  0(TMP)                                           ;

#define SATP_SETUP_SV32                                            ;\
    la   t6,   pgtb_l1                                             ;\
    li   t5,   SATP32_MODE                                         ;\
    srli t6,   t6, 12                                              ;\
    or   t6,   t6, t5                                              ;\
    WRITE_CSR(satp, t6)                                            ;

#define EXIT_LOGIC(REG, VAL)                                       ;\
    SREG VAL, 0(REG)                                               ;

#define GEN_VA(PA, VA, UP_10_BITS, MID_10_BITS)                    ;\
    slli VA, PA, 20                                                ;\
    srli VA, VA, 20                                                ;\
    li   t0, UP_10_BITS                                            ;\
    slli t0, t0, 22                                                ;\
    or   VA, VA, t0                                                ;\
    li   t0, MID_10_BITS                                           ;\
    slli t0, t0, 12                                                ;\
    or   VA, VA, t0                                                ;


#define CLEAR_ALL_PMPADDR                                          ;\
    WRITE_CSR(pmpaddr0, x0)                                        ;\
    WRITE_CSR(pmpaddr1, x0)                                        ;\
    WRITE_CSR(pmpaddr2, x0)                                        ;\
    WRITE_CSR(pmpaddr3, x0)                                        ;\
    WRITE_CSR(pmpaddr4, x0)                                        ;\
    WRITE_CSR(pmpaddr5, x0)                                        ;\
    WRITE_CSR(pmpaddr6, x0)                                        ;\
    WRITE_CSR(pmpaddr7, x0)                                        ;\
    WRITE_CSR(pmpaddr8, x0)                                        ;\
    WRITE_CSR(pmpaddr9, x0)                                        ;\
    WRITE_CSR(pmpaddr10, x0)                                       ;\
    WRITE_CSR(pmpaddr11, x0)                                       ;\
    WRITE_CSR(pmpaddr12, x0)                                       ;\
    WRITE_CSR(pmpaddr13, x0)                                       ;\
    WRITE_CSR(pmpaddr14, x0)                                       ;\
    WRITE_CSR(pmpaddr15, x0)                                       ;

#define CLEAR_ALL_PMPCFG                                           ;\
    WRITE_CSR(pmpcfg0, x0)                                         ;\
    WRITE_CSR(pmpcfg1, x0)                                         ;\
    WRITE_CSR(pmpcfg2, x0)                                         ;\
    WRITE_CSR(pmpcfg3, x0)                                         ;\


#define CHANGE_T0_S_MODE(MEPC_ADDR)                                ;\
    li        t0, MSTATUS_MPP                                      ;\
    CLEAR_CSR (mstatus, t0)                                        ;\
    li t1,    MSTATUS_MPS                                          ;\
    SET_CSR   (mstatus,t1)                                         ;\
    WRITE_CSR (mepc,MEPC_ADDR)                                     ;\
    mret                                                           ;

#define CHANGE_T0_U_MODE(SEPC_ADDR)                                ;\
    li        t0, SSTATUS_SPP                                      ;\
    CLEAR_CSR (sstatus,t0)                                         ;\
    WRITE_CSR (sepc,SEPC_ADDR)                                     ;\
    sret                                                           ;

#define LA(reg,val)                                                ;\
        .option push                                               ;\
        .option rvc                                                ;\
        .align UNROLLSZ                                            ;\
        .option norvc                                              ;\
        la reg,val                                                 ;\
        .align UNROLLSZ                                            ;\
        .option p                                                  ;

#define TEST_ACCESS_BIT(MODE, LEVEL, R, W, X, XA, A)               ;\
    li t2, -1		                                               ;\
	csrw pmpaddr0, t2                                              ;\
	li t2, 0x0F		                                               ;\
	csrw pmpcfg0, t2                                               ;\
    li t2, 0x23;\
    la t1, test_seg;\
    sw t2, 0(t1);\
    .if(LEVEL == 0)                                                ;\
        la a1, pgtb_l0                                             ;\
        GEN_VA(a1, a0, 0x003, 0x002)                               ;\
        SET_PTE_V(a2, FLUSH)                                       ;\
        PTE_SETUP_RV32(a1, a2, t1, a0, 1)                          ;\
    .endif                                                         ;\
    .if(MODE == S_MODE)                                            ;\
        la a1, supervisor_code                                     ;\
    .else                                                          ;\
        la a1, user_code                                           ;\
        SET_PTE_U(a2, FLUSH)                                       ;\
    .endif                                                         ;\
    GEN_VA(a1, a0, 0x003, 0x000)                                   ;\
    mv t3, a0                                                      ;\
    .if(X == 1)                                                    ;\
        SET_PTE_X(a2, NO_FLUSH)                                       ;\
    .endif                                                         ;\
    .if(XA == 1)                                                   ;\
        SET_PTE_A(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    SET_PTE_W(a2, NO_FLUSH)                                        ;\
    SET_PTE_R(a2, NO_FLUSH)                                        ;\
    SET_PTE_D(a2, NO_FLUSH)                                        ;\
    SET_PTE_V(a2, NO_FLUSH)                                        ;\
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL)                          ;\
    la a1, test_seg                                                     ;\
    .if(LEVEL == 0)                                                ;\
        GEN_VA(a1, a0, 0x003, 0x004)                               ;\
    .else                                                          ;\
        GEN_VA(a1, a0, 0x004, 0x000)                               ;\
    .endif                                                         ;\
    mv t4, a0                                                      ;\
    .if(R == 1)                                                    ;\
        SET_PTE_R(a2, FLUSH)                                       ;\
    .endif                                                         ;\
    .if(W == 1)                                                    ;\
        SET_PTE_W(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    .if(A == 1)                                                    ;\
        SET_PTE_A(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    SET_PTE_D(a2, NO_FLUSH)                                        ;\
    SET_PTE_V(a2, NO_FLUSH)                                        ;\
    .if(MODE == U_MODE)                                            ;\
        SET_PTE_U(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL)                          ;\
    la t1, tohost                                                  ;\
    mv a1, t1                                                      ;\
    .if(LEVEL == 0)                                                ;\
        GEN_VA(a1, a0, 0x003, 0x005)                               ;\
    .else                                                          ;\
        GEN_VA(a1, a0, 0x005, 0x000)                               ;\
    .endif                                                         ;\
    mv s1, a0                                                      ;\
    SET_RWXV_BITS(a2, FLUSH)                                       ;\
    SET_PTE_A(a2, NO_FLUSH)                                        ;\
    SET_PTE_D(a2, NO_FLUSH)                                        ;\
    .if(MODE == U_MODE)                                            ;\
        SET_PTE_U(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL)                          ;\
    SATP_SETUP_SV32                                                ;\
    la t2, trap_handler                                            ;\
    WRITE_CSR (mtvec, t2)                                          ;\
    WRITE_CSR (mepc, t3)                                           ;\
    li t2, 0x1800                                                  ;\
    CLEAR_CSR (mstatus, t2)                                        ;\
    .if(MODE == S_MODE)                                            ;\
        li t2,  0x00800                                            ;\
    .else                                                          ;\
        li t2, 0xC0000                                             ;\
    .endif                                                         ;\
    SET_CSR (mstatus, t2)                                          ;\
    MRET                                                           ;\
    supervisor_code:                                               ;\
    li t1, 0x45                                                    ;\
    .if(R == 1)                                                    ;\
        lw t1, 0(t4)                                               ;\
    .endif                                                         ;\
    .if(W == 1)                                                    ;\
        sw t1, 0(t4)                                               ;\
    .endif                                                         ;\
    .if(A&XA!=1)                                                   ;\
        li x1, 1                                                   ;\
    .endif                                                         ;\
    j exit                                                         ;\
    user_code:                                                     ;\
    li t1, 0x45                                                    ;\
    .if(R == 1)                                                    ;\
        lw t1, 0(t4)                                               ;\
    .endif                                                         ;\
    .if(W == 1)                                                    ;\
        sw t1, 0(t4)                                               ;\
    .endif                                                         ;\
    .if(A&XA!=1)                                                   ;\
        li x1, 1                                                   ;\
    .endif                                                         ;\
    j exit                                                         ;

#define ABit_trap_handler                                          ;\
    trap_handler:                                                  ;\
        csrr  t0,    mcause                                        ;\
        li    t1,   1;\
        beq   t0,   t1, instruction_access_fault;\
        li    t1,   2;\
        beq   t0,   t1, illegal_instruction_fault;\
        li    t1,   5;\
        beq   t0,   t1, load_access_fault;\
        li    t1,   7;\
        beq   t0,   t1, store_access_fault;\
        li    t1,   12                                             ;\
        beq   t0,   t1, instruction_page_fault                     ;\
        li    t1,   13                                             ;\
        beq   t0,   t1, load_page_fault                            ;\
        li    t1,   15                                             ;\
        beq   t0,   t1, store_page_fault                           ;\
        j     trap_handler_end                                     ;\
    instruction_access_fault: ;\
        li x1, 0                                                   ;\
        la s1, tohost                                              ;\
        j exit;\
    illegal_instruction_fault:;\
        li x1, 0                                                   ;\
        la s1, tohost                                              ;\
        j exit;\
    load_access_fault:;\
        li x1, 0                                                   ;\
        la s1, tohost                                              ;\
        j exit;\
    store_access_fault:;\
        li x1, 0                                                   ;\
        la s1, tohost                                              ;\
        j exit;\
    instruction_page_fault:                                        ;\
        li x1, 0                                                   ;\
        la s1, tohost                                              ;\
        j exit                                                     ;\
    load_page_fault:                                               ;\
        li x1, 0                                                   ;\
        la s1, tohost                                              ;\
        j exit                                                     ;\
    store_page_fault:                                              ;\
        li x1, 0                                                   ;\
        la s1, tohost                                              ;\
        j exit                                                     ;\
    trap_handler_end:                                              ;\
        j exit                                                     ;

#define TEST_MXR_UNSET(MODE, LEVEL, R, W, X, XA, A)               ;\
    li t2, -1		                                               ;\
	csrw pmpaddr0, t2                                              ;\
	li t2, 0x0F		                                               ;\
	csrw pmpcfg0, t2                                               ;\
    li t2, 0x23;\
    la t1, test_seg;\
    sw t2, 0(t1);\
    .if(LEVEL == 0)                                                ;\
        la a1, pgtb_l0                                             ;\
        GEN_VA(a1, a0, 0x003, 0x002)                               ;\
        SET_PTE_V(a2, FLUSH)                                       ;\
        PTE_SETUP_RV32(a1, a2, t1, a0, 1)                          ;\
    .endif                                                         ;\
    .if(MODE == S_MODE)                                            ;\
        la a1, supervisor_code                                     ;\
    .else                                                          ;\
        la a1, user_code                                           ;\
        SET_PTE_U(a2, FLUSH)                                       ;\
    .endif                                                         ;\
    GEN_VA(a1, a0, 0x003, 0x000)                                   ;\
    mv t3, a0                                                      ;\
    .if(X == 1)                                                    ;\
        SET_PTE_X(a2, NO_FLUSH)                                       ;\
    .endif                                                         ;\
    .if(XA == 1)                                                   ;\
        SET_PTE_A(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    SET_PTE_W(a2, NO_FLUSH)                                        ;\
    SET_PTE_R(a2, NO_FLUSH)                                        ;\
    SET_PTE_D(a2, NO_FLUSH)                                        ;\
    SET_PTE_V(a2, NO_FLUSH)                                        ;\
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL)                          ;\
    la a1, test_seg                                                     ;\
    .if(LEVEL == 0)                                                ;\
        GEN_VA(a1, a0, 0x003, 0x004)                               ;\
    .else                                                          ;\
        GEN_VA(a1, a0, 0x004, 0x000)                               ;\
    .endif                                                         ;\
    mv t4, a0                                                      ;\
    .if(R == 1)                                                    ;\
        SET_PTE_R(a2, FLUSH)                                       ;\
    .endif                                                         ;\
    .if(W == 1)                                                    ;\
        SET_PTE_W(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    .if(A == 1)                                                    ;\
        SET_PTE_A(a2, FLUSH)                                    ;\
    .endif                                                         ;\
    SET_PTE_D(a2, NO_FLUSH)                                        ;\
    SET_PTE_V(a2, NO_FLUSH)                                        ;\
    SET_PTE_X(a2, NO_FLUSH)                                        ;\
    .if(MODE == U_MODE)                                            ;\
        SET_PTE_U(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL)                          ;\
    la t1, tohost                                                  ;\
    mv a1, t1                                                      ;\
    .if(LEVEL == 0)                                                ;\
        GEN_VA(a1, a0, 0x003, 0x005)                               ;\
    .else                                                          ;\
        GEN_VA(a1, a0, 0x005, 0x000)                               ;\
    .endif                                                         ;\
    mv s1, a0                                                      ;\
    SET_RWXV_BITS(a2, FLUSH)                                       ;\
    SET_PTE_A(a2, NO_FLUSH)                                        ;\
    SET_PTE_D(a2, NO_FLUSH)                                        ;\
    .if(MODE == U_MODE)                                            ;\
        SET_PTE_U(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL)                          ;\
    SATP_SETUP_SV32                                                ;\
    la t2, trap_handler                                            ;\
    WRITE_CSR (mtvec, t2)                                          ;\
    WRITE_CSR (mepc, t3)                                           ;\
    li t2, 0x1800                                                  ;\
    CLEAR_CSR (mstatus, t2)                                        ;\
    .if(MODE == S_MODE)                                            ;\
        li t2,  0x00800                                            ;\
    .else                                                          ;\
        li t2, 0x00000                                             ;\
    .endif                                                         ;\
    SET_CSR (mstatus, t2)                                          ;\
    MRET                                                           ;\
    supervisor_code:                                               ;\
    li t1, 0x45                                                    ;\
    lw t1, 0(t4)                                               ;\
    .if(A&XA!=1)                                                   ;\
        li x1, 1                                                   ;\
    .endif                                                         ;\
    j exit                                                         ;\
    user_code:                                                     ;\
    li t1, 0x45                                                    ;\
    lw t1, 0(t4)                                               ;\
    .if(A&XA!=1)                                                   ;\
        li x1, 1                                                   ;\
    .endif                                                         ;\
    j exit                                                         ;

#define TEST_SUM_UNSET(MODE, LEVEL, R, W, X, XA, A)                 ;\
    li t2, -1		                                               ;\
	csrw pmpaddr0, t2                                              ;\
	li t2, 0x0F		                                               ;\
	csrw pmpcfg0, t2                                               ;\
    li t2, 0x23;\
    la t1, test_seg;\
    sw t2, 0(t1);\
    .if(LEVEL == 0)                                                ;\
        la a1, pgtb_l0                                             ;\
        GEN_VA(a1, a0, 0x003, 0x002)                               ;\
        SET_PTE_V(a2, FLUSH)                                       ;\
        PTE_SETUP_RV32(a1, a2, t1, a0, 1)                          ;\
    .endif                                                         ;\
    .if(MODE == S_MODE)                                            ;\
        la a1, supervisor_code                                     ;\
    .else                                                          ;\
        la a1, user_code                                           ;\
    .endif                                                         ;\
    GEN_VA(a1, a0, 0x003, 0x000)                                   ;\
    mv t3, a0                                                      ;\
    .if(X == 1)                                                    ;\
        SET_PTE_X(a2, NO_FLUSH)                                       ;\
    .endif                                                         ;\
    .if(XA == 1)                                                   ;\
        SET_PTE_A(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    SET_PTE_W(a2, NO_FLUSH)                                        ;\
    SET_PTE_R(a2, NO_FLUSH)                                        ;\
    SET_PTE_D(a2, NO_FLUSH)                                        ;\
    SET_PTE_V(a2, NO_FLUSH)                                        ;\
    .if(R|W==0)     ;\
    SET_PTE_U(a2, NO_FLUSH)                                       ;\
    .endif;\
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL)                          ;\
    la a1, test_seg                                                     ;\
    .if(LEVEL == 0)                                                ;\
        GEN_VA(a1, a0, 0x003, 0x004)                               ;\
    .else                                                          ;\
        GEN_VA(a1, a0, 0x004, 0x000)                               ;\
    .endif                                                         ;\
    mv t4, a0                                                      ;\
    .if(R == 1)                                                    ;\
        SET_PTE_R(a2, FLUSH)                                       ;\
    .endif                                                         ;\
    .if(W == 1)                                                    ;\
        SET_PTE_W(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    .if(A == 1)                                                    ;\
        SET_PTE_A(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    SET_PTE_D(a2, NO_FLUSH)                                        ;\
    SET_PTE_V(a2, NO_FLUSH)                                        ;\
    SET_PTE_U(a2, NO_FLUSH)                                       ;\
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL)                          ;\
    la t1, tohost                                                  ;\
    mv a1, t1                                                      ;\
    .if(LEVEL == 0)                                                ;\
        GEN_VA(a1, a0, 0x003, 0x005)                               ;\
    .else                                                          ;\
        GEN_VA(a1, a0, 0x005, 0x000)                               ;\
    .endif                                                         ;\
    mv s1, a0                                                      ;\
    SET_RWXV_BITS(a2, FLUSH)                                       ;\
    SET_PTE_A(a2, NO_FLUSH)                                        ;\
    SET_PTE_D(a2, NO_FLUSH)                                        ;\
    SET_PTE_U(a2, NO_FLUSH)                                       ;\
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL)                          ;\
    SATP_SETUP_SV32                                                ;\
    la t2, trap_handler                                            ;\
    WRITE_CSR (mtvec, t2)                                          ;\
    WRITE_CSR (mepc, t3)                                           ;\
    li t2, 0x1800                                                  ;\
    CLEAR_CSR (mstatus, t2)                                        ;\
    .if(MODE == S_MODE)                                            ;\
        li t2,  0x00800                                            ;\
    .else                                                          ;\
        li t2, 0x00000                                             ;\
    .endif                                                         ;\
    SET_CSR (mstatus, t2)                                          ;\
    MRET                                                           ;\
    supervisor_code:                                               ;\
    li t1, 0x45                                                    ;\
    .if(R == 1)                                                    ;\
        lw t1, 0(t4)                                               ;\
    .endif                                                         ;\
    .if(W == 1)                                                    ;\
        sw t1, 0(t4)                                               ;\
    .endif                                                         ;\
    .if(A&XA!=1)                                                   ;\
        li x1, 1                                                   ;\
    .endif                                                         ;\
    j exit                                                         ;\
    user_code:                                                     ;\
    li t1, 0x45                                                    ;\
    .if(R == 1)                                                    ;\
        lw t1, 0(t4)                                               ;\
    .endif                                                         ;\
    .if(W == 1)                                                    ;\
        sw t1, 0(t4)                                               ;\
    .endif                                                         ;\
    .if(A&XA!=1)                                                   ;\
        li x1, 1                                                   ;\
    .endif                                                         ;\
    j exit     ;

#define TEST_VM_PMP_CHECK(MODE, LEVEL, R, W, X, XA, A)               ;\
    li t2, 0x80000800		                                               ;\
    srli t2, t2, 2;\
	csrw pmpaddr0, t2                                              ;\
    li t2, 0x82000000		                                               ;\
    srli t2, t2, 2;\
	csrw pmpaddr1, t2                                              ;\
    li t2, 0x84000000		                                               ;\
    srli t2, t2, 2;\
	csrw pmpaddr2, t2                                              ;\
    la t2, test_seg		                                               ;\
    srli t2, t2, 2;\
    ori t2, t2, 0x0 ;\
	csrw pmpaddr3, t2                                              ;\
    .if((R|W)==0&X==1) ;\
	    li t2, 0x1F0F000B		                                               ;\
    .endif;\
    .if(R==0);\
        .if(W==1);\
        li t2, 0x1D0F000F		                                               ;\
        .endif;\
    .endif;\
    .if(R==1);\
        .if(W==0);\
        li t2, 0x1E0F000F		                                               ;\
        .endif;\
    .endif;\
	csrw pmpcfg0, t2                                               ;\
    li t2, 0x23;\
    la t1, test_seg;\
    sw t2, 0(t1);\
    .if(LEVEL == 0)                                                ;\
        la a1, pgtb_l0                                             ;\
        GEN_VA(a1, a0, 0x003, 0x002)                               ;\
        SET_PTE_V(a2, FLUSH)                                       ;\
        PTE_SETUP_RV32(a1, a2, t1, a0, 1)                          ;\
    .endif                                                         ;\
    .if(MODE == S_MODE)                                            ;\
        la a1, supervisor_code                                     ;\
    .else                                                          ;\
        la a1, user_code                                           ;\
        SET_PTE_U(a2, FLUSH)                                       ;\
    .endif                                                         ;\
    GEN_VA(a1, a0, 0x003, 0x000)                                   ;\
    mv t3, a0                                                      ;\
    .if(X == 1)                                                    ;\
        SET_PTE_X(a2, NO_FLUSH)                                       ;\
    .endif                                                         ;\
    .if(XA == 1)                                                   ;\
        SET_PTE_A(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    SET_PTE_W(a2, NO_FLUSH)                                        ;\
    SET_PTE_R(a2, NO_FLUSH)                                        ;\
    SET_PTE_D(a2, NO_FLUSH)                                        ;\
    SET_PTE_V(a2, NO_FLUSH)                                        ;\
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL)                          ;\
    la a1, test_seg                                                     ;\
    .if(LEVEL == 0)                                                ;\
        GEN_VA(a1, a0, 0x003, 0x004)                               ;\
    .else                                                          ;\
        GEN_VA(a1, a0, 0x004, 0x000)                               ;\
    .endif                                                         ;\
    mv t4, a0                                                      ;\
    .if(R == 1)                                                    ;\
        SET_PTE_R(a2, FLUSH)                                       ;\
    .endif                                                         ;\
    .if(W == 1)                                                    ;\
        SET_PTE_W(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    .if(A == 1)                                                    ;\
        SET_PTE_A(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    SET_PTE_D(a2, NO_FLUSH)                                        ;\
    SET_PTE_V(a2, NO_FLUSH)                                        ;\
    .if(MODE == U_MODE)                                            ;\
        SET_PTE_U(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL)                          ;\
    la t1, tohost                                                  ;\
    mv a1, t1                                                      ;\
    .if(LEVEL == 0)                                                ;\
        GEN_VA(a1, a0, 0x003, 0x005)                               ;\
    .else                                                          ;\
        GEN_VA(a1, a0, 0x005, 0x000)                               ;\
    .endif                                                         ;\
    mv s1, a0                                                      ;\
    SET_RWXV_BITS(a2, FLUSH)                                       ;\
    SET_PTE_A(a2, NO_FLUSH)                                        ;\
    SET_PTE_D(a2, NO_FLUSH)                                        ;\
    .if(MODE == U_MODE)                                            ;\
        SET_PTE_U(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL)                          ;\
    SATP_SETUP_SV32                                                ;\
    la t2, trap_handler                                            ;\
    WRITE_CSR (mtvec, t2)                                          ;\
    WRITE_CSR (mepc, t3)                                           ;\
    li t2, 0x1800                                                  ;\
    CLEAR_CSR (mstatus, t2)                                        ;\
    .if(MODE == S_MODE)                                            ;\
        li t2,  0x00800                                            ;\
    .else                                                          ;\
        li t2, 0xC0000                                             ;\
    .endif                                                         ;\
    SET_CSR (mstatus, t2)                                          ;\
    MRET                                                           ;\
    supervisor_code:                                               ;\
    li t1, 0x45                                                    ;\
    .if(R == 1)                                                    ;\
        lw t1, 0(t4)                                               ;\
    .endif                                                         ;\
    .if(W == 1)                                                    ;\
        sw t1, 0(t4)                                               ;\
    .endif                                                         ;\
    .if(A&XA!=1)                                                   ;\
        li x1, 1                                                   ;\
    .endif                                                         ;\
    j exit                                                         ;\
    user_code:                                                     ;\
    li t1, 0x45                                                    ;\
    .if(R == 1)                                                    ;\
        lw t1, 0(t4)                                               ;\
    .endif                                                         ;\
    .if(W == 1)                                                    ;\
        sw t1, 0(t4)                                               ;\
    .endif                                                         ;\
    .if(A&XA!=1)                                                   ;\
        li x1, 1                                                   ;\
    .endif                                                         ;\
    j exit                                                         ;


    //Macro for the pmp_check_for_pte

    #define TEST_PTE_VM_PMP_CHECK(MODE, LEVEL, R, W, X, A)         ;\
    li t2, 0x80000800		                                       ;\
    srli t2, t2, 2;\
	csrw pmpaddr0, t2                                              ;\
    li t2, 0x82000000		                                       ;\
    srli t2, t2, 2;\
	csrw pmpaddr1, t2                                              ;\
    li t2, 0x84000000		                                       ;\
    srli t2, t2, 2;\
	csrw pmpaddr2, t2                                              ;\
    la t2, test_seg		                                           ;\
    srli t2, t2, 2;\
    ori t2, t2, 0x0 ;\
	csrw pmpaddr3, t2                                              ;\
    .if((R|W)==0&X==1) ;\
	    li t2, 0x1F0B000F		                                   ;\
    .endif;\
    .if(R==0);\
        .if(W==1);\
        li t2, 0x1F0D000F		                                   ;\
        .endif;\
    .endif;\
    .if(R==1);\
        .if(W==0);\
        li t2, 0x1F0E000F		                                   ;\
        .endif;\
    .endif;\
	csrw pmpcfg0, t2                                               ;\
    li t2, 0x23;\
    la t1, test_seg;\
    sw t2, 0(t1);\
    .if(LEVEL == 0)                                                ;\
        la a1, pgtb_l0                                             ;\
        GEN_VA(a1, a0, 0x003, 0x002)                               ;\
        SET_PTE_V(a2, FLUSH)                                       ;\
        PTE_SETUP_RV32(a1, a2, t1, a0, 1)                          ;\
    .endif                                                         ;\
    .if(MODE == S_MODE)                                            ;\
        la a1, supervisor_code                                     ;\
    .else                                                          ;\
        la a1, user_code                                           ;\
        SET_PTE_U(a2, FLUSH)                                       ;\
    .endif                                                         ;\
    GEN_VA(a1, a0, 0x003, 0x000)                                   ;\
    mv t3, a0                                                      ;\
    .if(X == 1)                                                    ;\
        SET_PTE_X(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    SET_PTE_A(a2, NO_FLUSH)                                        ;\
    SET_PTE_W(a2, NO_FLUSH)                                        ;\
    SET_PTE_R(a2, NO_FLUSH)                                        ;\
    SET_PTE_D(a2, NO_FLUSH)                                        ;\
    SET_PTE_V(a2, NO_FLUSH)                                        ;\
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL)                          ;\
    la a1, test_seg                                                ;\
    .if(LEVEL == 0)                                                ;\
        GEN_VA(a1, a0, 0x003, 0x004)                               ;\
    .else                                                          ;\
        GEN_VA(a1, a0, 0x004, 0x000)                               ;\
    .endif                                                         ;\
    mv t4, a0                                                      ;\
    .if(R == 1)                                                    ;\
        SET_PTE_R(a2, FLUSH)                                       ;\
    .endif                                                         ;\
    .if(W == 1)                                                    ;\
        SET_PTE_W(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    .if(A == 1)                                                    ;\
        SET_PTE_A(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    SET_PTE_D(a2, NO_FLUSH)                                        ;\
    SET_PTE_V(a2, NO_FLUSH)                                        ;\
    .if(MODE == U_MODE)                                            ;\
        SET_PTE_U(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL)                          ;\
    la t1, tohost                                                  ;\
    mv a1, t1                                                      ;\
    .if(LEVEL == 0)                                                ;\
        GEN_VA(a1, a0, 0x003, 0x005)                               ;\
    .else                                                          ;\
        GEN_VA(a1, a0, 0x005, 0x000)                               ;\
    .endif                                                         ;\
    mv s1, a0                                                      ;\
    SET_RWXV_BITS(a2, FLUSH)                                       ;\
    SET_PTE_A(a2, NO_FLUSH)                                        ;\
    SET_PTE_D(a2, NO_FLUSH)                                        ;\
    .if(MODE == U_MODE)                                            ;\
        SET_PTE_U(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL)                          ;\
    SATP_SETUP_SV32                                                ;\
    la t2, trap_handler                                            ;\
    WRITE_CSR (mtvec, t2)                                          ;\
    WRITE_CSR (mepc, t3)                                           ;\
    li t2, 0x1800                                                  ;\
    CLEAR_CSR (mstatus, t2)                                        ;\
    .if(MODE == S_MODE)                                            ;\
        li t2,  0x00800                                            ;\
    .else                                                          ;\
        li t2, 0xC0000                                             ;\
    .endif                                                         ;\
    SET_CSR (mstatus, t2)                                          ;\
    MRET                                                           ;\
    supervisor_code:                                               ;\
    li t1, 0x45                                                    ;\
    .if(R == 1)                                                    ;\
        lw t1, 0(t4)                                               ;\
    .endif                                                         ;\
    .if(W == 1)                                                    ;\
        sw t1, 0(t4)                                               ;\
    .endif                                                         ;\
    j exit                                                         ;\
    user_code:                                                     ;\
    li t1, 0x45                                                    ;\
    .if(R == 1)                                                    ;\
        lw t1, 0(t4)                                               ;\
    .endif                                                         ;\
    .if(W == 1)                                                    ;\
        sw t1, 0(t4)                                               ;\
    .endif                                                         ;\
    li x1, 1                                                       ;\
    j exit                                                         ;


 #define PMP_ALL_MEM               ;\
    li t2, -1		               ;\
    WRITE_CSR (pmpaddr0, t2)       ;\
    li t2, 0x0F		               ;\
    WRITE_CSR (pmpcfg0, t2)        ;

    
#define TEST_UBIT_UNSET(MODE, LEVEL, R, W, X, A)                ;\
    li t2, -1		                                               ;\
	csrw pmpaddr0, t2                                              ;\
	li t2, 0x0F		                                               ;\
	csrw pmpcfg0, t2                                               ;\
    li t2, 0x23;\
    la t1, test_seg;\
    sw t2, 0(t1);\
    .if(LEVEL == 0)                                                ;\
        la a1, pgtb_l0                                             ;\
        GEN_VA(a1, a0, 0x003, 0x002)                               ;\
        SET_PTE_V(a2, FLUSH)                                       ;\
        PTE_SETUP_RV32(a1, a2, t1, a0, 1)                          ;\
    .endif                                                         ;\
    .if(MODE == S_MODE)                                            ;\
        la a1, supervisor_code                                     ;\
    .else                                                          ;\
        la a1, user_code                                           ;\
    .endif                                                         ;\
    GEN_VA(a1, a0, 0x003, 0x000)                                   ;\
    mv t3, a0                                                      ;\
    .if(X == 1)                                                    ;\
        SET_PTE_X(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    SET_PTE_A(a2, NO_FLUSH)                                        ;\
    SET_PTE_W(a2, NO_FLUSH)                                        ;\
    SET_PTE_R(a2, NO_FLUSH)                                        ;\
    SET_PTE_D(a2, NO_FLUSH)                                        ;\
    SET_PTE_V(a2, NO_FLUSH)                                        ;\
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL)                          ;\
    la a1, test_seg                                                ;\
    .if(LEVEL == 0)                                                ;\
        GEN_VA(a1, a0, 0x003, 0x004)                               ;\
    .else                                                          ;\
        GEN_VA(a1, a0, 0x004, 0x000)                               ;\
    .endif                                                         ;\
    mv t4, a0                                                      ;\
    .if(R == 1)                                                    ;\
        SET_PTE_R(a2, FLUSH)                                       ;\
    .endif                                                         ;\
    .if(W == 1)                                                    ;\
        SET_PTE_W(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    .if(A == 1)                                                    ;\
        SET_PTE_A(a2, NO_FLUSH)                                    ;\
    .endif                                                         ;\
    SET_PTE_D(a2, NO_FLUSH)                                        ;\
    SET_PTE_V(a2, NO_FLUSH)                                        ;\
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL)                          ;\
    la t1, tohost                                                  ;\
    mv a1, t1                                                      ;\
    .if(LEVEL == 0)                                                ;\
        GEN_VA(a1, a0, 0x003, 0x005)                               ;\
    .else                                                          ;\
        GEN_VA(a1, a0, 0x005, 0x000)                               ;\
    .endif                                                         ;\
    mv s1, a0                                                      ;\
    SET_RWXV_BITS(a2, FLUSH)                                       ;\
    SET_PTE_A(a2, NO_FLUSH)                                        ;\
    SET_PTE_D(a2, NO_FLUSH)                                        ;\
    PTE_SETUP_RV32(a1, a2, t1, a0, LEVEL)                          ;\
    SATP_SETUP_SV32                                                ;\
    la t2, trap_handler                                            ;\
    WRITE_CSR (mtvec, t2)                                          ;\
    WRITE_CSR (mepc, t3)                                           ;\
    li t2, 0x1800                                                  ;\
    CLEAR_CSR (mstatus, t2)                                        ;\
    .if(MODE == S_MODE)                                            ;\
        li t2,  0x00800                                            ;\
    .else                                                          ;\
        li t2, 0x00000                                             ;\
    .endif                                                         ;\
    SET_CSR (mstatus, t2)                                          ;\
    MRET                                                           ;\
    supervisor_code:                                               ;\
    li t1, 0x45                                                    ;\
    .if(R == 1)                                                    ;\
        lw t1, 0(t4)                                               ;\
    .endif                                                         ;\
    .if(W == 1)                                                    ;\
        sw t1, 0(t4)                                               ;\
    .endif                                                         ;\
        li x1, 1                                                   ;\
    j exit                                                         ;\
    user_code:                                                     ;\
    li t1, 0x45                                                    ;\
    .if(R == 1)                                                    ;\
        lw t1, 0(t4)                                               ;\
    .endif                                                         ;\
    .if(W == 1)                                                    ;\
        sw t1, 0(t4)                                               ;\
    .endif                                                         ;\
        li x1, 1                                                   ;\
    j exit     ;
