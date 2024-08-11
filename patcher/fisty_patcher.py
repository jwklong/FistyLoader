from genericpath import isfile
from pefile import PE, SectionStructure

def add_section_header(pe: PE, section_size: int):
    print("Increasing section count...")
    pe.FILE_HEADER.NumberOfSections += 1
    
    print(f"Increasing image size by 0x{section_size:x}...")
    pe.OPTIONAL_HEADER.SizeOfImage += section_size
    
    prev_section: SectionStructure = pe.sections[-1]
    
    print("Creating section .fisty...")
    section = SectionStructure(PE.__IMAGE_SECTION_HEADER_format__, pe=pe)
    section.Name = ".fisty".encode()
    section.Misc = section_size
    section.Misc_PhysicalAddress = section_size
    section.Misc_VirtualSize = section_size
    section.VirtualAddress = prev_section.VirtualAddress + prev_section.SizeOfRawData
    section.SizeOfRawData = section_size
    section.PointerToRawData = prev_section.PointerToRawData + prev_section.SizeOfRawData
    section.PointerToRelocations = 0
    section.PointerToLinenumbers = 0
    section.NumberOfRelocations = 0
    section.NumberOfLinenumbers = 0
    section.Characteristics = 0x60000000
    
    section.set_file_offset(0x3d0)
    pe.sections.append(section)
    pe.__structures__.append(section)

def add_section_content(filename: str, content: bytes):
    with open(filename, 'ab') as f:
        f.write(content)

def main():
    with open('custom_code.bin', 'rb') as f:
        section_content = f.read()
    
    if not isfile('out.exe'):
        print('Reading World of Goo 2.exe...')
        pe = PE("World of Goo 2.exe")
        
        add_section_header(pe, len(section_content))
        
        print("Writing out.exe...")
        pe.write("out.exe")
        add_section_content("out.exe", section_content)
    else:
        print('out.exe exists already, only applying changes...')
        
        with open('out.exe', 'rb+') as f:
            executable = f.read()
            fisty_section_offset = int.from_bytes(executable[0x3e4:0x3e8], byteorder='little')
            f.seek(fisty_section_offset)
            f.write(section_content)
            f.truncate(f.tell())
    
    print("Done.")

if __name__ == '__main__':
    main()
