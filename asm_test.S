.include "func_pte.S"
.include "trap_handler.S"
#.include "func1.s"
.text
.global _start
_start:

    
    la   t1,      pgtb_l0
    mv   a1,      t1
    li   a0,      0xA0002000
    li   a2,      0x001
    li   a3,      0x1
    jal  func_pte

    la   t1,      code 
    mv   a1,      t1
    li   a0,      0xA0000100
    li   a2,      0x0CF
    li   a3,      0x0
    jal  func_pte

    la   t1,      arr
    mv   a1,      t1
    li   a0,      0xA0004000
    li   a2,      0x0C3
    li   a3,      0x0
    jal  func_pte

    li   t1,      0x80000000
    la   t0,      pgtb_l1
    srli t0,      t0, 12
    or   t0,      t0, t1
    csrw satp,    t0

    la   t2,      trap_handler
    csrw mtvec,   t2
    li   t2,      0xA0000100
    csrw mepc,    t2
    li   t2,      0x1800
    csrc mstatus, t2
    li   t2,      0xC0800
    csrs mstatus, t2
    mret

code:
    li   t5,      0xA0004000
    lw   t6,      0(t5)
exit:
    la t0, tohost
    li t1, 1
    sw t1, 0(t0)
    j exit


.data

pgtb_l1:
    .zero 4096
.align 12
pgtb_l0:
    .zero 4096
pgtb_l0_1:
    .zero 4096
arr:
.word 0x23


.align 4; .global tohost;  tohost: .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;
