.section .text
.globl _start

_start:
    la      t0, supervisor
    csrw    mepc, t0
    la      t1, m_trap
    csrw    mtvec, t1
    li      t2, 0x1800
    csrc    mstatus, t2
    li      t3, 0x800
    csrs    mstatus, t3
    mret

m_trap:
    csrr    t0, mepc
    csrr    t1, mcause
    la      t2, supervisor
    csrw    mepc, t2
    j       write_tohost

supervisor:
    la      t0, user
    csrw    sepc, t0
    la      t1, s_trap   
    csrw    stvec, t1
    sret

s_trap:
    csrr    t0, sepc
    csrr    t1, scause
    ecall

user:
    li t0 ,1
    csrr    t0, mstatus
    # ecall
    

exit:
    la t0, tohost
    li t1, 1
    sw t1, 0(t0)
    j exit

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;
