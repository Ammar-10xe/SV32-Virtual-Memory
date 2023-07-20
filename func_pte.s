func_pte:

    beqz  a3, set_pte_l0

    la    t0, pgtb_l1

    srli  t1, a0, 22
    andi  t1, t1, 0x3FF

    j     setup_pte

set_pte_l0:

    la    t0, pgtb_l0
    srli  t1, a0, 12
    andi  t1, t1, 0x3FF

setup_pte:

    slli t1,  t1, 2
    add  t0,  t0, t1

    srli t2,  a1, 12
    slli t2,  t2, 10
    or   t2,  t2, a2
    # li   t3,  0x8000000f
    # mv   t2,  t3
    sw   t2,  0(t0)
    ret
