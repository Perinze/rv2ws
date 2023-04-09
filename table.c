unsigned char forward_count[2000];
unsigned char backward_count[2000];

unsigned readTargetCount(unsigned *riscv, unsigned *addr, unsigned char flag) {
    unsigned char *table = backward_count;
    if (flag != 0) {
        table = forward_count;
    }
    unsigned offset = (unsigned)((unsigned char*)addr - (unsigned char*)riscv);
    offset /= 4;
    return *(table + offset);
}

void incrTargetCount(unsigned *riscv, unsigned *addr, unsigned char flag) {
    unsigned char *table = backward_count;
    if (flag != 0) {
        table = forward_count;
    }
    unsigned offset = (unsigned)((unsigned char*)addr - (unsigned char*)riscv);
    offset /= 4;
    unsigned char tmp = *(table + offset);
    tmp = tmp + 1;
    *(table + offset) = tmp;
}

void generateTargetTable(unsigned *riscv) {
    //std::cerr << fmt::format("riscv {:#x}\n", (unsigned)riscv);
    unsigned *p = riscv;
    unsigned instr = *p;
    while (instr != 0xffffffff) {
        unsigned opcode = instr & 0b1111111;
        if (opcode != 0b1100011) {
            p += 1;
            instr = *p;
            continue;
        }
        //std::cerr << fmt::format("instr {:#08x}\n", instr);
        //std::cerr << fmt::format("opcode {:#07b}\n", opcode);
        instr >>= 7;
        int imm = instr & 0b11111; // [4:1|11]
        //std::cerr << fmt::format("imm[4:1|11] {:#b}\n", imm);
        unsigned tmp = imm & 1;
        if (tmp == 1) {
            imm |= 0b100000000000;
        }
        imm &= 0xfffffffe; // [11] [4:0]
        //std::cerr << fmt::format("imm[11][4:0] {:#b}\n", imm);
        instr >>= 18;
        tmp = instr & 0b111111;
        //std::cerr << fmt::format("tmp {:#b}\n", imm);
        tmp <<= 5;
        imm |= tmp; // [11:0]
        //std::cerr << fmt::format("imm[11:0] {:#b}\n", imm);
        instr >>= 6;
        tmp = instr & 1;
        unsigned char flag = 1; // forward
        if (tmp == 1) {
            imm |= 0xfffff000;
            flag = 0; // backward
        }
        //std::cerr << fmt::format("imm[31:0] {:#b}\n", imm);
        //std::cerr << fmt::format("imm {:d}\n", imm);
        imm += (unsigned)p;
        //std::cerr << fmt::format("pc {:#x}\n", (unsigned)imm);
        incrTargetCount(riscv, (unsigned*)imm, flag);
        p += 1; // in asm p += 4 since instruction is 4 bytes
        instr = *p;
    }
}