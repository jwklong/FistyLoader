from os import path

import yaml

from hooks import Hook

def generate_asm_definitions(hooks: list[Hook]):
    result = ""
    
    for hook in hooks:
        result += f"extern {hook.symbol_name}_return\n"
    
    with open('patch/build/hook_returns.inc.s', 'w') as f:
        f.write(result)

def generate_linker_symbols(hooks: list[Hook]):
    result = ""
    
    for hook in hooks:
        result += f"{hook.symbol_name}_return = {hex(hook.target_addr + hook.byte_length)};\n"
    
    with open('patch/build/hook_returns.inc.ld', 'w') as f:
        f.write(result)

def preprocess_hooks():
    hooks_path = path.join(path.dirname(__file__), 'data/hooks.yaml')
    
    with open(hooks_path, 'r') as f:
        input_file = f.read()
    
    hooks_dict: dict[str, dict] = yaml.safe_load(input_file)['hooks']
    hooks = [Hook.from_dict(symbol_name, args) for symbol_name, args in hooks_dict.items()]
    
    generate_asm_definitions(hooks)
    generate_linker_symbols(hooks)

if __name__ == '__main__':
    preprocess_hooks()
