    .data

    .align 2
forwardCount:
    .zero 2000

forwardCount:
    .zero 2000

RISCVtoWASM:

translateIType:

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
    mv      a1, a0

    # unsigned instr = *p;
    lw      a5, 0(a0)

    # while (instr != 0xffffffff) {
    #     unsigned opcode = instr & 0b1111111;
    #     if (opcode != 0b1100011) {
    #         p += 1;
    #         instr = *p;
    #         continue;
    #     }
    #     instr >>= 7;
    #     int imm = instr & 0b11111; // [4:1|11]
    #     unsigned tmp = imm & 1;
    #     if (tmp == 1) {
    #         imm |= 0b100000000000;
    #     }
    #     imm &= 0xfffffffe; // [11] [4:0]
    #     instr >>= 18;
    #     tmp = instr & 0b111111;
    #     tmp <<= 5;
    #     imm |= tmp; // [11:0]
    #     instr >>= 6;
    #     tmp = instr & 1;
    #     unsigned char flag = 1; // forward
    #     if (tmp == 1) {
    #         imm |= 0xfffff000;
    #         flag = 0; // backward
    #     }
    #     imm += (unsigned)p;
    #     incrTargetCount(riscv, (unsigned*)imm, flag);
    #     p += 1; // in asm p += 4 since instruction is 4 bytes
    #     instr = *p;
    # }



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