BITS 64
[map symbols symbols.map]

section .fistyglobals vstart=0x1ab7000

customGooballIds dq 0
gooballCount dq 0
temp dq 0

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
    ; SDL2Storage::FileOpen (vtable[2])
    mov rcx, rbx ; this
    lea rdx, [rel ballTablePath] ; filePath
    mov r8, 0x22 ; flags (0x22 : "w+b")
    lea r9, [rbp-0x10] ; out_fileHandle
    call qword [r12+0x10]
    
    ; if (result == 0) continue else load_config_hook_failure
    test rax, rax
    jne load_config_hook_failure
    ; FileOpen succeded
    ; SDL2Storage::FileWrite (vtable[4])
    mov rcx, rbx ; this
    mov rdx, [rbp-0x10] ; fileHandle
    lea r8, [rel ballTableHeader] ; content
    mov r9, ballTableHeaderLen ; size
    call qword [r12+0x20]
    
    ; for (int i = 0; i < GooBallType::COUNT; i++)
    mov r12, 0 ; r12 = no longer vtable, now int i
load_config_hook_loop_start:
    lea rcx, [rel load_config_hook-0xF94B50] ; gooballIds
    mov rcx, [rcx + r12 * 8]
    mov [rsp+0x20], rcx
    
    ; snprintf
    lea rcx, [rbp-0x90] ; dst
    mov rdx, 0x80 ; = 128, n
    lea r8, [rel ballTableLineFormat] ; format
    mov r9, r12 ; var arg 0
    call load_config_hook-0x1A62720
    
    ; SDL2Storage::FileWrite (vtable[4])
    mov rcx, rbx ; this
    mov rdx, [rbp-0x10] ; fileHandle
    lea r8, [rbp-0x90] ; content
    mov r9, rax ; size
    mov rax, qword [rbx]
    call qword [rax+0x20]
    
    add r12, 1
    cmp r12, baseGooballCount
    jl load_config_hook_loop_start
    
    ; end of loop
    ; SDL2Storage::FileClose (vtable[5])
    mov rcx, rbx ; this
    mov rdx, [rbp-0x10] ; fileHandle
    mov rax, qword [rbx]
    call qword [rax+0x28]
    
    ; SDL_ShowSimpleMessageBox
    mov ecx, 0x40
    lea rdx, [rel msgTitle]
    lea r8, [rel msgBallTableCreateSuccess]
    xor r9, r9
    call load_config_hook-0x1AADD91
    jmp load_config_hook_merge

load_config_hook_failure:
    ; Show error message that ballTable.ini could not be created
    ; SDL_ShowSimpleMessageBox
    mov ecx, 0x10
    lea rdx, [rel msgTitle]
    lea r8, [rel msgBallTableCreateErr]
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


; load_ball_table
;
; Parses the ballTable.ini file and loads the result into customGooballIds and gooballCount
;
; Input: rbx - SDL2Storage* storage
; Returns: N/A
; Clobbers: rax, rcx, r8, r9, r10, r11 flags
load_ball_table:
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rdi
    
    mov rbp, rsp
    sub rsp, 0x30 + 0x20
    
    ; read ballTable.ini into new buffer
    ; r12 = storage->vtable
    mov r12, qword [rbx]
    
    ; SDL2Storage::FileOpen (vtable[2])
    mov rcx, rbx ; this
    lea rdx, [rel ballTablePath] ; filePath
    mov r8, 0x11 ; flags (0x11 : "rb")
    lea r9, [rbp-0x8] ; out_fileHandle
    call qword [r12+0x10]
    
    ; SDL2Storage::GetFileSize (vtable[7])
    mov rcx, rbx ; this
    mov rdx, [rbp-0x8] ; fileHandle
    call qword [r12+0x38]
    mov r14d, eax ; r14d = int fileSize
    
    ; malloc
    lea ecx, [eax+1]
    call qword [rel load_ball_table-0x9F65A]
    mov r13, rax ; r13 = char* inputFile
    
    ; SDL2Storage::FileRead (vtable[3])
    mov rcx, rbx ; this
    mov rdx, [rbp-0x8] ; fileHandle
    mov r8, r13 ; content
    mov r9d, r14d ; size
    call qword [r12+0x18]
    
    ; do null termination
    movsxd rcx, r14d
    mov byte [r13+rcx], 0
    
    ; SDL2Storage::FileClose (vtable[5])
    mov rcx, rbx ; this
    mov rdx, [rbp-0x8] ; fileHandle
    call qword [r12+0x28]
    
    ; parse ballTable.ini content
    mov rbx, -1 ; rbx = max gooball id
    mov rdi, 0 ; rdi = gooball name buffer size
    mov r12, r13 ; r12 = filePtr
    movsxd r14, r14d
    add r14, r13 ; r14 = fileEnd
    mov qword [rbp-0x10], r13 ; = inputFile
    
    
    ; first loop: count max gooball id and value string buffer size
load_ball_table_pre_first_loop_start:
    cmp r12, r14
    jge load_ball_table_alloc_buffers
    
load_ball_table_first_loop_start:
    call read_line_until_equals
    cmp eax, -2
    je load_ball_table_error
    cmp eax, -1
    je load_ball_table_pre_first_loop_start
    
    ; left hand side (eax) is now valid and r12 is pointing to an '=' sign
    inc r12
    
    ; update max gooball id
    cmp eax, ebx
    cmovg ebx, eax
    
    ; read rest of line
    call read_line_trimmed
    add rdi, rax ; add read length to total buffer size
    
    ; add 1 to total buffer size (null terminator) if read length isn't 0
    lea rcx, [rdi+1]
    test rax, rax
    cmovne rdi, rcx
    
    cmp r12, r14
    jl load_ball_table_first_loop_start
    
    
load_ball_table_alloc_buffers:
    ; make sure that there is at least 1 gooball defined
    test rbx, rbx
    js load_ball_table_error
    
    ; debug
    ; snprintf
    mov [rsp+0x20], rdi
    lea rcx, [rel temp] ; dst
    mov rdx, 0x30 ; = 32, n
    lea r8, [rel ballTableDebugFormat2] ; format
    mov r9d, ebx ; var arg 0
    call load_config_hook-0x1A62720
    
    ; SDL_ShowSimpleMessageBox
    mov ecx, 0x40
    lea rdx, [rel msgTitle]
    lea r8, [rel temp]
    xor r9, r9
    call load_config_hook-0x1AADD91
    
    ; rbx = gooball id count, no longer max gooball id
    inc rbx
    
    ; allocate gooballIds[rbx+1] (w/ padding for safety) + string buffer
    ; malloc
    lea ecx, [rbx*8+rdi+8]
    call qword [rel load_ball_table-0x9F65A]
    mov qword [rbp-0x20], rax ; = char** gooballIds
    lea rdx, [rax+rbx*8] ; rdx = char** gooballIdsEnd
    add rdi, rdx ; rdi = char* stringBufEnd
    
    
    ; second loop: fill gooballIds with empty strings
    lea rcx, [rel load_ball_table-0x12566B9] ; rcx = "" (empty string)
load_ball_table_fill_empty_strings:
    mov [rax], rcx
    add rax, 8
    cmp rax, rdx
    jl load_ball_table_fill_empty_strings
    
    
    mov qword [rax], 0 ; write trailing null pointer
    
    lea r15, [rdx+8] ; r15 = char* stringBuf
    lea rdi, [rdx+rdi+8] ; rdi = char* stringBufEnd
    mov qword [rbp-0x18], rbx ; = gooball id count
    
    mov r12, qword [rbp-0x10] ; reset r12 to start of file
    
    ; third loop: populate gooballIds and stringBuf
load_ball_table_pre_second_loop_start:
    cmp r12, r14
    jge load_ball_table_merge
    
load_ball_table_second_loop_start:
    call read_line_until_equals
    ; no need to check for -2 as if an error existed, it would have been caught already
    cmp eax, -1
    je load_ball_table_pre_second_loop_start
    movsxd rax, eax
    mov r13, rax ; r13 = current gooball id
    
    ; left hand side (eax) is now valid and r12 is pointing to an '=' sign
    inc r12
    
    ; read rest of line
    call read_line_trimmed
    
    ; continue if rhsLen is 0
    test rax, rax
    je load_ball_table_pre_second_loop_start
    
    mov rbx, rax ; rbx = int rhsLen
    
    ; copy rhs into stringBuf
    ; strncpy
    mov rdx, rcx ; src
    mov rcx, r15 ; dest
    mov r8, rax ; count
    call qword [rel load_ball_table-0x9F04A]
    
    mov byte [r15+rbx], 0 ; null terminator
    
    ; move current stringBuf ptr into gooballIds
    mov rcx, qword [rbp-0x20] ; rcx = char** gooballIds
    mov [rcx+r13*8], r15
    
    lea r15, [r15+rbx+1]
    
    cmp r12, r14
    jl load_ball_table_second_loop_start
    
    
load_ball_table_merge:
    mov rcx, qword [rbp-0x20] ; rcx = char** gooballIds
    mov rdx, qword [rbp-0x18] ; rdx = int gooballIdCount
    
    mov [rel customGooballIds], rcx
    mov [rel gooballCount], rdx
    
    ; SDL_ShowSimpleMessageBox
    mov ecx, 0x40
    lea rdx, [rel msgTitle]
    lea r8, [rel msgBallTableRead]
    xor r9, r9
    call load_config_hook-0x1AADD91
    
    ; TODO: remember to free

    add rsp, 0x30 + 0x20
    
    pop rdi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
    
load_ball_table_error:
    ; TODO: make an actually good error handler
    ; SDL_ShowSimpleMessageBox
    mov ecx, 0x10
    lea rdx, [rel msgTitle]
    lea r8, [rel msgTitle]
    xor r9, r9
    call load_config_hook-0x1AADD91
    
    jmp load_ball_table_merge


; read_line_until_equals
; 
; Reads one line of ballTable.ini until it encounters an equals sign (=)
; and parses the left hand side into an integer if it does.
; If the lhs is not a valid integer, 
; 
; Input:    r12 - char* file_ptr, r14 - char* file_end
; Returns:  rax - Left hand side of the line parsed as an int if valid,
;                 -1 if the line contains no '='
;                 and -2 if the lhs is not an integer.
;           r12 - Updated file_ptr
; Clobbers: flags, ? (check with debugger)
read_line_until_equals:
    push rbp
    push rbx
    push r13
    push r15
    
    mov rbp, rsp
    sub rsp, 0x10 + 0x20
    
    ; first loop: check for when whitespace ends
read_line_until_equals_first_loop_start:
    ; check for bounds
    cmp r12, r14
    jge read_line_until_equals_return_empty
    
    ; check for special chars
    mov al, byte [r12]
    cmp al, 0Ah ; '\n'
    je read_line_until_equals_return_empty ; increments r12 so it points to the start of next line
    cmp al, 59 ; ';'
    je read_line_until_equals_skip_to_eol
    cmp al, 61 ; '='
    je read_line_until_equals_return_err
    
    ; isspace
    movzx rcx, al
    call qword [rel load_ball_table-0x9F02A]
    
    ; loop back again and increment r12 only if al is a space
    lea rcx, [r12+1]
    test eax, eax
    cmovne r12, rcx
    jne read_line_until_equals_first_loop_start
    
    ; second loop: read lhs until '=' sign
    mov rbx, r12 ; rbx = char* lhsPtr
    mov r13, 1 ; r13 = lhsLength
    mov r15, 1 ; r15 = lhsLength incl. whitespace
    
    inc r12
    cmp r12, r14
    jge read_line_until_equals_return_err
    cmp byte [r12], 61 ; '='
    je read_line_until_equals_end_of_read
    
read_line_until_equals_second_loop_start:
    ; check for eol
    mov al, byte [r12]
    cmp al, 0Ah ; '\n'
    je read_line_until_equals_return_err
    cmp al, 59 ; ';'
    je read_line_until_equals_return_err
    
    ; increment whitespace inclusive lhsLength
    ; (actual lhsLength will be updated too later,
    ; assuming that c isn't whitespace)
    ; this is to trim off trailing whitespace :)
    inc r15
    
    ; isspace
    movzx rcx, al
    call qword [rel load_ball_table-0x9F02A]
    test eax, eax
    cmove r13, r15 ; update the actual rhsLength if c is not whitespace
    
    inc r12
    cmp r12, r14
    jge read_line_until_equals_return_err
    cmp byte [r12], 61 ; '='
    jne read_line_until_equals_second_loop_start
    
    ; now parse lhs into an int
read_line_until_equals_end_of_read:
    mov rax, r13 ; lhsLength
    
    ; reset errno to 0
    call qword [rel load_ball_table-0x9F382]
    mov dword [rax], 0
    
    ; strtol
    mov rcx, rbx ; str
    lea rdx, [rbp-0x8] ; str_end (out)
    mov r8, 10 ; base
    call qword [rel load_ball_table-0x9F842]
    mov r15d, eax
    
    ; errno
    call qword [rel load_ball_table-0x9F382]
    cmp dword [rax], 0
    jne read_line_until_equals_return_err
    
    ; make sure strtol read the correct amount of characters
    mov rax, qword [rbp-0x8] ; str_end returned from strtol
    sub rax, rbx ; subtract lhsPtr to get the amount of chars read
    cmp rax, r13
    jne read_line_until_equals_return_err
    
    ; make sure lhs is not negative
    test r15d, r15d
    js read_line_until_equals_return_err
    
    ; success :D
    mov eax, r15d
    
    add rsp, 0x10 + 0x20
    
    pop r15
    pop r13
    pop rbx
    pop rbp
    ret
    
read_line_until_equals_skip_to_eol:
    inc r12
    cmp r12, r14
    setl cl
    cmp byte [r12], 0Ah ; r12 shouldn't be greater than r14 so this is fine
    setne dl
    test cl, dl ; if (cl && dl) continue loop
    jne read_line_until_equals_skip_to_eol
    ; fall through   
read_line_until_equals_return_empty:
    inc r12
    mov rax, -1
    
    add rsp, 0x10 + 0x20
    
    pop r15
    pop r13
    pop rbx
    pop rbp
    ret
    
read_line_until_equals_return_err:
    mov rax, -2
    
    add rsp, 0x10 + 0x20
    
    pop r15
    pop r13
    pop rbx
    pop rbp
    ret


; read_line_trimmed
;
; Reads from a pointer until it encounters a newline, semicolon
; or the end of file while stripping it from trailing whitespace.
;
; Returns the start of non-whitespace content together with the amount
; of characters it has read (excluding null-terminator).
;
; Input: r12 - char* filePtr, r14 - char* fileEnd
; Returns: rax - int contentLen, rcx - char* contentPtr, r12 - Updated filePtr
; Clobbers: flags, ?
read_line_trimmed:
    push rbp
    push rbx
    push rdi
    push rsi
    
    mov rbp, rsp
    sub rsp, 0x20
    
    xor rdi, rdi ; rdi - int length
    xor rsi, rsi ; rsi - int length incl. trailing whitespace
    xor rbx, rbx ; rbx - char* contentPtr
    
    ; first loop: skip to the first non-space char
read_line_trimmed_skip_spaces:
    cmp r12, r14
    jge read_line_trimmed_merge
    
    mov al, byte [r12]
    cmp al, 0Ah ; '\n'
    je read_line_trimmed_merge
    cmp al, 59 ; ';'
    je read_line_trimmed_skip_to_eol
    
    ; isspace
    movzx rcx, al
    call qword [rel load_ball_table-0x9F02A]
    
    ; continue loop if c is a space
    lea rcx, [r12+1]
    test eax, eax
    cmovne r12, rcx
    jne read_line_trimmed_skip_spaces
    
    
    ; second loop: skip to end of line and increment rdi along the way
    inc rdi ; at this point, we have at least 1 non space char
    mov rsi, rdi
    mov rbx, r12
    
    inc r12
    cmp r12, r14
    jge read_line_trimmed_merge
    
    mov al, byte [r12]
    cmp al, 0Ah ; '\n'
    je read_line_trimmed_merge
    cmp al, 59 ; ';'
    je read_line_trimmed_skip_to_eol
read_line_trimmed_count_name_chars:
    ; increment whitespace inclusive length
    ; see read_line_until_equals_second_loop_start
    inc rsi
    
    ; isspace
    movzx rcx, al
    call qword [rel load_ball_table-0x9F02A]
    test eax, eax
    cmove rdi, rsi ; update the actual length if not whitespace
    
    inc r12
    cmp r12, r14
    jge read_line_trimmed_merge
    
    ; continue loop if c != '\n' && c != ';'
    mov al, byte [r12]
    cmp al, 0Ah ; '\n'
    setne cl
    cmp al, 59 ; ';'
    setne dl
    test cl, dl
    jne read_line_trimmed_count_name_chars
    
    
    ; third loop: if c == ';' then skip to eol
    cmp al, 59
    jne read_line_trimmed_merge
read_line_trimmed_skip_to_eol:
    inc r12
    cmp r12, r14
    setl cl
    cmp byte [r12], 0Ah ; r12 shouldn't be greater than r14 so this is fine
    setne dl
    test cl, dl ; if (cl && dl) continue loop
    jne read_line_trimmed_skip_to_eol
    
    
read_line_trimmed_merge:
    inc r12 ; so it points to the start of next line
    mov rax, rdi ; out_contentLen
    mov rcx, rbx ; out_contentPtr
    
    add rsp, 0x20
    
    pop rsi
    pop rdi
    pop rbx
    pop rbp
    ret

; constants
msgTitle db "Fisty Loader", 00h
msgBallTableCreateErr db \
    "Failed to create ballTable.ini file. Make sure the game directory is not ",\
    "inside C:\Program Files or any other place that requires administrator permissions.", 0Ah, 0Ah,\
    "Continuing with default settings.", 00h
msgBallTableCreateSuccess db \
    "Successfully extracted assets from exe file into 'World of Goo 2 (current installation's game directory)/game/fisty'", 00h

msgBallTableRead db \
    "Loaded ballTable.ini", 00h

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

ballTableDebugFormat db "id %d with name %s", 00h
ballTableDebugFormat2 db \
    "maxgooballcount=%d", 0Ah,\
    "buffersize=%d", 00h

baseGooballCount equ 39

; in order to pad the file to the correct size (0x3000)
section .ignoreme start=0x2ffc
dd 0
