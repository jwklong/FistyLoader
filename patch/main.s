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
    push rdx
    push r8
    push r9
    push r12
    
    sub rsp, 32
    
    mov ecx, -1
    call qword [rel env_init_hook-0xA0AA8] ; AttachConsole
    
    mov ecx, 0xFFFFFFF6
    call qword [rel env_init_hook-0xA0AE0] ; GetStdHandle
    mov r12, rax
    
    mov qword [rel written], 0
    
    sub rsp, 8 + 8
    mov rcx, r12
    lea rdx, qword [rel msg]
    mov r8, msgLen
    lea r9, qword [rel written]
    mov qword [rsp + 32], NULL
    call qword [rel env_init_hook-0xA0B70] ; WriteFile
    
    call qword [rel env_init_hook-0xA0768] ; GetLastError
    mov rcx, rax
    lea rax, qword [rel env_init_hook-0x1417388] ; ExitProcess wrapper function
    call rax
    
    
    add rsp, 48
    pop r12
    pop r9
    pop r8
    pop rdx
    pop rcx
    
    ; softbranch
    push rbp
    push rbx
    push rsi
    push rdi
    
    lea rax, qword [rel env_init_hook-0x182F6E3]
    jmp rax
    
; in order to pad the file to the correct size (0x3000)
section .ignoreme start=0x1ab9ffc
dd 0
