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
    test al, al
    je load_config_hook_create_balltable ; skip the following code if ballTable.ini exists already and load the config instead
    
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

load_config_hook_create_balltable:
    ; load vanilla gooball table into custom table
    lea rax, [rel load_config_hook-0xF94B50]
    mov qword [rel customGooballIds], rax
    mov qword [rel gooballCount], baseGooballCount
    
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


; eolgizmo_hook
;
; Hooks into EOLGizmo::update and makes it use the custom gooballIds
; table rather than the default one.
eolgizmo_hook:
    ; rdx is free right now
    mov rdx, [rel customGooballIds]
    mov rbx, [rdx+rcx*8] ; rbx = char* ballName
    
    jmp eolgizmo_hook-0x1A1CBC9


; ballfactory_start_hook
;
; Hooks into BallFactory::load before the loop starts to make it
; use the custom gooballIds (why does that function even reference
; that?) and repurpose r14 into the gooballCount
ballfactory_start_hook:
    mov r14, [rel gooballCount] ; r14 = gooballCount
    mov rsi, [rel customGooballIds] ; r14 = char** iterator
    add rsi, 8 ; make it point to gooballIds[1]
    jmp ballfactory_start_hook-0x1A3AA2C


; ballfactory_loop_hook
;
; Hooks into BallFactory::load during the loop to make it calculate
; the offset into this->templateInfos without r14
ballfactory_loop_hook:
    ; this fucking sucks, I assumed multiplication would not be this stupid
    mov rax, rdi
    mov rcx, 0x4cb48
    mul rcx
    
    add rbx, rax
    mov rdx, rbx
    jmp ballfactory_loop_hook-0x1A3A9D2

%include "patch/ini_extract.s"
%include "patch/ini_parse.s"

; constants
msgTitle db "Fisty Loader", 00h
msgBallTableCreateSuccess db \
    "Successfully extracted assets from exe file into 'World of Goo 2 (current installation's game directory)/game/fisty'", 00h

fistyPath db "fisty", 00h
ballTablePath db "fisty/ballTable.ini", 00h

baseGooballCount equ 39

; in order to pad the file to the correct size (0x3000)
section .ignoreme start=0x2ffc
dd 0
