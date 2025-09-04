#!/bin/sh
assemble() {
    mkdir -p patch/build
    nasm patch/main.s -f elf64 -o patch/build/main.o
}

compile() {
    gcc -c -I include -mabi=ms -O2 -fno-stack-protector -o patch/build/ballTable.o patch/src/ballTable.cpp
}

link() {
    ld -o patch/build/custom_code.o --oformat elf64-x86-64 -T main.ld patch/build/main.o patch/build/ballTable.o
}

copy() {
    objcopy patch/build/custom_code.o -O binary patcher/custom_code.bin
    objcopy patch/build/custom_code.o --only-keep-debug patcher/custom_code_symbols.o
}

assemble && compile && link && copy && python3 patcher/main.py "$1"
