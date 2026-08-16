%ifndef ROSAM_PLATFORM_WINDOWS_X64_INCLUDED
%define ROSAM_PLATFORM_WINDOWS_X64_INCLUDED 1

BITS 64
default rel

; Microsoft x64 ABI:
;   integer/pointer arguments 1..4 -> RCX,RDX,R8,R9
;   caller reserves 32-byte shadow space
;   call-site stack must be 16-byte aligned
;
; IMPORTANT: Win64 API calls with five or more arguments need the
; fifth argument in the stack area above the 32-byte shadow space.

%macro ROSAM_CALL0 1
    sub rsp, 40
    call %1
    add rsp, 40
%endmacro

%macro ROSAM_ADDR_CALL1 2
    sub rsp, 40
    lea rcx, [rel %2]
    call %1
    add rsp, 40
%endmacro

%macro ROSAM_VALUE_CALL1 2
    sub rsp, 40
    mov rcx, %2
    call %1
    add rsp, 40
%endmacro

%macro ROSAM_ADDR_ADDR_CALL2 3
    sub rsp, 40
    lea rcx, [rel %2]
    lea rdx, [rel %3]
    call %1
    add rsp, 40
%endmacro

%macro ROSAM_ADDR_IMM_CALL2 3
    sub rsp, 40
    lea rcx, [rel %2]
    mov edx, %3
    call %1
    add rsp, 40
%endmacro

%macro ROSAM_ADDR_MEM_CALL2 3
    sub rsp, 40
    lea rcx, [rel %2]
    mov rdx, qword [rel %3]
    call %1
    add rsp, 40
%endmacro

%macro ROSAM_ADDR_IMM_ADDR_CALL3 4
    sub rsp, 40
    lea rcx, [rel %2]
    mov edx, %3
    lea r8, [rel %4]
    call %1
    add rsp, 40
%endmacro

%macro ROSAM_ADDR_ADDR_VALUE_CALL2 3
    sub rsp, 40
    lea rcx, [rel %2]
    lea rdx, [rel %3]
    call %1
    add rsp, 40
%endmacro

%macro ROSAM_STR_EQUAL_BRANCH 3
    sub rsp, 40
    lea rcx, [rel %1]
    lea rdx, [rel %2]
    call rosam_str_equal
    add rsp, 40
    test eax, eax
    jnz %3
%endmacro

%macro ROSAM_STR_EQUAL_STORE 3
    sub rsp, 40
    lea rcx, [rel %2]
    lea rdx, [rel %3]
    call rosam_str_equal
    add rsp, 40
    mov dword [rel %1], eax
%endmacro

%macro ROSAM_RETURN_I32 1
    %ifnum %1
        mov eax, %1
    %else
        mov eax, dword [rel %1]
    %endif
%endmacro

%macro ROSAM_RETURN_I64 1
    %ifnum %1
        mov rax, %1
    %else
        mov rax, qword [rel %1]
    %endif
%endmacro

%macro ROSAM_EXIT 1
    sub rsp, 40
    mov ecx, %1
    call rosam_process_exit
    ud2
%endmacro

%macro ROSAM_CMP_I32_EQ 3
    mov eax, dword [rel %1]
    cmp eax, dword [rel %2]
    je %3
%endmacro
%macro ROSAM_CMP_I32_NE 3
    mov eax, dword [rel %1]
    cmp eax, dword [rel %2]
    jne %3
%endmacro
%macro ROSAM_CMP_I32_LT 3
    mov eax, dword [rel %1]
    cmp eax, dword [rel %2]
    jl %3
%endmacro
%macro ROSAM_CMP_I32_LE 3
    mov eax, dword [rel %1]
    cmp eax, dword [rel %2]
    jle %3
%endmacro
%macro ROSAM_CMP_I32_GT 3
    mov eax, dword [rel %1]
    cmp eax, dword [rel %2]
    jg %3
%endmacro
%macro ROSAM_CMP_I32_GE 3
    mov eax, dword [rel %1]
    cmp eax, dword [rel %2]
    jge %3
%endmacro

%macro ROSAM_CMP_I32_EQ_VAL 3
    mov eax, dword [rel %1]
    cmp eax, %2
    je %3
%endmacro
%macro ROSAM_CMP_I32_NE_VAL 3
    mov eax, dword [rel %1]
    cmp eax, %2
    jne %3
%endmacro
%macro ROSAM_CMP_I32_LT_VAL 3
    mov eax, dword [rel %1]
    cmp eax, %2
    jl %3
%endmacro
%macro ROSAM_CMP_I32_LE_VAL 3
    mov eax, dword [rel %1]
    cmp eax, %2
    jle %3
%endmacro
%macro ROSAM_CMP_I32_GT_VAL 3
    mov eax, dword [rel %1]
    cmp eax, %2
    jg %3
%endmacro
%macro ROSAM_CMP_I32_GE_VAL 3
    mov eax, dword [rel %1]
    cmp eax, %2
    jge %3
%endmacro

%macro ROSAM_I32_INC 1
    add dword [rel %1], 1
%endmacro

%macro ROSAM_I32_DEC 1
    sub dword [rel %1], 1
%endmacro

%macro ROSAM_LOOP_DEC_I32 2
    mov ecx, dword [rel %1]
%%loop:
    test ecx, ecx
    jz %%done
    dec ecx
    jmp %2
%%done:
    mov dword [rel %1], ecx
%endmacro

%macro ROSAM_ARRAY_GET_I32 3
    lea r11, [rel %1]
    %ifnum %2
        mov eax, dword [r11 + %2*4]
    %else
        mov r10d, dword [rel %2]
        mov eax, dword [r11 + r10*4]
    %endif
    mov dword [rel %3], eax
%endmacro

%macro ROSAM_ARRAY_SET_I32 3
    lea r11, [rel %1]
    mov eax, dword [rel %3]
    %ifnum %2
        mov dword [r11 + %2*4], eax
    %else
        mov r10d, dword [rel %2]
        mov dword [r11 + r10*4], eax
    %endif
%endmacro

extern GetStdHandle
extern WriteFile
extern ReadFile
extern ExitProcess

%define STD_INPUT_HANDLE  -10
%define STD_OUTPUT_HANDLE -11

section .data
align 1
rosam_win_minus: db '-', 0

section .bss
align 8
rosam_win_input_buf: resb 4096
rosam_win_input_len: resq 1
rosam_win_int_buf:   resb 32
rosam_win_error:     resq 1

section .text

; ------------------------------------------------------------
; rosam_io_write_buf
; RCX = pointer
; RDX = byte count
; Return RAX = 0 on success, -1 on failure.
; ------------------------------------------------------------
global rosam_io_write_buf
rosam_io_write_buf:
    sub rsp, 72

    mov [rsp+32], qword 0          ; WriteFile arg #5: lpOverlapped = NULL
    mov [rsp+40], rcx              ; buffer
    mov [rsp+48], rdx              ; length

    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    test rax, rax
    jz .fail
    cmp rax, -1
    je .fail

    mov [rsp+56], rax              ; handle
    mov qword [rsp+64], 0          ; bytes written

    mov rcx, [rsp+56]
    mov rdx, [rsp+40]
    mov r8,  [rsp+48]
    lea r9,  [rsp+64]
    ; [rsp+32] remains NULL for lpOverlapped
    call WriteFile
    test eax, eax
    jz .fail

    xor eax, eax
    add rsp, 72
    ret
.fail:
    mov eax, -1
    add rsp, 72
    ret

; ------------------------------------------------------------
; rosam_io_println
; ------------------------------------------------------------
global rosam_io_println
rosam_io_println:
    sub rsp, 72
    mov byte [rsp+40], 10
    mov qword [rsp+32], 0
    mov qword [rsp+48], 1

    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    test rax, rax
    jz .fail
    cmp rax, -1
    je .fail

    mov [rsp+56], rax
    mov qword [rsp+64], 0
    mov rcx, [rsp+56]
    lea rdx, [rsp+40]
    mov r8d, 1
    lea r9, [rsp+64]
    call WriteFile
    test eax, eax
    jz .fail

    xor eax, eax
    add rsp, 72
    ret
.fail:
    mov eax, -1
    add rsp, 72
    ret

; ------------------------------------------------------------
; rosam_io_input
; RCX = destination buffer
; EDX = capacity excluding NUL
; R8  = pointer to qword length output
; Return RAX = normalized input length; -1 on failure.
; ------------------------------------------------------------
global rosam_io_input
rosam_io_input:
    sub rsp, 88

    mov qword [rsp+32], 0          ; ReadFile arg #5: lpOverlapped = NULL
    mov [rsp+40], rcx              ; destination
    mov [rsp+48], rdx              ; capacity
    mov [rsp+56], r8               ; length pointer

    test edx, edx
    jz .fail
    mov ecx, STD_INPUT_HANDLE
    call GetStdHandle
    test rax, rax
    jz .fail
    cmp rax, -1
    je .fail

    mov [rsp+64], rax              ; handle
    mov qword [rsp+72], 0          ; bytes read

    mov rcx, [rsp+64]
    mov rdx, [rsp+40]
    mov r8d, dword [rsp+48]
    lea r9, [rsp+72]
    ; [rsp+32] stays NULL for lpOverlapped
    call ReadFile
    test eax, eax
    jz .fail

    mov r10d, dword [rsp+72]
    mov r11, [rsp+40]
    xor r9d, r9d

.scan:
    cmp r9d, r10d
    jae .terminate
    mov al, byte [r11+r9]
    cmp al, 10
    je .terminate
    cmp al, 13
    je .terminate
    inc r9
    jmp .scan

.terminate:
    mov byte [r11+r9], 0
    mov rax, r9
    mov r8, [rsp+56]
    test r8, r8
    jz .done
    mov [r8], r9
.done:
    add rsp, 88
    ret

.fail:
    mov r8, [rsp+56]
    test r8, r8
    jz .fail_no_len
    mov qword [r8], 0
.fail_no_len:
    mov rax, -1
    add rsp, 88
    ret

; ------------------------------------------------------------
; Internal: unsigned 32-bit integer to NUL-terminated decimal.
; EAX = value, RAX = pointer.
; ------------------------------------------------------------
rosam_rt_u32_to_cstr:
    lea r11, [rel rosam_win_int_buf+31]
    mov byte [r11], 0
    mov ecx, 10
.next:
    xor edx, edx
    div ecx
    add dl, '0'
    dec r11
    mov [r11], dl
    test eax, eax
    jnz .next
    mov rax, r11
    ret

; ------------------------------------------------------------
; rosam_io_input_i32
; RCX = pointer to i32 destination
; ------------------------------------------------------------
global rosam_io_input_i32
rosam_io_input_i32:
    sub rsp, 72
    mov [rsp+40], rcx

    lea rcx, [rel rosam_win_input_buf]
    mov edx, 4095
    lea r8, [rel rosam_win_input_len]
    call rosam_io_input
    cmp rax, -1
    je .fail

    lea r10, [rel rosam_win_input_buf]
    mov r11, rax
    xor eax, eax
    xor r9d, r9d
    xor r8d, r8d

    cmp r11, 0
    je .store
    cmp byte [r10], '-'
    jne .digits
    mov r8d, 1
    inc r9

.digits:
    cmp r9, r11
    jae .store
    movzx edx, byte [r10+r9]
    cmp edx, '0'
    jb .store
    cmp edx, '9'
    ja .store
    imul eax, eax, 10
    sub edx, '0'
    add eax, edx
    inc r9
    jmp .digits

.store:
    test r8d, r8d
    jz .write
    neg eax
.write:
    mov rcx, [rsp+40]
    mov dword [rcx], eax
    add rsp, 72
    ret
.fail:
    mov rcx, [rsp+40]
    mov dword [rcx], 0
    mov eax, -1
    add rsp, 72
    ret

; ------------------------------------------------------------
; rosam_io_print_i32
; RCX = pointer to i32
; ------------------------------------------------------------
global rosam_io_print_i32
rosam_io_print_i32:
    sub rsp, 72
    mov eax, dword [rcx]
    test eax, eax
    jns .positive
    neg eax
    mov dword [rsp+40], eax
    lea rcx, [rel rosam_win_minus]
    mov edx, 1
    call rosam_io_write_buf
    mov eax, dword [rsp+40]
.positive:
    call rosam_rt_u32_to_cstr
    mov rcx, rax
    call rosam_io_write_cstr_internal
    add rsp, 72
    ret

; ------------------------------------------------------------
; Internal C-string writer (only called from this backend).
; RCX = NUL-terminated string.
; ------------------------------------------------------------
rosam_io_write_cstr_internal:
    sub rsp, 72
    mov [rsp+40], rcx
    xor r10d, r10d
    mov r11, rcx
.scan:
    cmp byte [r11+r10], 0
    je .ready
    inc r10
    cmp r10, 0FFFFFFFFh
    jne .scan
    mov eax, -1
    add rsp, 72
    ret
.ready:
    mov rcx, [rsp+40]
    mov rdx, r10
    call rosam_io_write_buf
    add rsp, 72
    ret

; ------------------------------------------------------------
; rosam_io_print_i64
; RCX = pointer to i64
; ------------------------------------------------------------
global rosam_io_print_i64
rosam_io_print_i64:
    sub rsp, 72
    mov rax, qword [rcx]
    test rax, rax
    jns .positive
    neg rax
    mov qword [rsp+40], rax
    lea rcx, [rel rosam_win_minus]
    mov edx, 1
    call rosam_io_write_buf
    mov rax, qword [rsp+40]
.positive:
    lea r11, [rel rosam_win_int_buf+31]
    mov byte [r11], 0
    mov rcx, 10
.next:
    xor rdx, rdx
    div rcx
    add dl, '0'
    dec r11
    mov [r11], dl
    test rax, rax
    jnz .next
    mov rcx, r11
    call rosam_io_write_cstr_internal
    add rsp, 72
    ret

; ------------------------------------------------------------
; Basic i32 mutation API
; ------------------------------------------------------------
global rosam_set_i32
rosam_set_i32:
    mov dword [rcx], edx
    xor eax, eax
    ret

global rosam_copy_i32
rosam_copy_i32:
    mov eax, dword [rdx]
    mov dword [rcx], eax
    xor eax, eax
    ret

global rosam_zero_i32
rosam_zero_i32:
    mov dword [rcx], 0
    xor eax, eax
    ret

global rosam_i32_add
rosam_i32_add:
    mov eax, dword [rcx]
    add eax, dword [rdx]
    mov dword [rcx], eax
    xor eax, eax
    ret

global rosam_i32_sub
rosam_i32_sub:
    mov eax, dword [rcx]
    sub eax, dword [rdx]
    mov dword [rcx], eax
    xor eax, eax
    ret

global rosam_i32_mul
rosam_i32_mul:
    mov eax, dword [rcx]
    imul eax, dword [rdx]
    mov dword [rcx], eax
    xor eax, eax
    ret

global rosam_i32_div
rosam_i32_div:
    mov r10d, dword [rdx]
    test r10d, r10d
    jz .div0
    mov eax, dword [rcx]
    cdq
    idiv r10d
    mov dword [rcx], eax
    xor eax, eax
    ret
.div0:
    mov qword [rel rosam_win_error], 7
    mov eax, -1
    ret

global rosam_i32_mod
rosam_i32_mod:
    mov r10d, dword [rdx]
    test r10d, r10d
    jz .div0
    mov eax, dword [rcx]
    cdq
    idiv r10d
    mov dword [rcx], edx
    xor eax, eax
    ret
.div0:
    mov qword [rel rosam_win_error], 7
    mov eax, -1
    ret

; Basic i64 arithmetic.
global rosam_i64_add
rosam_i64_add:
    mov rax, qword [rcx]
    add rax, qword [rdx]
    mov qword [rcx], rax
    xor eax, eax
    ret

global rosam_i64_sub
rosam_i64_sub:
    mov rax, qword [rcx]
    sub rax, qword [rdx]
    mov qword [rcx], rax
    xor eax, eax
    ret

global rosam_i64_mul
rosam_i64_mul:
    mov rax, qword [rcx]
    imul rax, qword [rdx]
    mov qword [rcx], rax
    xor eax, eax
    ret

global rosam_i64_div
rosam_i64_div:
    mov r10, qword [rdx]
    test r10, r10
    jz .div0
    mov rax, qword [rcx]
    cqo
    idiv r10
    mov qword [rcx], rax
    xor eax, eax
    ret
.div0:
    mov qword [rel rosam_win_error], 7
    mov eax, -1
    ret

global rosam_i64_mod
rosam_i64_mod:
    mov r10, qword [rdx]
    test r10, r10
    jz .div0
    mov rax, qword [rcx]
    cqo
    idiv r10
    mov qword [rcx], rdx
    xor eax, eax
    ret
.div0:
    mov qword [rel rosam_win_error], 7
    mov eax, -1
    ret

; ------------------------------------------------------------
; Error API
; ------------------------------------------------------------
global rosam_error_clear
rosam_error_clear:
    mov qword [rel rosam_win_error], 0
    xor eax, eax
    ret

global rosam_error_set
rosam_error_set:
    mov qword [rel rosam_win_error], rcx
    xor eax, eax
    ret

global rosam_error_get
rosam_error_get:
    mov rax, qword [rel rosam_win_error]
    ret

global rosam_error_has
rosam_error_has:
    cmp qword [rel rosam_win_error], 0
    setne al
    movzx eax, al
    ret

global rosam_error_code
rosam_error_code:
    mov rax, qword [rel rosam_win_error]
    ret

; ------------------------------------------------------------
; Core string subset used by the public ROSAM API.
; ------------------------------------------------------------
global rosam_str_equal
rosam_str_equal:
    mov r8, rcx
    mov r9, rdx
.eq_loop:
    mov al, byte [r8]
    mov r10b, byte [r9]
    cmp al, r10b
    jne .eq_false
    test al, al
    je .eq_true
    inc r8
    inc r9
    jmp .eq_loop
.eq_true:
    mov eax, 1
    ret
.eq_false:
    xor eax, eax
    ret

global rosam_str_copy
rosam_str_copy:
    mov r8, rcx
    mov r9, rdx
.copy_loop:
    mov al, byte [r9]
    mov byte [r8], al
    inc r8
    inc r9
    test al, al
    jne .copy_loop
    xor eax, eax
    ret

; ------------------------------------------------------------
; Process API
; ------------------------------------------------------------
global rosam_process_exit
rosam_process_exit:
    sub rsp, 40
    mov ecx, ecx
    call ExitProcess
    ud2

%endif
