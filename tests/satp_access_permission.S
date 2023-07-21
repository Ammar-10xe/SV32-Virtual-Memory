# Verification Goals: Show that satp is only accessible in M and S mode and illegal instruction exception is generated when accessed in lower privilege mode
# Discription: Access satp in M, S, and U mode using csrrw, csrrc, csrrs

.text
.global _start
_start:

    la a0, machine_mode
    jalr a0
    j exit

machine_mode:
    # Save machine mode satp
    li t1, 0xdeadbeef
    csrrw s1, satp, t1
    li t2, 0x80000000
    csrrc s2, satp, t2
    li t3,0xbeefdead
    csrrs s3,satp,t3
    ret

    # # Switch to supervisor mode
    # la a0, supervisor_mode
    # csrw mepc, a0
    # li a0, 0x1
    # csrw mstatus, a0
    # mret





exit:
    la t0, tohost
    li t1, 1
    sw t1, 0(t0)
    j exit

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;

