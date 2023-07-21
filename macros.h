#include "encoding.h"

#define pgtb_le1 0x80001000
#define pgtb_le0 0x80002000

#define SATP_SV32_MODE_VAL 0x01

#define SREG sw
#define LREG lw
#define MRET mret

#define CHECK_SV32_MODE(REG)                               ;\
    GET_SATP_MODE(REG)                                     ;

#define GET_SATP_MODE(DST_REG)                             ;\
    READ_CSR(satp, DST_REG)                                ;\
    srli DST_REG, DST_REG, 31                              ;\

#define WRITE_CSR(CSR_REG, SRC_REG)                        ;\
    csrw CSR_REG, SRC_REG                                  ;

#define CLEAR_CSR(CSR_REG, SRC_REG)                        ;\
    csrc CSR_REG, SRC_REG                                  ;

#define SET_CSR(CSR_REG, SRC_REG)                          ;\
    csrw CSR_REG, SRC_REG                                  ;

#define READ_CSR(CSR_REG, DST_REG)                         ;\
    csrr DST_REG, CSR_REG                                  ;

#define PTE(PA, PR)                                        ;\
    srli     PA,   PA, 12                                  ;\
    slli     PA,   PA, 10                                  ;\
    or       PA,   PA, PR                                  ;

#define PTE(PA, PR)                                        ;\
    srli     PA, PA, 12                                    ;\
    slli     PA, PA, 10                                    ;\
    or       PA, PA, PR                                    ;

#define PTE_SETUP_RV32(PA, PR, TMP, VA, level)             ;\
    PTE(PA, PR)                                            ;\
    .if (level==1)                                         ;\
        la   TMP, pgtb_le1                                 ;\
        srli VA,  VA, 22                                   ;\
    .endif                                                 ;\
    .if (level==0)                                         ;\
        li   TMP, pgtb_le0                                 ;\
        slli VA,  VA, 10                                   ;\
        srli VA,  VA, 22                                   ;\
    .endif                                                 ;\
    slli     VA,  VA,  2                                   ;\
    add      TMP, TMP, VA                                  ;\
    SREG     PA,  0(TMP)                                   ;    

#define SATP_SETUP_SV32                                    ;\
    la   t6,   pgtb_le1                                    ;\
    li   t5,   SATP32_MODE                                 ;\
    srli t6,   t6, 12                                      ;\
    or   t6,   t6, t5                                      ;\
    WRITE_CSR(satp, t6)                                    ;

#define EXIT_LOGIC(REG)                                    ;\
    li   t1, 1                                             ;\
    SREG t1, 0(REG)                                        ;

#define GEN_VA(PA, VA, UP_10_BITS, MID_10_BITS)            ;\
    slli VA, PA, 20                                        ;\
    srli VA, VA, 20                                        ;\
    li   t0, UP_10_BITS                                    ;\
    slli t0, t0, 22                                        ;\
    or   VA, VA, t0                                        ;\
    li   t0, MID_10_BITS                                   ;\
    slli t0, t0, 12                                        ;\
    or   VA, VA, t0                                        ;
