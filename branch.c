size_t translateBranch(unsigned char *wasm, const unsigned *riscv, unsigned char opcode) {
    unsigned instr = *riscv;

    instr >>= 7;
    int imm = instr & 0b11111; // [4:1|11]
    instr >>= 8;
    unsigned tmp = imm & 1;
    if (tmp == 1) {
        imm |= 0b100000000000;
    }
    imm &= 0xfffffffe; // [11] [4:0]

    unsigned src = instr & 0b11111;
    instr >>= 5;
    unsigned tar = instr & 0b11111;
    instr >>= 5;

    tmp = instr & 0b111111;
    tmp <<= 5;
    imm |= tmp; // [11:0]
    instr >>= 6;
    tmp = instr & 1;
    bool flag = 1; // forward
    if (tmp == 1) {
        imm |= 0xfffff000;
        flag = 0; // backward
    }

    unsigned char *p = wasm;

    if (flag == 1) { // forward
        //std::cerr << "forward\n";
        *p = 0x02; // block
        p += 1;
        *p = 0x40; // block
        p += 1;
    }

    if (src == 0) {
        // i32.const 0
        *p = 0x0041; // store halfword
        p += 2;
    } else {
        // get_local tmp
        *p = 0x20; // store byte
        p += 1;
        unsigned tmp = regMap[src];
        *p = tmp; // store byte
        p += 1;
    }

    if (tar == 0) {
        // i32.const 0
        *p = 0x41; // store halfword
        p += 1;
        *p = 0x00;
        p += 1;
    } else {
        // get_local tmp
        *p = 0x20; // store byte
        p += 1;
        unsigned tmp = regMap[tar];
        *p = tmp; // store byte
        p += 1;
    }

    // opcode
    *p = opcode; // store byte
    p += 1;

    // br_if 0
    *p = 0x0d; // store halfword
    p += 1;
    *p = 0x00; // store halfword
    p += 1;

    if (flag == 0) { // backward
        *p = 0x0b;
        p += 1;
    }

    return (unsigned)(p - wasm);
}