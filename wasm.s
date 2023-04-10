    .include "common.s"
    .data

    .align 2
forwardCount:
    .space 2000

backwardCount:
    .space 2000

regMap:
    .byte 0x00, 0x3f, 0x3f, 0x3f, 0x3f, 0x16, 0x17, 0x18, 
    .byte 0x19, 0x1a, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 
    .byte 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 
    .byte 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 

    .text
opcode:
    li          t3, 0x707f
    and 	t0, a0, t3
    
    li          t3, 0x40000000
    and         t1, a0, t3

    li      t2, 0x7013
    beq     t2, t0, opcode_and
    li      t2, 0x7033
    beq     t2, t0, opcode_and
    li      t2, 0x6013
    beq     t2, t0, opcode_or
    li      t2, 0x6033
    beq     t2, t0, opcode_or
    li      t2, 0x0013
    beq     t2, t0, opcode_addi
    li      t2, 0x0033
    beq     t2, t0, opcode_add_or_sub
    li      t2, 0x5013
    beq     t2, t0, opcode_srai_or_srli
    li      t2, 0x1013
    beq     t2, t0, opcode_slli
    li      t2, 0x5033
    beq     t2, t0, opcode_srl
    li      t2, 0x1033
    beq     t2, t0, opcode_sll
    li      t2, 0x0063
    beq     t2, t0, opcode_beq
    li      t2, 0x5063
    beq     t2, t0, opcode_bge
    j       opcode_default

opcode_and:
    li      a0, 0x71
    jalr    zero, ra, 0

opcode_or:
    li      a0, 0x71
    jalr    zero, ra, 0

opcode_addi:
    li      a0, 0x6a
    jalr    zero, ra, 0

opcode_add_or_sub:
    bne     t1, zero, opcode_sub

    li      a0, 0x6a
    jalr    zero, ra, 0

opcode_sub:

    li      a0, 0x6b
    jalr    zero, ra, 0

opcode_srai_or_srli:
    beq     t1, zero, opcode_srli

    li      a0, 0x75
    jalr    zero, ra, 0

opcode_srli:

    li      a0, 0x76
    jalr    zero, ra, 0

opcode_slli:
    li      a0, 0x74
    jalr    zero, ra, 0

opcode_srl:
    li      a0, 0x76
    jalr    zero, ra, 0

opcode_sll:
    li      a0, 0x74
    jalr    zero, ra, 0

opcode_beq:
    li      a0, 0x46
    jalr    zero, ra, 0

opcode_bge:
    li      a0, 0x4e
    jalr    zero, ra, 0

opcode_default:
    li      a0, 0xff
    jalr    zero, ra, 0








RISCVtoWASM:
    mv      s4, a0
    mv      s5, a1

    mv      s6, a0

    jal     generateTargetTable

    mv      a4, s5

    lw      a3, 0(s4)

    li      t0, 0xffffffff
    beq     a3, t0, main_loop_end

main_loop:

    mv      a0, a3
    jal     opcode
    mv      a2, a0
    
    srli    a3, a3, 4

    andi    a5, a3, 0x7

    sub     t0, s4, s6
    srli    t0, t0, 2
    lb      t0, %lo(forwardCount)(t0)

    j       loop_forward_check
loop_forward_begin:
    li      t1, 0x0b
    sb      t1, 0(a4)

    addi    a4, a4, 1
    addi	t0, t0, -1
    
loop_forward_check:
    bgt		t0, zero, loop_forward_begin
    
loop_forward_end:

    sub     t0, s4, s6
    srli    t0, t0, 2
    lb      t0, %lo(backwardCount)(t0)

    j		loop_backward_check
loop_backward_begin:
    li      t1, 0x4003
    sh      t1, 0(a4)

    addi    a0, a4, 2

    addi    t0, t0, -1

loop_backward_check:
    bgt     t0, zero, loop_backward_begin

    mv      a1, s4
    mv      s9, a0

    li      t0, 0x1
    beq     a5, t0, switch_i_type
    li      t0, 0x3
    beq     a5, t0, switch_r_type
    li      t0, 0x6
    beq     a5, t0, switch_branch
    j       switch_end

switch_i_type:

    jal     translateIType
    j       switch_end

switch_r_type:

    jal     translateRType
    j       switch_end

switch_branch:

    jal     translateBranch
switch_end:

    add     a0, a0, s9

    addi    s4, s4, 4

    lw      a3, 0(s4)

    li      t0, 0xffffffff
    bne     a3, t0, main_loop

main_loop_end:

    li      t0, 0x0b0f0020
    sw		t0, 0(a0)
    
    addi    a0, a0, 4

    sub     a0, a0, s5
    jalr    zero, ra, 0








translateIType:
    mv      a4, a2

    lw      a2, 0(a1)

    mv      s7, a0

    srli    a2, a2, 7

    andi    a3, a2, 0x1f

    srli    a2, a2, 8

    andi    a0, a2, 0x1f

    srli    a2, a2, 5

    li      t0, 0xfff
    and     a2, a2, t0

    li      t0, 0x75
    bne     a4, t0, handle_i32_shr_s_end

    andi    a2, a2, 0x1f

handle_i32_shr_s_end:
    

    mv      a1, s7
    jal		convertReg

    add     a1, s7, a0

    li      t0, 0x41
    sb      t0, 0(a1)

    addi    a1, a1, 1

    mv      s0, a1
    mv      a0, a2
    jal     encodeLEB128

    sh      a0, 0(s0)

    add     a1, s0, a1

    sb      a4, 0(a1)

    addi    a1, a1, 1

    li      t0, 0x21
    sb      t0, 0(a1)

    addi    a1, a1, 1

    lb      t0, %lo(regMap)(a3)

    sb      t0, 0(a1)

    addi    a1, a1, 1

    sub     a0, a1, s7
    jalr    zero, ra, 0







translateRType:
    mv      a4, a2

    lw      a2, 0(a1)

    mv      s7, a0

    srli    a2, a2, 7

    andi    a3, a2, 0x1f

    srli    a2, a2, 8

    andi    a0, a2, 0x1f

    srli    a2, a2, 5

    andi    a5, a2, 0x1f
    

    mv      a1, s7
    jal     convertReg

    add     a6, s7, a0
    mv      a1, a6

    mv      a0, a5
    jal     convertReg

    add     a1, a6, a0

    sb      a4, 0(a1)

    addi    a1, a1, 1

    li      t0, 0x21
    sb      t0, 0(a1)

    addi    a1, a1, 1

    lb      t0, %lo(regMap)(a3)

    sb      t0, 0(a1)

    addi    a1, a1, 1

    sub     a0, a1, s7
    jalr    zero, ra, 0







translateBranch:
    mv      a4, a2

    lw      a2, 0(a1)

    mv      s7, a0

    srli    a2, a2, 7

    andi    a3, a2, 0x1f

    srli    a2, a2, 8

    andi    t0, a3, 1

    beq     t0, zero, branch_set_imm_11_done

    li      t0, 0x800
    or      a3, a3, t0

branch_set_imm_11_done:
    andi    a3, a3, 0xfffffffe

    andi    a0, a2, 0x1f

    srli    a2, a2, 5

    andi    a5, a2, 0x1f

    srli    a2, a2, 5

    andi    t0, a2, 0x3f

    slli    t0, t0, 5

    or      a3, a3, t0

    srli    a2, a2, 6

    andi    t0, a2, 1

    li      s8, 1

    beq     t0, zero, extend_imm_done

    li      t0, 0xfffff000
    or      a3, a3, t0

    li      s8, 0

extend_imm_done:

    mv      a1, s7

    beq     t1, zero, branch_forward_end

    li      t0, 0x02
    sb      t0, 0(a1)

    addi    a1, a1, 1

    li      t0, 0x40
    sb      t0, 0(a1)

    addi    a1, a1, 1

branch_forward_end:

    mv      a6, a1

    jal     convertReg

    add     a1, a6, a0

    mv      a6, a1

    mv      a0, a5
    jal     convertReg

    add     a1, a6, a0

    sb      a4, 0(a1)

    addi    a1, a1, 1

    li      t0, 0x0d
    sb      t0, 0(a1)

    addi    a1, a1, 1

    sb      zero, 0(a1)

    addi    a1, a1, 1

    bne     s8, zero, branch_backward_end

    li      t0, 0x0b
    sb      t0, 0(a1)

    addi    a1, a1, 1

branch_backward_end:

    sub     a0, a1, s7
    jalr    zero, ra, 0








encodeLEB128:
    li      t1, 0xfff



    bne     t1, zero, upper_all_zero_end
    li      t2, 0
upper_all_zero_end:

    bne     t1, t3, upper_all_one_end
    li      t2, 0
upper_all_one_end:




    li      t6, 1
    bne     t3, t6, extend_uppermost_bit_end
    ori     t5, t5, 0x60
extend_uppermost_bit_end:

    li      a0, 0

    beq     t2, zero, add_high_to_result_end
    mv      a0, t5
add_high_to_result_end:

    slli    a0, a0, 1

    or      a0, a0, t2

    slli    a0, a0, 7

    or      a0, a0, t4

    li      a1, 1

    beq     t2, zero, set_size_to_2_end
    li      a1, 2
set_size_to_2_end:

    jalr    zero, ra, 0








generateTargetTable:
    mv      a3, a0

    lw      a5, 0(a3)

    li      a4, -1

    beq     a5, a4, generate_table_return

    li      a7, 0x63

generate_table_loop:
    andi    a6, a5, 0x7f

    bne     a6, a7, incr_instr_ptr

    srli    a5, a5, 7

    andi    a1, a5, 0x1f

    andi    a7, a1, 1

    beq     a7, zero, set_imm_11_done
    
    li      t0, 0x800
    or      a1, a1, t0
set_imm_11_done:

    andi    a1, a1, 0xfffffffe

    srli    a5, a5, 18

    andi    a7, a5, 0x3f

    slli    a7, a7, 5

    or      a1, a1, a7

    srli    a5, a5, 6

    andi    a7, a5, 1

    li      a2, 1

    beq     a7, zero, generate_table_set_flag

    li      t0, 0xfffff000
    or      a1, a1, t0

    li      a2, 0

generate_table_set_flag:

    add     a1, a1, a3
    
    jal		incrTargetCount
    
incr_instr_ptr:
    addi    a3, a3, 4

    lw		a5, 0(a3)

    bne     a5, a4, generate_table_loop

generate_table_return:
    jalr    zero, ra, 0








readTargetCount:
    la      a5, backwardCount

    beq     a2, zero, flag_is_zero_read
    la      a5, forwardCount
flag_is_zero_read:

    sub     a1, a1, a0

    srli    a1, a1, 2

    add     a5, a5, a1
    lbu     a0, 0(a5)
    jalr    zero, ra, 0








incrTargetCount:
    la      a5, backwardCount

    beq     a2, zero, flag_is_zero_incr
    la      a5, forwardCount
flag_is_zero_incr:

    sub     a1, a1, a0

    srli    a1, a1, 2

    add     a5, a5, a1
    lbu     a4, 0(a5)

    addi    a4, a4, 1

    sb      a4, 0(a5)

    jalr    zero, ra, 0








convertReg:

    bne     a0, zero, src_is_reg

    li      t0, 0x0041
    sh      t0, 0(a1)

    li      a0, 2
    jalr    zero, ra, 0

src_is_reg:

    li      t0, 0x20
    sb      t0, 0(a1)

    addi    a1, a1, 1

    lb		t0, %lo(regMap)(a0)

    sb      t0, 0(a1)

    li      a0, 2
    jalr    zero, ra, 0
