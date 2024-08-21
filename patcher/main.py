from posixpath import dirname, isfile, join, realpath
from sys import argv
from pefile import PE, SectionStructure

from hooks import patch_game

def add_section_header(pe: PE, section_size: int):
    print(f"Increasing image size by 0x{section_size:x}...")
    
    print("Creating section .fisty...")
    section: SectionStructure = pe.sections[-1]
    section.Name = ".fisty".encode()
    section.Misc = section_size - 0x104
    section.Misc_PhysicalAddress = section_size - 0x104
    section.Misc_VirtualSize = section_size - 0x104
    # section.VirtualAddress = prev_section.VirtualAddress + prev_section.SizeOfRawData
    section.SizeOfRawData = section_size
    # section.PointerToRawData = prev_section.PointerToRawData + prev_section.SizeOfRawData
    section.PointerToRelocations = 0
    section.PointerToLinenumbers = 0
    section.NumberOfRelocations = 0
    section.NumberOfLinenumbers = 0
    section.Characteristics = 0xE0000000 # rwx permissions
    
    print(f"Virtual address of new section: 0x{section.VirtualAddress:x}")

def main():
    custom_code_path = join(dirname(realpath(argv[0])), 'custom_code.bin')
    with open(custom_code_path, 'rb') as f:
        section_content = f.read()
    
    if not isfile('out.exe') or argv[1] in ['--clean', '-c']:
        print('Reading World of Goo 2.exe...')
        pe = PE("World of Goo 2.exe")
        
        add_section_header(pe, len(section_content))
        
        print("Writing out.exe...")
        pe.write("out.exe")
    else:
        print('out.exe exists already, only applying changes...')
    
    with open('out.exe', 'rb+') as f:
        executable = f.read()
        fisty_section_offset = int.from_bytes(executable[0x3dc:0x3e0], byteorder='little')
        f.seek(fisty_section_offset)
        f.write(section_content)
        patch_game(f)

if __name__ == '__main__':
    main()
