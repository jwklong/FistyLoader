nasm patch/main.s -o patcher/custom_code.bin
python patcher/main.py "$1"
./out.exe
