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
    
    # SDL2Environment::loadConfig -> load_config_hook
    overwrite_bytes(file, 0x140288a90, bytes([0xe9, 0xAB, 0xE5, 0x82, 0x01]))
