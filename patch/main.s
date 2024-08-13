BITS 64

section .fisty vstart=0x1ab7000
; org 0x1ab7000

; constants
NULL equ 0
STD_OUTPUT_HANDLE equ -11

msg db "Hello World", 0Dh, 0Ah
msgLen equ $-msg

; runtime data
alignb 8
written dq 0

; code
env_init_hook:
    push rcx
    push rbp
    push rdx
    push r8
    push r9
    push r10
    push r11
    
    ; SDL_ShowSimpleMessageBox
    mov ecx, 0x40
    lea rdx, [rel msgTitle]
    lea r8, [rel msgContent]
    xor r9, r9
    call env_init_hook-0x1435198
    
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rbp
    pop rcx
    
    ; softbranch
    push rbp
    push rbx
    push rsi
    push rdi
    
    ; lea rax, qword [rel env_init_hook-0x182F6E3]
    jmp env_init_hook-0x182F6E3

; constants 2 (so I don't shift the asm around)
msgTitle db "Fisty Loader", 00h
msgContent db "This is a test", 00h

; in order to pad the file to the correct size (0x3000)
section .ignoreme start=0x1ab9ffc
dd 0
