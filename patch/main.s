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
    push rbx
    push rcx
    push r12
    
    sub rsp, 32
    
    ; AttachConsole
    mov ecx, -1
    call qword [rel env_init_hook-0xA0AA8]
    
    ; GetStdHandle
    mov ecx, 0xFFFFFFF6
    call qword [rel env_init_hook-0xA0AE0]
    
    ; WriteFile
    mov qword [rel written], 0
    sub rsp, 16
    mov ecx, eax
    lea edx, [rel msg]
    mov r8, msgLen
    mov r9, [rel written]
    mov qword [rsp+32], NULL
    call qword [rel env_init_hook-0xA0B70]
    
    add rsp, 48
    
    pop r12
    pop rcx
    pop rbx
    
    mov qword [rsp+10h],rbx
    jmp env_init_hook-0x1892E13
    
; in order to pad the file to the correct size (0x3000)
section .ignoreme start=0x1ab9ffc
dd 0
