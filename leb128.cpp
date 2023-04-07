#include <bits/stdc++.h>

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

struct testcase {
    unsigned riscv;
    unsigned leb128;
    unsigned leb128_size;
    testcase(unsigned riscv, unsigned leb128, unsigned leb128_size):
        riscv(riscv), leb128(leb128), leb128_size(leb128_size) {}
};

int main() {
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
        auto res = encodeLEB128(c.riscv);
        bool case_name_printed = false;
        if (res.first != c.leb128) {
            if (!case_name_printed) {
                std::cerr << "in case of input 0x" << std::hex << c.riscv << std::endl;
                case_name_printed = true;
            }
            std::cerr << "0x" << c.leb128 << " expected, however 0x" << res.first << " get\n";
        }
        if (res.second != c.leb128_size) {
            if (!case_name_printed) {
                std::cerr << "in case of input " << std::hex << c.riscv << std::endl;
                case_name_printed = true;
            }
            std::cerr << std::dec << "size " << c.leb128_size << " expected, however " << res.second << " get\n";
        }
    }
    return 0;
}