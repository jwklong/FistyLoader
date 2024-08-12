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
written resq 1

hello:
    sub rsp, 8 + 32
    mov ecx, -11
    
    ; GetStdHandle
    call qword [0000000141A16538h]
    
    mov qword [rel written], 0
    
    sub rsp, 8 + 8
    mov rcx, rax
    lea rdx, [rel msg]
    mov r8, msgLen
    lea r9, [rel written]
    mov qword [rsp + 4 * 8], NULL
        
    ; WriteFile
    call qword [0000000141A164A8h]
    add rsp, 48
    ret
    
; in order to pad the file to the correct size (0x3000)
section .ignoreme start=0x1ab9ffc
dd 0
