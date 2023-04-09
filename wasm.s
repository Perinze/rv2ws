    .data

    .align 2
forwardCount:
    .zero 2000

forwardCount:
    .zero 2000

RISCVtoWASM:








translateIType:
    # unsigned instr = *riscv;
    # riscv end
    lw      a2, 0(a1)

    # s7 is wasm
    mv      s7, a0

    # instr >>= 7;
    srli    a2, a2, 7

    # unsigned dst = instr & 0b11111;
    andi    a3, a2, 0x1f

    # instr >>= 8;
    srli    a2, 8

    # unsigned src = instr & 0b11111;
    andi    a0, a2, 0x1f

    # instr >>= 5;
    srli    a2, a2, 5

    # unsigned imm = instr & 0xfff;
    # instr end
    andi    a2, a2, 0xfff

    # if (opcode == 0x75) { // i32.shr_s
    li      t0, 0x75
    bne     a4, t0, handle_i32_shr_s_end

    #     imm &= 0b11111;
    andi    a2, a2, 0x1f

    # }
handle_i32_shr_s_end:
    
    ## unsigned char *p = wasm;
    #mv      p, wasm

    # a0 = src, a1 = wasm
    # src end
    mv      a1, s7
    jal		convertReg
    # check a2 still store imm

    # p = wasm + a0
    add     a1, s7, a0

    # *p = 0x41; // store byte
    li      t0, 0x41
    sb      t0, 0(a1)

    # p += 1;
    addi    a1, a1, 1

    # auto res = encodeLEB128(imm);
    # a0 = imm
    # imm end
    # now s0 is p
    mv      s0, a1
    mv      a0, a2
    jal     encodeLEB128

    # *p = a0; // store halfword
    sh      a0, 0(s0)

    # p += a1;
    # p is not a1
    addi    a1, s0, a1

    # *p = opcode; // store byte
    sb      a4, 0(a1)

    # p += 1;
    addi    a1, a1, 1

    # *p = 0x21; // store byte
    li      t0, 0x21
    sb      t0, 0(a1)

    # p += 1;
    addi    a1, a1, 1

    # unsigned tmp = regMap[dst];
    lb      t0, regMap(a3)

    # *p = tmp; // store byte
    sb      t0, 0(a1)

    # p += 1;
    addi    a1, a1, 1

    # return (unsigned)(p - wasm);
    sub     a0, a1, s7
    jalr    zero, ra, 0







translateRType:

translateBranch:








encodeleb128:
    # x &= 0xfff;
    li      t1, 0xfff
    and     t0, a0, t1 # t0 x

    # unsigned upper6 = x >> 6;
    srli    t1, t0, 6   # t1 upper6

    # bool high_valid = 1;
    li      t2, 1   # t2 high_valid

    # if (upper6 == 0b000000) {
    #     high_valid = 0;
    # }
    bne     t1, zero, upper_all_zero_end
    li      t2, 0
upper_all_zero_end:

    # if (upper6 == 0b111111) {
    #     high_valid = 0;
    # }
    li      t3, 0x3f    # tmp 0x3f
    bne     t1, t3, upper_all_one_end
    li      t2, 0
upper_all_one_end:

    # bool sign = x >> 11;
    srli    t3, t0, 11  # t3 sign

    # unsigned low = x & 0b1111111;
    andi    t4, t0, 0x7f    # t4 low

    # unsigned high = x >> 7;
    srli    t5, t0, 7   # t5 high

    # if (sign == 1) {
    #     high |= 0b1100000;
    # }
    li      t6, 1
    bne     t3, t6, extend_uppermost_bit_end
    ori     t5, t5, 0x60
extend_uppermost_bit_end:

    # unsigned result = 0b0000000;
    li      a0, 0

    # if (high_valid) { // else
    #     result = high;
    # }
    beq     t2, zero, add_high_to_result_end
    mv      a0, t5
add_high_to_result_end:

    # result <<= 1;
    slli    a0, a0, 1

    # result |= high_valid;
    or      a0, a0, t2

    # result <<= 7;
    slli    a0, a0, 7

    # result |= low;
    or      a0, a0, t4

    # unsigned size = 1;
    li      a1, 1

    # if (high_valid) {
    #     size = 2;
    # }
    beq     t2, zero, set_size_to_2_end
    li      a1, 2
set_size_to_2_end:

    jalr    zero, ra, 0








generateTargetTable:
    # unsigned *p = riscv;
    mv      a3, a0

    # unsigned instr = *p;
    lw      a5, 0(a3)

    # a4 = 0xffffffff;
    li      a4, -1

    # if (instr == 0xffffffff) return;
    beq     a5, a4, generate_table_return

    # a7 = 0b1100011
    li      a7, 0x63

generate_table_loop:
    #     unsigned opcode = instr & 0b1111111;
    andi    a6, a5, 0x7f

    #     if (opcode != 0b1100011) {
    #         p += 1;
    #         instr = *p;
    #         continue;
    #     }
    bne     a6, a7, incr_instr_ptr

    #     instr >>= 7;
    srli    a5, a5, 7

    #     int imm = instr & 0b11111; // [4:1|11]
    andi    a1, a5, 0x1f

    #     unsigned tmp = imm & 1;
    andi    a7, a1, 1

    #     if (tmp == 1) {
    #         imm |= 0b100000000000;
    #     }
    beq     a7, zero, set_imm_11_done
    ori     a1, a1, 0x800
set_imm_11_done:

    #     imm &= 0xfffffffe; // [11] [4:0]
    andi    a1, a1, 0xfffffffe

    #     instr >>= 18;
    srli    a5, a5, 18

    #     tmp = instr & 0b111111;
    andi    a7, a5, 0x3f

    #     tmp <<= 5;
    slli    a7, a7, 5

    #     imm |= tmp; // [11:0]
    or      a1, a1, a7

    #     instr >>= 6;
    srli    a5, a5, 6

    #     tmp = instr & 1;
    andi    a7, a5, 1

    #     unsigned char flag = 1; // forward
    li      a2, 1

    #     if (tmp == 1) {
    beq     a7, zero, generate_table_set_flag

    #         imm |= 0xfffff000;
    ori     a1, a1, 0xfffff000

    #         flag = 0; // backward
    li      a2, 0

    #     }
generate_table_set_flag:

    #     imm += (unsigned)p;
    add     a1, a1, a3
    
    #     incrTargetCount(riscv, (unsigned*)imm, flag);
    #     a0 = riscv, a1 = imm, a2 = flag
    jal		incrTargetCount
    
incr_instr_ptr:
    #     p += 1; // in asm p += 4 since instruction is 4 bytes
    add     a3, a3, 4

    #     instr = *p;
    lw		a5, 0(a3)

    # while (instr != 0xffffffff);
    bne     a5, a4, generate_table_loop

generate_table_return:
    jalr    zero, ra, 0








readTargetCount:
    # unsigned char *table = backward_count;
    la      a5, backward_count

    # if (flag != 0) {
    #     table = forward_count;
    # }
    beq     a2, zero, flag_is_zero
    la      a5, forward_count
flag_is_zero:

    # unsigned offset = (unsigned)((unsigned char*)addr - (unsigned char*)riscv);
    sub     a1, a1, a0

    # offset /= 4;
    srli    a1, a1, 2

    # return *(table + offset);
    add     a5, a5, a1
    lbu     a0, 0(a5)
    jalr    zero, ra, 0








incrTargetCount:
    # unsigned char *table = backward_count;
    la      a5, backward_count

    # if (flag != 0) {
    #     table = forward_count;
    # }
    beq     a2, zero, flag_is_zero
    la      a5, forward_count
flag_is_zero:

    # unsigned offset = (unsigned)((unsigned char*)addr - (unsigned char*)riscv);
    sub     a1, a1, a0

    # offset /= 4;
    srli    a1, a1, 2

    # unsigned char tmp = *(table + offset);
    add     a5, a5, a1
    lbu     a4, 0(a5)

    # tmp = tmp + 1;
    addi    a4, a4, 1

    # *(table + offset) = tmp;
    sb      a4, 0(a5)

    jalr    zero, ra, 0








convertReg:
    # a0 = src, a1 = p
    # return size

    # if (src == 0) {
    bne     a0, zero, src_is_reg

    #     *p = 0x0041; // store halfword
    li      t0, 0x0041
    sh      t0, 0(a1)

    # return 2
    li      a0, 2
    jalr    zero, ra, 0

    # } else {
src_is_reg:

    #     *p = 0x20; // store byte
    li      t0, 0x20
    sb      t0, 0(a1)

    #     p += 1;
    addi    a1, a1, 1

    #     unsigned tmp = regMap[src];
    lb		t0, regMap(a0)

    #     *p = tmp; // store byte
    sb      t0, 0(a1)

    #     return 2
    li      a0, 2
    jalr    zero, ra, 0
