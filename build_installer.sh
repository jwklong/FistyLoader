# Creates PyInstaller executable of installer
# Make sure you have nasm installed

if [ ! -d '.venv' ]; then
    echo Python venv has not been created yet.
    echo Run this first and then try again: python -m venv .venv
    exit 1
fi

if [ -d '.venv/Scripts' ]; then
    source .venv/Scripts/activate
elif [ -d '.venv/bin' ]; then
    source .venv/bin/activate
else
    echo Invalid venv.
    exit 1
fi

pip install -r requirements.txt

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

assemble && link && copy

nasm patch/main.s -o patcher/custom_code.bin
pyinstaller -F patcher/install.py --add-data patcher/custom_code.bin:. --recursive-copy-metadata readchar --clean

echo Done.
