from io import BufferedRandom

def overwrite_bytes(file: BufferedRandom, virtual_address: int, replacement: bytes):
    # calculate physical address
    if virtual_address < 0x140001000 or virtual_address >= 0x140001000 + 0x85AE00:
        raise Exception(f"Hook to addr {virtual_address:x} is outside of .text section")
    
    physical_address = virtual_address - 0x140001000 + 0x400
    file.seek(physical_address)
    file.write(replacement)

def patch_game(file: BufferedRandom):
    print("Injecting hooks...")
    
    # Hooks
    # SDL2Environment::loadConfig -> load_config_hook
    overwrite_bytes(file, 0x140288a90, bytes([0xe9, 0xAB, 0xE5, 0x82, 0x01]))
    
    # EOLGizmo::update: mov rbx, qword [r15+rcx*8+gooballIds] -> eolgizmo_hook
    overwrite_bytes(file, 0x14009a524, bytes([0xe9, 0xC9, 0xCB, 0xA1, 0x01, 0x90, 0x90, 0x90]))
    
    # BallFactory::load (before loop) -> ballfactory_start_hook
    overwrite_bytes(file, 0x14007c6d1, bytes([0xe9, 0x2C, 0xAA, 0xA3, 0x01, 0x0F, 0x1F, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00]))
    
    # BallFactory::load (during loop) -> ballfactory_loop_hook
    overwrite_bytes(file, 0x14007c742, bytes([0xe9, 0xD2, 0xA9, 0xA3, 0x01, 0x90]))
    
    
    # Direct asm patches
    # BallTemplateInfoUtils::Deserialize: lea rax, [gooBallIds] -> mov rax, [customGooBallIds]
    overwrite_bytes(file, 0x1400818d3, bytes([0x48, 0x8b, 0x05, 0x26, 0x57, 0xa3, 0x01]))
    
    # ItemPipeIn::spawnBall: lea rdx, [gooBallIds] -> mov rdx, [customGooBallIds]
    overwrite_bytes(file, 0x1400faf8b, bytes([0x48, 0x8b, 0x15, 0x6e, 0xc0, 0x9b, 0x01]))
    
    # BallFactory::load: add r14, 0x4cb48 + cmp edi, 0x27 -> 7-byte nop + cmp edi, r14d (unhardcode gooball cap)
    overwrite_bytes(file, 0x14007c767, bytes([0x0F, 0x1F, 0x80, 0x00, 0x00, 0x00, 0x00, 0x44, 0x39, 0xf7]))
