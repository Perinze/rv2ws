#include <bits/stdc++.h>
#include <fmt/format.h>

std::pair<unsigned, unsigned> encodeLEB128(unsigned x) {

    x &= 0xfff;

    // upper most 6 bits is needed to set MSB
    unsigned upper6 = x >> 6;

    bool high_valid = 1;
    if (upper6 == 0b000000) {
        high_valid = 0;
    }
    if (upper6 == 0b111111) {
        high_valid = 0;
    }

    bool sign = x >> 11;
    unsigned low = x & 0b1111111;
    unsigned high = x >> 7;
    if (sign == 1) {
        high |= 0b1100000;
    }

    unsigned result = 0b0000000; // if high_valid is 0 and is positive
    if (high_valid) { // else
        result = high;
    }

    result <<= 1;
    result |= high_valid;

    result <<= 7;
    result |= low;

    unsigned size = 1;
    if (high_valid) {
        size = 2;
    }

    return std::make_pair(result, size);
}

unsigned short regMap[] = {
    0x00, // zero     -> 0
    0x3f, // invalid
    0x3f, // invalid
    0x3f, // invalid
    0x3f, // invalid
    0x16, // t0  (x5) -> 22 (0x16)
    0x17, // t1  (x6) -> 23 (0x17)
    0x18, // t2  (x7) -> 24 (0x18)
    0x19, // s0  (x8) -> 25 (0x19)
    0x1a, // s1  (x9) -> 26 (0x1a)
    0x00, // a0 (x10) ->  0 (0x00)
    0x01, // a1 (x11) ->  1 (0x01)
    0x02, // a2 (x12) ->  2 (0x02)
    0x03, // a3 (x13) ->  3 (0x03)
    0x04, // a4 (x14) ->  4 (0x04)
    0x05, // a5 (x15) ->  5 (0x05)
    0x06, // a6 (x16) ->  6 (0x06)
    0x07, // a7 (x17) ->  7 (0x07)
    0x08, // s2 (x18) ->  8 (0x08)
    0x09, // s3 (x19) ->  9 (0x09)
    0x0a, // s4 (x20) -> 10 (0x0a)
    0x0b, // s5 (x21) -> 11 (0x0b)
    0x0c, // s6 (x22) -> 12 (0x0c)
    0x0d, // s7 (x23) -> 13 (0x0d)
    0x0e, // s8 (x24) -> 14 (0x0e)
    0x0f, // s9 (x25) -> 15 (0x0f)
    0x10, // s10(x26) -> 16 (0x10)
    0x11, // s11(x27) -> 17 (0x11)
    0x12, // t3 (x28) -> 18 (0x12)
    0x13, // t4 (x29) -> 19 (0x13)
    0x14, // t5 (x30) -> 20 (0x14)
    0x15, // t6 (x31) -> 21 (0x15)
};

// TODO
size_t translateIType(unsigned char *wasm, const unsigned long long *riscv, unsigned char opcode) {
    unsigned long long instr = *riscv;
    instr >>= 7;
    unsigned dst = instr & 0b11111;
    instr >>= 8;
    unsigned src = instr & 0b11111;
    instr >>= 5;
    unsigned imm = instr & 0xfff;
    
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

size_t translateRType(unsigned char *wasm, const unsigned long long *riscv, unsigned char opcode) {
    unsigned instr = *riscv;
    instr >>= 7;
    unsigned dst = instr & 0b11111;
    instr >>= 8;
    unsigned src = instr & 0b11111;
    instr >>= 5;
    unsigned tar = instr & 0b11111;
    
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

    if (tar == 0) {
        // i32.const 0
        *p = 0x0041; // store halfword
        p += 2;
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

    // set_local
    *p = 0x21; // store byte
    p += 1;

    unsigned tmp = regMap[dst];
    *p = tmp; // store byte
    p += 1;

    return (unsigned)(p - wasm);
}

unsigned char forward_count[2000];
unsigned char backward_count[2000];

unsigned readTargetCount(unsigned *riscv, unsigned *addr, bool flag) {
    unsigned char *table = backward_count;
    if (flag != 0) {
        table = forward_count;
    }
    unsigned offset = (unsigned)((unsigned char*)addr - (unsigned char*)riscv);
    offset /= 4;
    return *(table + offset);
}

void incrTargetCount(unsigned *riscv, unsigned *addr, bool flag) {
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
        bool flag = 1; // forward
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

    if (flag == 0) { // forward
        *p = 0x0b;
        p += 1;
    }

    return (unsigned)(p - wasm);
}

unsigned char opcode(unsigned instr) {
    unsigned tmp = instr & 0x707f;
    unsigned flag = instr & 0x40000000;
    switch (tmp) {
        case 0x7013: // andi
        case 0x7033: // and
        return 0x71; // i32.and

        case 0x6013: // ori
        case 0x6033: // or
        return 0x72; // i32.or

        case 0x0013: // addi
        return 0x6a; // i32.add

        case 0x0033:
        if (flag == 0) { // add
            return 0x6a; // i32.add
        } else { // sub
            return 0x6b; // i32.sub
        }

        case 0x5013:
        if (flag == 1) { // srai
            return 0x75; // i32.shr_s
        } else { // srli
            return 0x76; // i32.shr_u
        }
        case 0x1013: // slli
        return 0x74; // i32.shl
        case 0x5033: // srl
        return 0x76; // i32.shr_u
        case 0x1033:
        return 0x74; // i32.shl
        case 0x0063:
        return 0x46; // i32.eq
        case 0x5063:
        return 0x4e; // i32.ge_s
        default:
        return 0xff; // invalid
    }
}

size_t RISCVtoWASM(unsigned *riscv, unsigned char* wasm) {
    unsigned char* wasm_copy = wasm;
    generateTargetTable(riscv);
    for (size_t i = 0; i < 7; i++) {
        std::cerr << fmt::format("forward[{:d}] = {:d}\n", i, readTargetCount((unsigned*)0, (unsigned*)(i * 4), 1));
        std::cerr << fmt::format("backward[{:d}] = {:d}\n", i, readTargetCount((unsigned*)0, (unsigned*)(i * 4), 0));
    }
    unsigned *p = riscv;
    unsigned instr = *p;
    while (instr != 0xffffffff) {
        unsigned char opc = opcode(instr);
        std::cerr << fmt::format("instr[{:d}] = {:#x}\n", (size_t)(p - riscv), instr);
        std::cerr << fmt::format("wasm offset = {:d}\n", (size_t)(wasm - wasm_copy));
        instr >>= 4;
        unsigned type = instr & 0b111;

        unsigned cnt = backward_count[(size_t)(p - riscv)];
        std::cerr << fmt::format("backward[{:d}] = {:d}\n", (size_t)(p - riscv), cnt);
        while (cnt-- > 0) {
            *wasm = 0x03;
            wasm += 1;
            *wasm = 0x40;
            wasm += 1;
        }

        cnt = forward_count[(size_t)(p - riscv)];
        std::cerr << fmt::format("wasm offset = {:d}\n", (size_t)(wasm - wasm_copy));
        std::cerr << fmt::format("forward[{:d}] = {:d}\n", (size_t)(p - riscv), cnt);
        while (cnt-- > 0) {
            *wasm = 0x0b;
            wasm += 1;
        }
        
        switch (type) {
            case 0b001: // itype
            wasm += translateIType(wasm, (unsigned long long*)p, opc);
            break;
            case 0b011: // rtype
            wasm += translateRType(wasm, (unsigned long long*)p, opc);
            break;
            case 0b110: // branch
            wasm += translateBranch(wasm, (unsigned*)p, opc);
            break;
        }

        p += 1;
        instr = *p;
    }
    *wasm = 0x20; // get_local
    wasm += 1;
    *wasm = 0x00; // get_local 0
    wasm += 1;
    *wasm = 0x0f; // return
    wasm += 1;
    *wasm = 0x0b; // end
    wasm += 1;
    return (size_t)(p - riscv);
}


struct testcase {
    unsigned long long input;
    unsigned long long output;
    unsigned size;
    unsigned char opcode;
    testcase(unsigned long long input, unsigned long long output, unsigned size):
        input(input), output(output), size(size) {}
    testcase(unsigned long long input, unsigned long long output, unsigned size, unsigned char opcode):
        input(input), output(output), size(size), opcode(opcode) {}
};

void test_encode_leb128() {
    std::cout << "test encode leb128\n";
    std::vector<testcase> cases {
        testcase(0x0184, 0x0384, 2),
        testcase(0x0fc0, 0x0040, 1),
        testcase(0x0040, 0x00c0, 2),
        testcase(0x07ff, 0x0fff, 2),
        testcase(0x0000, 0x0000, 1),
        testcase(0x0800, 0x7080, 2),
        testcase(0x0fff, 0x007f, 1),
        testcase(0x0001, 0x0001, 1),
    };
    for (testcase c : cases) {
        auto res = encodeLEB128(c.input);
        bool case_name_printed = false;
        if (res.first != c.output) {
            if (!case_name_printed) {
                std::cerr << "in case of input 0x" << std::hex << c.input << std::endl;
                case_name_printed = true;
            }
            std::cerr << "0x" << c.output << " expected, however 0x" << res.first << " get\n";
        }
        if (res.second != c.size) {
            if (!case_name_printed) {
                std::cerr << "in case of input " << std::hex << c.input << std::endl;
                case_name_printed = true;
            }
            std::cerr << std::dec << "size " << c.size << " expected, however " << res.second << " get\n";
        }
    }
}

void test_translate_i_type() {
    std::cout << "test translate i type\n";
    std::vector<testcase> cases {
        testcase(0x00600293, 0x16216a06410041, 7, 0x6a),
        testcase(0x00100313, 0x17216a01410041, 7, 0x6a),
        testcase(0x00150513, 0x00216a01410020, 7, 0x6a),
    };
    for (testcase c : cases) {
        unsigned long long output;
        unsigned size = translateIType((unsigned char*)&output, &c.input, c.opcode);
        if (size != c.size) {
            std::cerr << "size not match\n";
        }
        if (output != c.output) {
            std::cerr << "wasm not match\n";
            std::cerr << "get 0x" << std::hex << output << std::endl;
        }
    }
}

void test_translate_r_type() {
    std::cout << "test translate r type\n";
    std::vector<testcase> cases {
        testcase(0x40550533, 0x00216b16200020, 7, 0x6b),
    };
    for (testcase c : cases) {
        unsigned long long output;
        unsigned size = translateRType((unsigned char*)&output, &c.input, c.opcode);
        if (size != c.size) {
            std::cerr << "size not match\n";
        }
        if (output != c.output) {
            std::cerr << "wasm not match\n";
            std::cerr << "get 0x" << std::hex << output << std::endl;
        }
    }
}

void test_count() {
    std::cout << "test count\n";
    memset(forward_count, 0, sizeof(forward_count));
    memset(backward_count, 0, sizeof(backward_count));
    incrTargetCount((unsigned*)0x0000, (unsigned*)0x0100, 0);
    incrTargetCount((unsigned*)0x0000, (unsigned*)0x0100, 0);
    incrTargetCount((unsigned*)0x0000, (unsigned*)0x0200, 0);
    incrTargetCount((unsigned*)0x0000, (unsigned*)0x0100, 1);
    incrTargetCount((unsigned*)0x0000, (unsigned*)0x0200, 0);
    incrTargetCount((unsigned*)0x0000, (unsigned*)0x0300, 1);
    incrTargetCount((unsigned*)0x0000, (unsigned*)0x0300, 0);
    incrTargetCount((unsigned*)0x0000, (unsigned*)0x1300, 0);
    incrTargetCount((unsigned*)0x0000, (unsigned*)0x0100, 1);

    assert(readTargetCount((unsigned*)0x0000, (unsigned*)0x0100, 0) == 2);
    assert(readTargetCount((unsigned*)0x0000, (unsigned*)0x0100, 1) == 2);
    assert(readTargetCount((unsigned*)0x0000, (unsigned*)0x0200, 0) == 2);
    assert(readTargetCount((unsigned*)0x0000, (unsigned*)0x0200, 1) == 0);
    assert(readTargetCount((unsigned*)0x0000, (unsigned*)0x0300, 0) == 1);
    assert(readTargetCount((unsigned*)0x0000, (unsigned*)0x0300, 1) == 1);
    assert(readTargetCount((unsigned*)0x0000, (unsigned*)0x1300, 0) == 1);
    assert(readTargetCount((unsigned*)0x0000, (unsigned*)0x1300, 1) == 0);
}

unsigned short BackwardBranch[] = {
    0x0293, 0x0060, 0x0533, 0x4055, 
    0x0313, 0x0010, 0x5ce3, 0xfe65, 
    0x0463, 0x0005, 0x0513, 0xfff0, 
    0x0513, 0x0015, 
    0xffff, 0xffff, 
};

void test_table_1() {
    std::cout << "test table 1\n";
    memset(forward_count, 0, sizeof(forward_count));
    memset(backward_count, 0, sizeof(backward_count));
    generateTargetTable((unsigned*)BackwardBranch);
    std::vector<unsigned> forward_count {
        0, 0, 0, 0, 0, 0, 1, 
    };
    std::vector<unsigned> backward_count {
        0, 1, 0, 0, 0, 0, 0, 
    };
    for (size_t i = 0; i < 7; i++) {
        unsigned cnt;
        if ((cnt = readTargetCount((unsigned*)0, (unsigned*)(i * 4), 1)) != forward_count[i]) {
            std::cerr << "forward[" << i << "] is expected to be " << forward_count[i];
            std::cerr << ", but " << cnt << " gotten\n";
        }
        if ((cnt = readTargetCount((unsigned*)0, (unsigned*)(i * 4), 0)) != backward_count[i]) {
            std::cerr << "backward[" << i << "] is expected to be " << backward_count[i];
            std::cerr << ", but " << cnt << " gotten\n";
        }
    }
}

unsigned short BranchToFirstInstruction[] = {
    0x0513, 0xfff5, 0x0293, 0x0070, 
    0x5ce3, 0xfe55, 0x0533, 0x4005, 
    0xffff, 0xffff, 
};

void test_table_2() {
    std::cout << "test table 2\n";
    memset(forward_count, 0, sizeof(forward_count));
    memset(backward_count, 0, sizeof(backward_count));
    generateTargetTable((unsigned*)BranchToFirstInstruction);
    std::vector<unsigned> forward_count {
        0, 0, 0, 0, 
    };
    std::vector<unsigned> backward_count {
        1, 0, 0, 0, 
    };
    for (size_t i = 0; i < 4; i++) {
        unsigned cnt;
        if ((cnt = readTargetCount((unsigned*)0, (unsigned*)(i * 4), 1)) != forward_count[i]) {
            std::cerr << "forward[" << i << "] is expected to be " << forward_count[i];
            std::cerr << ", but " << cnt << " gotten\n";
        }
        if ((cnt = readTargetCount((unsigned*)0, (unsigned*)(i * 4), 0)) != backward_count[i]) {
            std::cerr << "backward[" << i << "] is expected to be " << backward_count[i];
            std::cerr << ", but " << cnt << " gotten\n";
        }
    }
}

void test_translate_branch() {
    std::cout << "test translate branch\n";
    std::vector<testcase> cases {
        testcase(0xfe655ce3, 0x0b000d4e17200020, 8, 0x4e),
        testcase(0x00050463, 0x000d46004100204002, 9, 0x46),
    };
    for (testcase c : cases) {
        unsigned long long output;
        unsigned size = translateBranch((unsigned char*)&output, (unsigned*)&c.input, c.opcode);
        if (size != c.size) {
            std::cerr << "size not match\n";
        }
        if (output != c.output) {
            std::cerr << "wasm not match\n";
            std::cerr << "get 0x" << std::hex << output << std::endl;
        }
    }
}

void test_all() {
    std::cout << "test all\n";
    std::vector<std::string> tests {
        "BackwardBranch",
    };
    for (auto name : tests) {
        memset(forward_count, 0, sizeof(forward_count));
        memset(backward_count, 0, sizeof(backward_count));

        FILE *fbin = fopen(fmt::format("test/{:s}.bin", name).c_str(), "rb");
        FILE *fans = fopen(fmt::format("test/{:s}.wasm", name).c_str(), "rb");

        fseek(fbin, 0L, SEEK_END);
        size_t bin_size = ftell(fbin);
        rewind(fbin);

        fseek(fans, 0L, SEEK_END);
        size_t ans_size = ftell(fans);
        rewind(fans);

        unsigned *bin_buf = (unsigned*)malloc(bin_size + 4);
        bin_buf[bin_size / 4] = 0xffffffff;
        fread(bin_buf, bin_size, 1, fbin);
        for (size_t i = 0; i < bin_size / 4 + 1; i++) {
            std::cerr << fmt::format("{:#08x}\n", bin_buf[i]);
        }
        unsigned char *ans_buf = (unsigned char*)malloc(ans_size);
        fread(ans_buf, ans_size, 1, fans);

        unsigned char *out_buf = (unsigned char*)calloc(1, ans_size + 64);
        RISCVtoWASM(bin_buf, out_buf);

        bool match = true;
        for (size_t i = 0; i < ans_size; i++) {
            if (out_buf[i] != ans_buf[i]) {
                match = false;
            }
        }
        if (!match) {
            std::string log_file = fmt::format("test/{:s}.out", name);
            FILE *fout = fopen(log_file.c_str(), "wb");
            fwrite(out_buf, ans_size, 1, fout);
            fclose(fout);
            std::cerr << fmt::format("not match\noutput saved to {:s}\n", log_file);
        }

        free(bin_buf);
        free(out_buf);
        free(ans_buf);

        fclose(fbin);
        fclose(fans);
    }
}

int main() {
    test_encode_leb128();
    test_translate_i_type();
    test_translate_r_type();
    test_count();
    test_table_1();
    test_table_2();
    test_translate_branch();
    test_all();

    std::cout << "done\n";
    return 0;
}