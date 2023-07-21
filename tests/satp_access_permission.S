# Verification Goals: Show that satp is only accessible in M and S mode and illegal instruction exception is generated when accessed in lower privilege mode
# Discription: Access satp in M, S, and U mode using csrrw, csrrc, csrrs

.include "../trap_handler.S"
.text
.global _start
_start:
    la t1, trap_handler
    csrw   mtvec, t1
    la a0, machine_mode
    jalr a0 
    j exit

machine_mode:

    li t1, 0x0000ffff
    li t2, 0xffffffff
    li t3, 0x12345678
    csrrs s3, satp, t1
    csrrc s2, satp, t2
    csrrw s1, satp, t3
    // If SATP is accessible chnagae mode to S
    la   t4, change_mode_supervisor
    j    a1
    
change_mode_supervisor: // Chnages mode from M to S

    li      t0, 0x1800
    csrc    mstatus, t0
    li      t1, 0x800
    csrs    mstatus, t1
    la      t2, supervisor_mode
    csrw    mepc,t2 
    mret  
    
supervisor_mode:
    
    li t1, 0x0000ffff
    li t2, 0xffffffff
    li t3, 0x12345678
    csrrs s3, satp, t1
    csrrc s2, satp, t2
    csrrw s1, satp, t3
    // If SATP is accessible chnagae mode to S
    la   a1, change_mode_user
    j    a1



change_mode_user: //chnages mode from S to U

    la      t0, user_mode
    csrw    sepc, t0
    sret 


user_mode:

    li t1, 0x0000ffff
    li t2, 0xffffffff
    li t3, 0x12345678
    csrrs s3, satp, t1
    csrrc s2, satp, t2
    csrrw s1, satp, t3


exit:
    la t0, tohost
    li t1, 1
    sw t1, 0(t0)
    j exit

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;

