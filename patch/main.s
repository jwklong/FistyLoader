BITS 64
[map symbols symbols.map]

section .fistyglobals vstart=0x1ab7000

customGooballIds dq 0
gooballCount dq 0

section .fisty start=0x40 vstart=0x1ab7040

; load_config_hook
; 
; Hooks into SDL2Environment::loadConfig to generate the fisty/ballTable.ini file
; if it doesn't already exist or load the file if it does.
load_config_hook:
    push rbx
    push rcx
    push rdx
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    
    mov rbp, rsp
    sub rsp, 64 + 128
    
    ; FileSystemUtils::CreateDir
    lea rcx, [rel fistyPath]
    call load_config_hook-0x1858150
    
    ; Environment::instance
    call load_config_hook-0x1890FB0
    
    ; Environment::getStorage (vtable[0x28])
    mov rdx, qword [rax] ; rdx = env->vtable
    mov rcx, rax
    call qword [rdx + 0x140]
    mov rbx, rax ; rbx = SDL2Storage* storage
    
    ; SDL2Storage::FileExists (vtable[1])
    ; I'm just going to ignore the TOCTOU "vulnerability" here
    mov r12, qword [rbx] ; r12 = storage->vtable
    mov rcx, rbx ; this
    lea rdx, [rel ballTablePath] ; filePath
    call qword [r12+0x8]
    test al, al ; for some reason FileExists outputs in al only
    jne load_config_hook_read_config ; skip the following code if ballTable.ini exists already and load the config instead
    
    ; Generate the config file
    call create_ball_table
    test rax, rax
    je load_config_hook_merge
    
    ; SDL_ShowSimpleMessageBox
    mov ecx, 0x40
    lea rdx, [rel msgTitle]
    lea r8, [rel msgBallTableCreateSuccess]
    xor r9, r9
    call load_config_hook-0x1AADD91
    jmp load_config_hook_merge


load_config_hook_read_config:
    ; storage passed in as rbx
    call load_ball_table

load_config_hook_merge:
    add rsp, 64 + 128
    
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdx
    pop rcx
    pop rbx
    
    ; softbranch
    mov qword [rsp+0x10], rbx
    jmp load_config_hook-0x182E5AB


%include "patch/ini_parse.s"


; create_ball_table
;
; Creates ballTable.ini and extracts the default gooballIds table into it.
;
; Input: rbx - SDL2Storage* storage
; Result: rax - bool success (1 if success, 0 if error)
; Clobbers: ?
create_ball_table:
    push rbp
    push r12
    push rdi
    push r13
    
    mov rbp, rsp
    sub rsp, 0x28 + 0x80 + 0x20
    
    mov r12, qword [rbx] ; r12 = storage->vtable
    
    ; SDL2Storage::FileOpen (vtable[2])
    mov rcx, rbx ; this
    lea rdx, [rel ballTablePath] ; filePath
    mov r8, 0x22 ; flags (0x22 : "w+b")
    lea r9, [rbp-0x10] ; out_fileHandle
    call qword [r12+0x10]
    
    ; if (result != 0) goto create_ball_table_failure
    test rax, rax
    jne create_ball_table_failure
    
    
    ; FileOpen succeded
    mov rdi, qword [rbp-0x10] ; rdi = fileHandle
    
    ; write header
    ; SDL2Storage::FileWrite (vtable[4])
    mov rcx, rbx ; this
    mov rdx, rdi ; fileHandle
    lea r8, [rel ballTableHeader] ; content
    mov r9, ballTableHeaderLen ; size
    call qword [r12+0x20]
    
    
    ; loop: print all default gooball ids
    mov r13, 0 ; r13 = int i
create_ball_table_loop_start:
    lea rcx, [rel load_config_hook-0xF94B50] ; gooballIds
    mov rcx, [rcx + r13 * 8]
    mov [rsp+0x20], rcx
    
    ; snprintf
    lea rcx, [rbp-0x90] ; dst
    mov rdx, 0x80 ; = 128, n
    lea r8, [rel ballTableLineFormat] ; format
    mov r9, r13 ; var arg 0
    call load_config_hook-0x1A62720
    
    ; SDL2Storage::FileWrite (vtable[4])
    mov rcx, rbx ; this
    mov rdx, rdi ; fileHandle
    lea r8, [rbp-0x90] ; content
    mov r9, rax ; size
    call qword [r12+0x20]
    
    add r13, 1
    cmp r13, baseGooballCount
    jl create_ball_table_loop_start
    
    
    ; SDL2Storage::FileClose (vtable[5])
    mov rcx, rbx ; this
    mov rdx, rdi ; fileHandle
    call qword [r12+0x28]
    
    mov rax, 1 ; 1 for success
    
create_ball_table_merge:
    add rsp, 0x28 + 0x80 + 0x20
    
    pop r13
    pop rdi
    pop r12
    pop rbp
    ret
    
create_ball_table_failure:
    ; Show error message that ballTable.ini could not be created
    ; SDL_ShowSimpleMessageBox
    mov ecx, 0x10
    lea rdx, [rel msgTitle]
    lea r8, [rel msgBallTableCreateErr]
    xor r9, r9
    call load_config_hook-0x1AADD91
    
    xor rax, rax ; 0 for error
    jmp create_ball_table_merge


; constants
msgTitle db "Fisty Loader", 00h
msgBallTableCreateErr db \
    "Failed to create ballTable.ini file. Make sure the game directory is not ",\
    "inside C:\Program Files or any other place that requires administrator permissions.", 0Ah, 0Ah,\
    "Continuing with default settings.", 00h
msgBallTableCreateSuccess db \
    "Successfully extracted assets from exe file into 'World of Goo 2 (current installation's game directory)/game/fisty'", 00h

fistyPath db "fisty", 00h
ballTablePath db "fisty/ballTable.ini", 00h
ballTableHeader db \
    "; This table defines all Gooball typeEnums", 0Dh, 0Ah, \
    "; Extend this list to add your own gooballs.", 0Dh, 0Ah, \
    "; ", 0Dh, 0Ah, \
    "; Generated by FistyLoader 0.1", 0Dh, 0Ah, 0Dh, 0Ah
ballTableHeaderLen equ $-ballTableHeader
db 0

ballTableLineFormat db "%d=%s", 0Dh, 0Ah, 00h

baseGooballCount equ 39

; in order to pad the file to the correct size (0x3000)
section .ignoreme start=0x2ffc
dd 0
