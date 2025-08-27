#!/bin/sh
assemble() {
    mkdir -p patch/build
    nasm patch/main.s -f elf64 -o patch/build/custom_code.o
}

link() {
    ld -o patcher/custom_code.bin --oformat binary patch/build/custom_code.o -T main.ld
}

assemble && link && python3 patcher/main.py "$1"
