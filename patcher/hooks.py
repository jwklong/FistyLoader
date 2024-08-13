from io import BufferedRandom
from sys import stderr

def overwrite_bytes(file: BufferedRandom, virtual_address: int, replacement: bytes):
    # calculate physical address
    if virtual_address < 0x140001000 or virtual_address >= 0x140001000 + 0x85AE00:
        raise Exception(f"Hook to addr {virtual_address:x} is outside of .text section")
    
    physical_address = virtual_address - 0x140001000 + 0x400
    file.seek(physical_address)
    file.write(replacement)

def patch_game(file: BufferedRandom):
    print("Injecting hooks...")
    
    # int main() -> call env_init_hook
    overwrite_bytes(file, 0x140224200, bytes([0xe9, 0x13, 0x2E, 0x89, 0x01]))
