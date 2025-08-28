#!/bin/sh
assemble() {
    mkdir -p patch/build
    nasm patch/main.s -f elf64 -o patch/build/main.o
}

link() {
    ld -o patch/build/custom_code.o --oformat elf64-x86-64 patch/build/main.o -T main.ld
}

copy() {
    objcopy patch/build/custom_code.o -O binary patcher/custom_code.bin
    objcopy patch/build/custom_code.o --only-keep-debug patcher/custom_code_symbols.o
}

assemble && link && copy && python3 patcher/main.py "$1"
