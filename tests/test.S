.section .text

.globl _start
_start:
    la t3, code
    csrw mepc, t3
    la t3, trap
    csrw mtvec, t3
    li t2,  0x00800
    csrw mstatus, t2
    mret

code:
    li t6, 89
    j exit

trap:
    csrr t0, mcause
    j exit

exit:
    li x1, 0
    slli x1, x1, 1
    addi x1, x1, 1
    sw x1, tohost, x30
    self_loop: j self_loop

.data

pgtb_l1:
    .zero 4096
.align 12
pgtb_l0:
    .zero 4096
arr:
.word 0x23

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;