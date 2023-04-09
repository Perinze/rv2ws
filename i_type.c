size_t translateIType(unsigned char *wasm, const unsigned long long *riscv, unsigned char opcode) {
    unsigned long long instr = *riscv;
    instr >>= 7;
    unsigned dst = instr & 0b11111;
    instr >>= 8;
    unsigned src = instr & 0b11111;
    instr >>= 5;
    unsigned imm = instr & 0xfff;
    if (opcode == 0x75) { // i32.shr_s
        imm &= 0b11111;
    }
    
    unsigned char *p = wasm;

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

    // get_local
    *p = 0x41; // store byte
    p += 1;
    // leb128
    auto res = encodeLEB128(imm);
    *p = res.first; // store halfword
    p += res.second;

    // opcode
    *p = opcode; // store byte
    p += 1;

    // set_local
    *p = 0x21; // store byte
    p += 1;

    unsigned tmp = regMap[dst];
    *p = tmp; // store byte
    p += 1;

    return (unsigned)(p - wasm);
}