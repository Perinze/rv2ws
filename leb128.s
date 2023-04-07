.text
main:
    li      a0, 0x0001
    jal     ra, encodeLEB128
    li      a7, 10
    ecall

encodeLEB128:
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
