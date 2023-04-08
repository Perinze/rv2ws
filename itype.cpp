#include <bits/stdc++.h>

unsigned short regMap[] = {
    0x0041, // zero     -> i32.const 0
    0x3f3f, // invalid
    0x3f3f, // invalid
    0x3f3f, // invalid
    0x3f3f, // invalid
    0x1620, // t0  (x5) -> get_local 22 (0x16)
    0x1720, // t1  (x6) -> get_local 23 (0x17)
    0x1820, // t2  (x7) -> get_local 24 (0x18)
    0x1920, // s0  (x8) -> get_local 25 (0x19)
    0x1a20, // s1  (x9) -> get_local 26 (0x1a)
    0x0020, // a0 (x10) -> get_local  0 (0x00)
    0x0120, // a1 (x11) -> get_local  1 (0x01)
    0x0220, // a2 (x12) -> get_local  2 (0x02)
    0x0320, // a3 (x13) -> get_local  3 (0x03)
    0x0420, // a4 (x14) -> get_local  4 (0x04)
    0x0520, // a5 (x15) -> get_local  5 (0x05)
    0x0620, // a6 (x16) -> get_local  6 (0x06)
    0x0720, // a7 (x17) -> get_local  7 (0x07)
    0x0820, // s2 (x18) -> get_local  8 (0x08)
    0x0920, // s3 (x19) -> get_local  9 (0x09)
    0x0a20, // s4 (x20) -> get_local 10 (0x0a)
    0x0b20, // s5 (x21) -> get_local 11 (0x0b)
    0x0c20, // s6 (x22) -> get_local 12 (0x0c)
    0x0d20, // s7 (x23) -> get_local 13 (0x0d)
    0x0e20, // s8 (x24) -> get_local 14 (0x0e)
    0x0f20, // s9 (x25) -> get_local 15 (0x0f)
    0x1020, // s10(x26) -> get_local 16 (0x10)
    0x1120, // s11(x27) -> get_local 17 (0x11)
    0x1220, // t3 (x28) -> get_local 18 (0x12)
    0x1320, // t4 (x29) -> get_local 19 (0x13)
    0x1420, // t5 (x30) -> get_local 20 (0x14)
    0x1520, // t6 (x31) -> get_local 21 (0x15)
};

size_t translateIType(unsigned char *wasm, const unsigned long long *riscv, unsigned char opcode) {
    unsigned long long instr = *riscv;
    instr >>= 7;
    unsigned dst = instr & 0b11111;
    instr >>= 8;
    unsigned src = instr & 0b11111;
    instr >>= 5;
    unsigned imm = instr & 0xfff;
    
    unsigned char *p = wasm;

    unsigned tmp = regMap[src];
    *p = tmp; // Caution! use store halfword
    p += 2;

    auto res = encodeLEB128(imm);
}