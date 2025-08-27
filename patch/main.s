BITS 64

extern loading_screen_hook_return
extern loading_screen_draw_hook_return

section .fisty

customGooballIds dq 0
gooballCount dq 0

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
    call load_config_hook-0x1DE1450
    
    ; Environment::instance
    call load_config_hook-0x1E1C140
    
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
    mov qword [rsp+8], rbx
    jmp load_config_hook-0x1DB790B

load_config_hook_create_balltable:
    ; load vanilla gooball table into custom table
    lea rax, [rel load_config_hook-0xFC4B50]
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
    call load_config_hook-0x21B9C7F
    jmp load_config_hook_merge


; eolgizmo_hook
;
; Hooks into EOLGizmo::update and makes it use the custom gooballIds
; table rather than the default one.
eolgizmo_hook:
    ; rdx is free right now
    mov rdx, [rel customGooballIds]
    mov rbx, [rdx+rcx*8] ; rbx = char* ballName
    
    jmp eolgizmo_hook-0x1FA6149


; ballfactory_start_hook
;
; Hooks into BallFactory::load before the loop starts to make it
; use the custom gooballIds (why does that function even reference
; that?) and repurpose r14 into the gooballCount.
ballfactory_start_hook:
    mov r14, [rel gooballCount] ; r14 = gooballCount
    mov rsi, [rel customGooballIds] ; r14 = char** iterator
    add rsi, 8 ; make it point to gooballIds[1]
    jmp ballfactory_start_hook-0x1FC3A53


; ballfactory_loop_hook
;
; Hooks into BallFactory::load during the loop to make it calculate
; the offset into this->templateInfos without r14.
ballfactory_loop_hook:
    ; this fucking sucks, I assumed multiplication would not be this stupid
    mov rax, rdi
    mov rcx, 0x4cb48
    mul rcx
    
    add rbx, rax
    mov rdx, rbx
    jmp ballfactory_loop_hook-0x1FC3A00


; ballfactory_init_hook
;
; Hooks into BallFactory::init and modifies BallFactory's allocation size
; to be dynamically determined by gooballCount.
ballfactory_init_hook:
    mov rax, 0x4cb48 ; = sizeof(BallTemplateInfo)
    mov rcx, qword [rel gooballCount] ; = gooballCount
    mul rcx
    
    lea rcx, [rax+0x18]
    jmp ballfactory_init_hook-0x1FC3B16


; ballfactory_constructor_hook1
; 
; Hooks into BallFactory's constructor and modifies the amount of templateInfos
; to be initialized with BallTemplateInfo's constructor.
ballfactory_constructor_hook1:
    mov r8, qword [rel gooballCount]
    jmp ballfactory_constructor_hook1-0x1FC41C6


; ballfactory_constructor_hook2
; 
; Hooks into BallFactory's constructor and modifies the value
; this->templateInfos.length will be set to
ballfactory_constructor_hook2:
    mov rdx, qword [rel gooballCount]
    mov dword [rdi+0x8], edx
    jmp ballfactory_constructor_hook2-0x1FC41B6


; get_template_info_hook
; 
; Hooks into BallFactory::getTemplateInfo and modifies the
; amount of templateInfos it iterates through to gooballCount
get_template_info_hook:
    inc r9 ; r9 = i
    mov r8, qword [rel gooballCount]
    cmp r9, r8
    jmp get_template_info_hook-0x1FC3BB4


; create_objects_hook
; 
; Hooks into Item::createObjects and modifies the maximum
; gooball type for userVars with type 4
create_objects_hook:
    mov rcx, qword [rel gooballCount]
    dec rcx
    
    pxor xmm3, xmm3
    cvtsi2ss xmm3, ecx
    jmp create_objects_hook-0x1F6A81C


; loading_screen_hook
; 
; Hooks into the LoadingScreenRenderer constructor and reenables
; the unused loading screen watermark to now use the text
; in `loadingText`
loading_screen_hook:
    lea rdx, [rel loadingText]
    jmp loading_screen_hook_return


%include "patch/ini_extract.s"
%include "patch/ini_parse.s"

; constants
msgTitle db "Fisty Loader", 00h
msgBallTableCreateSuccess db \
    "Successfully extracted assets from exe file into 'World of Goo 2 (current installation's game directory)/game/fisty'", 00h

fistyPath db "fisty", 00h
ballTablePath db "fisty/ballTable.ini", 00h

baseGooballCount equ 39

loadingText db "Using FistyLoader v1.0", 00h
