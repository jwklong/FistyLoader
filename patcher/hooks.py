from io import BufferedRandom

# from https://stackoverflow.com/a/36361832/10079808
NOP_SEQUENCES = [
    None, # 0-byte nop doesn't exist
	bytes([0x90]), # 1-byte nop
	bytes([0x66, 0x90]), # 2-byte nop
	bytes([0x0F, 0x1F, 0x00]), # 3-byte nop
	bytes([0x0F, 0x1F, 0x40, 0x00]), # 4-byte nop
	bytes([0x0F, 0x1F, 0x44, 0x00, 0x00]), # 5-byte nop
	bytes([0x66, 0x0F, 0x1F, 0x44, 0x00, 0x00]), # 6-byte nop
	bytes([0x0F, 0x1F, 0x80, 0x00, 0x00, 0x00, 0x00]), # 7-byte nop
	bytes([0x0F, 0x1F, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00]), # 8-byte nop
	bytes([0x66, 0x0F, 0x1F, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00]), # 9-byte nop
]

def overwrite_bytes(file: BufferedRandom, virtual_address: int, replacement: bytes):
    # calculate physical address
    if virtual_address < 0x140001000 or virtual_address >= 0x140001000 + 0x85AE00:
        raise Exception(f"Hook to addr {virtual_address:x} is outside of .text section")
    
    physical_address = virtual_address - 0x140001000 + 0x400
    file.seek(physical_address)
    file.write(replacement)

def hook_addr(file: BufferedRandom, virtual_address: int, target_address: int, *, padding: int = 0):
    relative_target_addr = target_address - (virtual_address + 5)
    buf = bytes([0xe9, *relative_target_addr.to_bytes(4, 'little')])
    
    if padding > 0:
        assert padding < len(NOP_SEQUENCES), f"Cannot add padding longer than {len(NOP_SEQUENCES) - 1}"
        buf += NOP_SEQUENCES[padding]
    
    overwrite_bytes(file, virtual_address, buf)

def inject_hooks(file: BufferedRandom):
    print("Injecting hooks...")
    
    # Hooks
    # SDL2Environment::loadConfig -> load_config_hook
    hook_addr(file, 0x140411730, 0x1421C9040)
    
    # EOLGizmo::update: mov rbx, qword [r15+rcx*8+gooballIds] -> eolgizmo_hook
    hook_addr(file, 0x140222fa4, 0x1421C90F2, padding=3)
    
    # BallFactory::load (before loop) -> ballfactory_start_hook
    hook_addr(file, 0x1402056a2, 0x1421C9102, padding=8)
    
    # BallFactory::load (during loop) -> ballfactory_loop_hook
    hook_addr(file, 0x140205713, 0x1421C9119, padding=1)
    
    # BallFactory::init: mov ecx, 0xbaf810 -> ballfactory_init_hook
    hook_addr(file, 0x140205614, 0x1421C912F)
    
    # BallFactory::BallFactory: mov r8d, 0x27 -> ballfactory_constructor_hook1
    hook_addr(file, 0x140204f7b, 0x1421C9147, padding=1)
    
    # BallFactory::BallFactory: mov dword [rdi+0x8], 0x27 -> ballfactory_constructor_hook2
    hook_addr(file, 0x140204f96, 0x1421C9153, padding=2)
    
    # BallFactory::getTemplateInfo: inc r9 + cmp r9, 0x27 -> get_template_info_hook
    hook_addr(file, 0x1402055a7, 0x1421C9162, padding=2)
    
    # Item::createObjects: movss xmm3, 38.0 -> create_objects_hook
    hook_addr(file, 0x14025e950, 0x1421C9174, padding=3)
    
    # LoadingScreenRenderer::constructor: lea rdx, "" -> loading_screen_hook
    hook_addr(file, 0x1402ffc2f, 0x1421C918B, padding=2)
    
    # # Direct asm patches
    # BallTemplateInfoUtils::Deserialize: lea rax, [gooBallIds] -> mov rax, [customGooBallIds]
    overwrite_bytes(file, 0x14020a850, bytes([0x48, 0x8b, 0x05, 0xa9, 0xe7, 0xfb, 0x01]))
    
    # ItemPipeIn::spawnBall: lea rax, [gooBallIds] -> mov rax, [customGooBallIds]
    overwrite_bytes(file, 0x140283ce9, bytes([0x48, 0x8b, 0x05, 0x10, 0x53, 0xf4, 0x01]))
    
    # BallFactory::load: add r14, 0x4cb48 + cmp edi, 0x27 -> 7-byte nop + cmp edi, r14d (unhardcode gooball cap)
    overwrite_bytes(file, 0x140205738, bytes([0x0F, 0x1F, 0x80, 0x00, 0x00, 0x00, 0x00, 0x44, 0x39, 0xf7]))
