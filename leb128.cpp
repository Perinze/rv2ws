#include <bits/stdc++.h>

std::pair<unsigned, unsigned> encodeLEB128(unsigned x) {

    unsigned high = x >> 7;
    high &= 0b11111;

    unsigned low = x;
    low &= 0b1111111;

    // high_valid indicate high is neither 0b00000 nor 0b11111
    bool high_valid = 1;

    if (high == 0b00000) {
        high_valid = 0;
    }
    if (high == 0b11111) {
        high_valid = 0;
    }

    unsigned result = 0b00000; // if high_valid is 0
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

int main() {

}