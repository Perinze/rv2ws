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
# unsigned char opcode(unsigned instr) {
    # unsigned tmp = instr & 0x707f;
    li      t0, 0x707f
    and 	t0, a0, t0
    
    # unsigned flag = instr & 0x40000000;
    li      t1, 0x40000000
    and     t1, a0, t1

    # switch (tmp) {
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
    #     case 0x7013: // andi
    #     case 0x7033: // and
    #     return 0x71; // i32.and
    li      a0, 0x71
    jalr    zero, ra, 0

opcode_or:
    #     case 0x6013: // ori
    #     case 0x6033: // or
    #     return 0x72; // i32.or
    li      a0, 0x71
    jalr    zero, ra, 0

opcode_addi:
    #     case 0x0013: // addi
    #     return 0x6a; // i32.add
    li      a0, 0x6a
    jalr    zero, ra, 0

opcode_add_or_sub:
    #     case 0x0033:
    #     if (flag == 0) { // add
    bne     t1, zero, opcode_sub

    #         return 0x6a; // i32.add
    li      a0, 0x6a
    jalr    zero, ra, 0

    #     } else { // sub
opcode_sub:

    #         return 0x6b; // i32.sub
    li      a0, 0x6b
    jalr    zero, ra, 0

opcode_srai_or_srli:
    #     case 0x5013:
    #     if (flag == 1) { // srai
    beq     t1, zero, opcode_srli

    #         return 0x75; // i32.shr_s
    li      a0, 0x75
    jalr    zero, ra, 0

    #     } else { // srli
opcode_srli:

    #         return 0x76; // i32.shr_u
    li      a0, 0x76
    jalr    zero, ra, 0

opcode_slli:
    #     case 0x1013: // slli
    #     return 0x74; // i32.shl
    li      a0, 0x74
    jalr    zero, ra, 0

opcode_srl:
    #     case 0x5033: // srl
    #     return 0x76; // i32.shr_u
    li      a0, 0x76
    jalr    zero, ra, 0

opcode_sll:
    #     case 0x1033:
    #     return 0x74; // i32.shl
    li      a0, 0x74
    jalr    zero, ra, 0

opcode_beq:
    #     case 0x0063:
    #     return 0x46; // i32.eq
    li      a0, 0x46
    jalr    zero, ra, 0

opcode_bge:
    #     case 0x5063:
    #     return 0x4e; // i32.ge_s
    li      a0, 0x4e
    jalr    zero, ra, 0

opcode_default:
    #     default:
    #     return 0xff; // invalid
    li      a0, 0xff
    jalr    zero, ra, 0








RISCVtoWASM:
# size_t RISCVtoWASM(unsigned *riscv, unsigned char* wasm) {
    # riscv = a0, wasm = a1
    mv      s4, a0
    mv      s5, a1
    # riscv = s4, wasm = s5

    # unsigned *riscv_copy = riscv;
    mv      s6, a0

    # generateTargetTable(riscv);
    jal     generateTargetTable

    # unsigned char *p = wasm;
    mv      a4, s5

    # unsigned instr = *riscv;
    lw      a3, 0(s4)

    # if (instr == 0xffffffff) goto main_loop_end
    li      t0, 0xffffffff
    beq     a3, t0, main_loop_end

main_loop:

    #     unsigned char opc = opcode(instr);
    # instr = a0 -> opc = a0
    mv      a0, a3
    jal     opcode
    mv      a2, a0
    # opc = a2
    
    #     instr >>= 4;
    srli    a3, a3, 4

    #     unsigned type = instr & 0b111;
    andi    a5, a3, 0x7

    #     unsigned cnt = forwardCount[(size_t)(riscv - riscv_copy)];
    sub     t0, s4, s6
    srli    t0, t0, 2
    lb      t0, %lo(forwardCount)(t0)

    j       loop_forward_check
loop_forward_begin:
    #         *p = 0x0b;
    li      t1, 0x0b
    sb      t1, 0(a4)

    #         p += 1;
    addi    a4, a4, 1

    #         cnt--;
    addi	t0, t0, -1
    
loop_forward_check:
    #     while (cnt > 0) {
    bgt		t0, zero, loop_forward_begin
    
loop_forward_end:

    #     cnt = backwardCount[(size_t)(riscv - riscv_copy)];
    sub     t0, s4, s6
    srli    t0, t0, 2
    lb      t0, %lo(backwardCount)(t0)

    j		loop_backward_check
loop_backward_begin:
    #         *p = 0x4003;
    li      t1, 0x4003
    sh      t1, 0(a4)

    #         p += 2;
    addi    a0, a4, 2
    # p is not a0

    #         cnt--;
    addi    t0, t0, -1

loop_backward_check:
    #     while (cnt > 0);
    bgt     t0, zero, loop_backward_begin

    # p = a0, riscv = a1, opc = a2
    mv      a1, s4
    # old_p = s9
    mv      s9, a0

    #     switch (type) { // a5
    li      t0, 0x1
    beq     a5, t0, switch_i_type
    li      t0, 0x3
    beq     a5, t0, switch_r_type
    li      t0, 0x6
    beq     a5, t0, switch_branch
    j       switch_end

    #         case 0b001: // itype
switch_i_type:

    #         p += translateIType(p, riscv, opc);
    jal     translateIType
    j       switch_end

    #         case 0b011: // rtype
switch_r_type:

    #         p += translateRType(p, (unsigned long long*)riscv, opc);
    jal     translateRType
    j       switch_end

    #         case 0b110: // branch
switch_branch:

    #         p += translateBranch(p, (unsigned*)riscv, opc);
    jal     translateBranch
switch_end:

    add     a0, a0, s9

    #     riscv += 1; // 4 per instr
    addi    s4, s4, 4

    #     instr = *riscv;
    lw      a3, 0(s4)

    # while (instr != 0xffffffff);
    li      t0, 0xffffffff
    bne     a3, t0, main_loop

main_loop_end:

    # *p = 0x0b0f0020; // get_local
    li      t0, 0x0b0f0020
    sw		t0, 0(a0)
    
    # p += 4;
    addi    a0, a0, 4

    # return (size_t)(p - wasm);
    sub     a0, a0, s5
    jalr    zero, ra, 0








translateIType:
    # a4 = opcode(a2)
    mv      a4, a2

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
    srli    a2, a2, 8

    # unsigned src = instr & 0b11111;
    andi    a0, a2, 0x1f

    # instr >>= 5;
    srli    a2, a2, 5

    # unsigned imm = instr & 0xfff;
    # instr end
    li      t0, 0xfff
    and     a2, a2, t0

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
    add     a1, s0, a1

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
    lb      t0, %lo(regMap)(a3)

    # *p = tmp; // store byte
    sb      t0, 0(a1)

    # p += 1;
    addi    a1, a1, 1

    # return (unsigned)(p - wasm);
    sub     a0, a1, s7
    jalr    zero, ra, 0







# size_t translateRType(unsigned char *wasm, const unsigned long long *riscv, unsigned char opcode) {
translateRType:
    # a4 = opcode(a2)
    mv      a4, a2

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
    srli    a2, a2, 8

    # unsigned src = instr & 0b11111;
    andi    a0, a2, 0x1f

    # instr >>= 5;
    srli    a2, a2, 5

    # unsigned tar = instr & 0b11111;
    andi    a5, a2, 0x1f
    
    # unsigned char *p = wasm;

    # a0 = src, a1 = wasm
    # src end
    mv      a1, s7
    jal     convertReg

    # p = wasm + a0
    add     a6, s7, a0
    mv      a1, a6

    # a0 = tar, a1 = p
    # tar end
    mv      a0, a5
    jal     convertReg

    # p = old_p + a0
    # old_p a6 end
    add     a1, a6, a0

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
    lb      t0, %lo(regMap)(a3)

    # *p = tmp; // store byte
    sb      t0, 0(a1)

    # p += 1;
    addi    a1, a1, 1

    # return (unsigned)(p - wasm);
    sub     a0, a1, s7
    jalr    zero, ra, 0







translateBranch:
# size_t translateBranch(unsigned char *wasm, const unsigned *riscv, unsigned char opcode) {
    # a4 = opcode(a2)
    mv      a4, a2

    # unsigned instr = *riscv;
    # riscv end
    lw      a2, 0(a1)

    # s7 is wasm
    mv      s7, a0

    # instr >>= 7;
    srli    a2, a2, 7

    # int imm = instr & 0b11111; // [4:1|11]
    andi    a3, a2, 0x1f

    # instr >>= 8;
    srli    a2, a2, 8

    # unsigned tmp = imm & 1;
    andi    t0, a3, 1

    # if (tmp == 1) {
    beq     t0, zero, branch_set_imm_11_done

    #     imm |= 0b100000000000;
    li      t0, 0x800
    or      a3, a3, t0

branch_set_imm_11_done:
    # imm &= 0xfffffffe; // [11] [4:0]
    andi    a3, a3, 0xfffffffe

    # unsigned src = instr & 0b11111;
    andi    a0, a2, 0x1f

    # instr >>= 5;
    srli    a2, a2, 5

    # unsigned tar = instr & 0b11111;
    andi    a5, a2, 0x1f

    # instr >>= 5;
    srli    a2, a2, 5

    # tmp = instr & 0b111111;
    andi    t0, a2, 0x3f

    # tmp <<= 5;
    slli    t0, t0, 5

    # imm |= tmp; // [11:0]
    or      a3, a3, t0

    # instr >>= 6;
    srli    a2, a2, 6

    # tmp = instr & 1;
    andi    t0, a2, 1

    # bool flag = 1; // forward
    li      s8, 1

    # if (tmp == 1) {
    beq     t0, zero, extend_imm_done

    #     imm |= 0xfffff000;
    li      t0, 0xfffff000
    or      a3, a3, t0

    #     flag = 0; // backward
    li      s8, 0

extend_imm_done:

    # unsigned char *p = wasm;
    mv      a1, s7

    # if (flag == 1) { // forward
    beq     t1, zero, branch_forward_end

    #     *p = 0x02; // block
    li      t0, 0x02
    sb      t0, 0(a1)

    #     p += 1;
    addi    a1, a1, 1

    #     *p = 0x40; // block
    li      t0, 0x40
    sb      t0, 0(a1)

    #     p += 1;
    addi    a1, a1, 1

branch_forward_end:

    # old_p = p
    mv      a6, a1

    # a0 = src, a1 = p
    # src end
    jal     convertReg

    # p = old_p + a0
    # old_p a6 end
    add     a1, a6, a0

    # old_p = p
    mv      a6, a1

    # a0 = tar, a1 = p
    # tar end
    mv      a0, a5
    jal     convertReg

    # p = old_p + a0
    # old_p a6 end
    add     a1, a6, a0

    # *p = opcode; // store byte
    sb      a4, 0(a1)

    # p += 1;
    addi    a1, a1, 1

    # *p = 0x0d; // store halfword
    li      t0, 0x0d
    sb      t0, 0(a1)

    # p += 1;
    addi    a1, a1, 1

    # *p = 0x00; // store halfword
    sb      zero, 0(a1)

    # p += 1;
    addi    a1, a1, 1

    # if (flag == 0) { // backward
    bne     s8, zero, branch_backward_end

    #     *p = 0x0b;
    li      t0, 0x0b
    sb      t0, 0(a1)

    #     p += 1;
    addi    a1, a1, 1

branch_backward_end:

    # return (unsigned)(p - wasm);
    sub     a0, a1, s7
    jalr    zero, ra, 0








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








generateTargetTable:
    mv      s10, a0
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
    li      a7, 0x800
    or      a1, a1, a7
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
    li      a7, 0xfffff000
    or      a1, a1, a7

    #         flag = 0; // backward
    li      a2, 0

    #     }
generate_table_set_flag:

    #     imm += (unsigned)p;
    add     a1, a1, a3
    
    mv      a0, s10
    #     incrTargetCount(riscv, (unsigned*)imm, flag);
    #     a0 = p, a1 = imm, a2 = flag
    jal		incrTargetCount
    
incr_instr_ptr:
    #     p += 1; // in asm p += 4 since instruction is 4 bytes
    addi    a3, a3, 4

    #     instr = *p;
    lw		a5, 0(a3)
    li      t1, 0xffff
    and     t1, t1, a5

    # while (instr != 0xffffffff);
    li      t0, 0xffff
    bne     t1, t0, generate_table_loop

generate_table_return:
    jalr    zero, ra, 0








readTargetCount:
    # unsigned char *table = backwardCount;
    la      a5, backwardCount

    # if (flag != 0) {
    #     table = forwardCount;
    # }
    beq     a2, zero, flag_is_zero
    la      a5, forwardCount
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
    # unsigned char *table = backwardCount;
    la      a5, backwardCount

    # if (flag != 0) {
    #     table = forwardCount;
    # }
    beq     a2, zero, flag_is_zero_incr
    la      a5, forwardCount
flag_is_zero_incr:

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
    lb		t0, %lo(regMap)(a0)

    #     *p = tmp; // store byte
    sb      t0, 0(a1)

    #     return 2
    li      a0, 2
    jalr    zero, ra, 0
