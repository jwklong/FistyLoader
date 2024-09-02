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

nasm patch/main.s -o patcher/custom_code.bin
pyinstaller -F patcher/install.py --add-data patcher/custom_code.bin:. --recursive-copy-metadata readchar --clean

echo Done.
