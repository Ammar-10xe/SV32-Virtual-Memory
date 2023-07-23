#include "encoding.h"

#define pgtb_le1 0x80001000
#define pgtb_le0 0x80002000

#define SATP_SV32_MODE_VAL 0x01

#define SREG sw
#define LREG lw
#define MRET mret

#define FLUSH 0x1
#define NO_FLUSH 0x0

#define WRITE_MEPC(_TR1, LABEL)                             ;\
    la _TR1, LABEL                                          ;\
    WRITE_CSR(mepc, _TR1)                                   ;

#define SET_RWX_PERMISSION(REG, ZERO)                       ;\
    .if(ZERO==FLUSH)                                        ;\
        SET_PTE_R(REG, FLUSH)                               ;\
    .else                                                   ;\
        SET_PTE_R(REG, NO_FLUSH)                            ;\
    .endif                                                  ;\
    SET_PTE_W(REG, NO_FLUSH)                                ;\
    SET_PTE_X(REG, NO_FLUSH)                                ;

#define SET_RWXV_BITS(REG, ZERO)                            ;\
    .if(ZERO==FLUSH)                                        ;\
        SET_PTE_R(REG, FLUSH)                               ;\
    .else                                                   ;\
        SET_PTE_R(REG, NO_FLUSH)                            ;\
    .endif                                                  ;\
    SET_PTE_W(REG, NO_FLUSH)                                ;\
    SET_PTE_X(REG, NO_FLUSH)                                ;\
    SET_PTE_V(REG, NO_FLUSH)                                ;

#define SET_RW_BITS(REG, ZERO)                              ;\
    .if(ZERO==FLUSH)                                        ;\
        SET_PTE_R(REG, FLUSH)                               ;\
    .else                                                   ;\
        SET_PTE_R(REG, NO_FLUSH)                            ;\
    .endif                                                  ;\
    SET_PTE_W(REG, NO_FLUSH)                                ;\

#define SET_RV_BITS(REG, ZERO)                              ;\
    .if(ZERO==FLUSH)                                        ;\
        SET_PTE_R(REG, FLUSH)                               ;\
    .else                                                   ;\
        SET_PTE_R(REG, NO_FLUSH)                            ;\
    .endif                                                  ;\
    SET_PTE_V(REG, NO_FLUSH)                                ;\

#define SET_WV_BITS(REG, ZERO)                              ;\
    .if(ZERO==FLUSH)                                        ;\
        SET_PTE_W(REG, FLUSH)                               ;\
    .else                                                   ;\
        SET_PTE_W(REG, NO_FLUSH)                            ;\
    .endif                                                  ;\
    SET_PTE_V(REG, NO_FLUSH)                                ;\

#define SET_PTE_R(REG, ZERO)                                ;\
    .if(ZERO==FLUSH)                                        ;\
        li REG, 0                                           ;\
    .endif                                                  ;\
    ori REG, REG, PTE_R                                     ;

#define SET_PTE_W(REG, ZERO)                                ;\
    .if(ZERO==FLUSH)                                        ;\
        li REG, 0                                           ;\
    .endif                                                  ;\
    ori REG, REG, PTE_W                                     ;

#define SET_PTE_X(REG, ZERO)                                ;\
    .if(ZERO==FLUSH)                                        ;\
        li REG, 0                                           ;\
    .endif                                                  ;\
    ori REG, REG, PTE_X                                     ;

#define SET_PTE_U(REG, ZERO)                                ;\
    .if(ZERO==FLUSH)                                        ;\
        li REG, 0                                           ;\
    .endif                                                  ;\
    ori REG, REG, PTE_U                                     ;

#define SET_PTE_G(REG, ZERO)                                ;\
    .if(ZERO==FLUSH)                                        ;\
        li REG, 0                                           ;\
    .endif                                                  ;\
    ori REG, REG, PTE_G                                     ;

#define SET_PTE_A(REG, ZERO)                                ;\
    .if(ZERO==FLUSH)                                        ;\
        li REG, 0                                           ;\
    .endif                                                  ;\
    ori REG, REG, PTE_A                                     ;

#define SET_PTE_D(REG, ZERO)                                ;\
    .if(ZERO==FLUSH)                                        ;\
        li REG, 0                                           ;\
    .endif                                                  ;\
    ori REG, REG, PTE_D                                     ;

#define SET_PTE_V(REG, ZERO)                                ;\
    .if(ZERO==FLUSH)                                        ;\
        li REG, 0                                           ;\
    .endif                                                  ;\
    ori REG, REG, PTE_V                                     ;

#define CHECK_SV32_MODE(REG)                                ;\
    GET_SATP_MODE(REG)                                      ;

                                    ;    

#define GET_SATP_MODE(DST_REG)                              ;\
    READ_CSR(satp, DST_REG)                                 ;\
    srli DST_REG, DST_REG, 31                               ;\

#define WRITE_CSR(CSR_REG, SRC_REG)                         ;\
    csrw CSR_REG, SRC_REG                                   ;

#define CLEAR_CSR(CSR_REG, SRC_REG)                         ;\
    csrc CSR_REG, SRC_REG                                   ;

#define SET_CSR(CSR_REG, SRC_REG)                           ;\
    csrw CSR_REG, SRC_REG                                   ;

#define READ_CSR(CSR_REG, DST_REG)                          ;\
    csrr DST_REG, CSR_REG                                   ;

#define PTE(PA, PR)                                         ;\
    srli     PA,   PA, 12                                   ;\
    slli     PA,   PA, 10                                   ;\
    or       PA,   PA, PR                                   ;

#define PTE(PA, PR)                                         ;\
    srli     PA, PA, 12                                     ;\
    slli     PA, PA, 10                                     ;\
    or       PA, PA, PR                                     ;

#define PTE_SETUP_RV32(PA, PR, TMP, VA, level)              ;\
    PTE(PA, PR)                                             ;\
    .if (level==1)                                          ;\
        la   TMP, pgtb_le1                                  ;\
        srli VA,  VA, 22                                    ;\
    .endif                                                  ;\
    .if (level==0)                                          ;\
        li   TMP, pgtb_le0                                  ;\
        slli VA,  VA, 10                                    ;\
        srli VA,  VA, 22                                    ;\
    .endif                                                  ;\
    slli     VA,  VA,  2                                    ;\
    add      TMP, TMP, VA                                   ;\
    SREG     PA,  0(TMP)                                    ;

#define SATP_SETUP_SV32                                     ;\
    la   t6,   pgtb_le1                                     ;\
    li   t5,   SATP32_MODE                                  ;\
    srli t6,   t6, 12                                       ;\
    or   t6,   t6, t5                                       ;\
    WRITE_CSR(satp, t6)                                     ;

#define EXIT_LOGIC(REG)                                     ;\
    li   t1, 1                                              ;\
    SREG t1, 0(REG)                                         ;

#define GEN_VA(PA, VA, UP_10_BITS, MID_10_BITS)             ;\
    slli VA, PA, 20                                         ;\
    srli VA, VA, 20                                         ;\
    li   t0, UP_10_BITS                                     ;\
    slli t0, t0, 22                                         ;\
    or   VA, VA, t0                                         ;\
    li   t0, MID_10_BITS                                    ;\
    slli t0, t0, 12                                         ;\
    or   VA, VA, t0                                         ;
