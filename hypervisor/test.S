# disable --enable pmp flag in run.sh

.section .text

.globl _start

_start:

    la t3, code
    csrw mepc, t3
    la t3, trap
    csrw mtvec, t3
    li t1, 0x80
    csrw misa,t1
    li t2,  0x1000000800
    csrs mstatus, t2

    mret

code:

    nop
    j exit

trap:

    csrr t0, mcause
    j exit

exit:

    li x1, 1
    la t0, tohost
    sw x1, 0(t0)
    j exit

.data

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;