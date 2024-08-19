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
    sub rsp, 0x30 + 0x110 + 0x20
    
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
    call qword [rel load_config_hook-0x9F510]
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
    mov qword [rbp-0x28], rbx ; = storage
    mov rbx, -1 ; rbx = max gooball id
    xor rdi, rdi ; rdi = gooball name buffer size
    
    mov r12, r13 ; r12 = filePtr
    movsxd r14, r14d
    add r14, r13 ; r14 = fileEnd
    xor r15, r15 ; r15 = int lineNumber
    
    mov qword [rbp-0x10], r13 ; = inputFile
    
    
    ; first loop: count max gooball id and value string buffer size
load_ball_table_pre_first_loop_start:
    cmp r12, r14
    jge load_ball_table_alloc_buffers
    
load_ball_table_first_loop_start:
    inc r15
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
    mov rcx, 1
    test rbx, rbx
    cmovs r15, rcx
    js load_ball_table_error
    
    ; rbx = gooball id count, no longer max gooball id
    inc rbx
    
    ; allocate gooballIds[rbx+1] (w/ padding for safety) + string buffer
    ; malloc
    lea ecx, [rbx*8+rdi+8]
    call qword [rel load_config_hook-0x9F510]
    mov qword [rbp-0x20], rax ; = char** gooballIds
    lea rdx, [rax+rbx*8] ; rdx = char** gooballIdsEnd
    add rdi, rdx ; rdi = char* stringBufEnd
    
    
    ; second loop: fill gooballIds with empty strings
    lea rcx, [rel load_config_hook-0x125656F] ; rcx = "" (empty string)
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
    jge load_ball_table_done
    
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
    call qword [rel load_config_hook-0x9EF00]
    
    mov byte [r15+rbx], 0 ; null terminator
    
    ; move current stringBuf ptr into gooballIds
    mov rcx, qword [rbp-0x20] ; rcx = char** gooballIds
    mov [rcx+r13*8], r15
    
    lea r15, [r15+rbx+1]
    
    cmp r12, r14
    jl load_ball_table_second_loop_start
    
    
load_ball_table_done:
    mov rcx, qword [rbp-0x20] ; rcx = char** gooballIds
    mov rdx, qword [rbp-0x18] ; rdx = int gooballIdCount
    
    mov [rel customGooballIds], rcx
    mov [rel gooballCount], rdx
    
load_ball_table_merge:
    ; free
    mov rcx, qword [rbp-0x10] ; rcx = char* inputFile
    call qword [rel load_config_hook-0x9F4D8]
    
    add rsp, 0x30 + 0x110 + 0x20
    
    pop rdi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
    
load_ball_table_error:
    ; Show error message
    ; snprintf
    lea rcx, [rbp-0x28-0x110] ; dst
    mov rdx, 0x110 ; n
    lea r8, [rel msgBallTableReadErr] ; format
    mov r9, r15 ; var arg 0
    call load_config_hook-0x1A62720
    
    ; SDL_ShowSimpleMessageBox
    mov ecx, 0x10
    lea rdx, [rel msgTitle]
    lea r8, [rbp-0x28-0x110]
    xor r9, r9
    call load_config_hook-0x1AADD91
    
    ; Create ballTable_backup.ini file with current content
    ; and regenerate ballTable.ini
    mov rbx, [rbp-0x28] ; rbx = SDL2Storage* storage
    mov r12, [rbx] ; r12 = rbx->vtable
    
    ; SDL2Storage::FileOpen (vtable[2])
    mov rcx, rbx ; this
    lea rdx, [rel ballTableBackupPath] ; filePath
    mov r8, 0x22 ; flags (0x22 : "w+b")
    lea r9, [rbp-0x8] ; out_fileHandle
    call qword [r12+0x10]
    
    ; if (result != 0) goto create_ball_table_failure
    test rax, rax
    jne load_ball_table_backup_failure
    
    ; FileOpen succeeded
    mov r13, qword [rbp-0x10] ; r13 = char* inputFile
    mov rdi, qword [rbp-0x8] ; rdi = fileHandle
    sub r14, r13 ; r14 = fileSize
    
    ; SDL2Storage::FileWrite (vtable[4])
    mov rcx, rbx ; this
    mov rdx, rdi ; fileHandle
    mov r8, r13 ; content
    mov r9, r14 ; size
    call qword [r12+0x20]
    
    ; SDL2Storage::FileClose (vtable[5])
    mov rcx, rbx ; this
    mov rdx, rdi ; fileHandle
    call qword [r12+0x28]
    
    ; Regenerate ballTable.ini
    call create_ball_table
    
load_ball_table_error_merge:
    ; load vanilla gooball table into custom table
    mov qword [rel customGooballIds], load_config_hook-0xF94B50
    mov qword [rel gooballCount], baseGooballCount
    jmp load_ball_table_merge
    
load_ball_table_backup_failure:
    ; SDL_ShowSimpleMessageBox
    mov ecx, 0x10
    lea rdx, [rel msgTitle]
    lea r8, [rel msgBallTableBackupErr]
    xor r9, r9
    call load_config_hook-0x1AADD91
    jmp load_ball_table_error_merge


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
    call qword [rel load_config_hook-0x9EEE0]
    
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
    call qword [rel load_config_hook-0x9EEE0]
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
    call qword [rel load_config_hook-0x9F238]
    mov dword [rax], 0
    
    ; strtol
    mov rcx, rbx ; str
    lea rdx, [rbp-0x8] ; str_end (out)
    mov r8, 10 ; base
    call qword [rel load_config_hook-0x9F6F8]
    mov r15d, eax
    
    ; errno
    call qword [rel load_config_hook-0x9F238]
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
    call qword [rel load_config_hook-0x9EEE0]
    
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
    call qword [rel load_config_hook-0x9EEE0]
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
msgBallTableReadErr db \
    "Error reading ballTable.ini in line %d.", 0Ah, 0Ah, \
    "Copied current ballTable file to 'ballTable_backup.ini'", 0Ah, \
    "and regenerated ballTable.", 0Ah, 0Ah, \
    "Continuing with default settings.", 00h
msgBallTableBackupErr db \
    "Failed to create ballTable_backup.ini.", 0Ah, \
    "ballTable.ini will not be modified.", 0Ah, 0Ah, \
    "If you wish to still have it be regenerated,", 0Ah, \
    "delete the file and start the game again.", 0Ah, 0Ah, \
    "Continuing with default settings.", 00h

ballTableBackupPath db "fisty/ballTable_backup.ini", 00h
