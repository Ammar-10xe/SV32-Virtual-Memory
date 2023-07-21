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
    
    la   a1, change_mode_supervisor
    jalr a1
    
    j exit

machine_mode:
    # Save machine mode satp
    li t1, 0xdeadbeef
    csrrw s1, satp, t1
    li t2, 0xf0000000
    csrrc s2, satp, t2
    li t3,0x0eefdead
    csrrs s3,satp,t3
    ret

m_trap:
    csrr    t0, mepc
    csrr    t1, mcause
    j       exit


change_mode_supervisor: //chnages mode from M to S

    li      t0, 0x1800
    csrc    mstatus, t0
    li      t1, 0x800
    csrs    mstatus, t1
    la      t2, supervisor_mode
    csrw    mepc,t2 
    mret  
    
supervisor_mode:
    
    
    li t2, 0xdeadbeef
    csrrw s1, satp, t2
    li t3, 0xf0000000
    csrrc s2, satp, t3
    li t4,0x1eefdead
    csrrs s3,satp,t4

    j exit






exit:
    la t0, tohost
    li t1, 1
    sw t1, 0(t0)
    j exit

.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;

