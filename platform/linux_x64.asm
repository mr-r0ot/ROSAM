%ifndef ROSAM_PLATFORM_LINUX_X64_INCLUDED
%define ROSAM_PLATFORM_LINUX_X64_INCLUDED 1

BITS 64
default rel

; -----------------------------------------------------------------------------
; ROSAM Linux x86-64 backend
;
; Public ROSAM API uses ROSAM's private logical argument convention:
;   arg1 -> RCX
;   arg2 -> RDX
;   arg3 -> R8
;
; These adapter macros translate that convention into calls to the local
; ROSAM runtime. No C ABI or libc dependency is required.
;
; Linux x86-64 system calls use:
;   syscall number -> RAX
;   args 1..6     -> RDI, RSI, RDX, R10, R8, R9
;   return         -> RAX
; and SYSCALL clobbers RCX and R11.
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Generic call adapters
; At a normal SysV function entry RSP % 16 == 8. Subtracting 8 aligns the
; stack before a nested CALL. The runtime functions themselves do not call libc.
; -----------------------------------------------------------------------------

%macro ROSAM_CALL0 1
    sub rsp, 8
    call %1
    add rsp, 8
%endmacro

%macro ROSAM_ADDR_CALL1 2
    sub rsp, 8
    lea rcx, [rel %2]
    call %1
    add rsp, 8
%endmacro

%macro ROSAM_VALUE_CALL1 2
    sub rsp, 8
    mov rcx, %2
    call %1
    add rsp, 8
%endmacro

%macro ROSAM_ADDR_ADDR_CALL2 3
    sub rsp, 8
    lea rcx, [rel %2]
    lea rdx, [rel %3]
    call %1
    add rsp, 8
%endmacro

%macro ROSAM_ADDR_IMM_CALL2 3
    sub rsp, 8
    lea rcx, [rel %2]
    mov edx, %3
    call %1
    add rsp, 8
%endmacro

%macro ROSAM_ADDR_MEM_CALL2 3
    sub rsp, 8
    lea rcx, [rel %2]
    mov rdx, qword [rel %3]
    call %1
    add rsp, 8
%endmacro

%macro ROSAM_ADDR_IMM_ADDR_CALL3 4
    sub rsp, 8
    lea rcx, [rel %2]
    mov edx, %3
    lea r8, [rel %4]
    call %1
    add rsp, 8
%endmacro

%macro ROSAM_ADDR_ADDR_VALUE_CALL2 3
    sub rsp, 8
    lea rcx, [rel %2]
    lea rdx, [rel %3]
    call %1
    add rsp, 8
%endmacro

%macro ROSAM_STR_EQUAL_BRANCH 3
    sub rsp, 8
    lea rcx, [rel %1]
    lea rdx, [rel %2]
    call rosam_str_equal
    add rsp, 8
    test eax, eax
    jnz %3
%endmacro

%macro ROSAM_STR_EQUAL_STORE 3
    sub rsp, 8
    lea rcx, [rel %2]
    lea rdx, [rel %3]
    call rosam_str_equal
    add rsp, 8
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
    sub rsp, 8
    mov ecx, %1
    call rosam_process_exit
    add rsp, 8
    ud2
%endmacro

; -----------------------------------------------------------------------------
; Control-flow adapters
; -----------------------------------------------------------------------------

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

; -----------------------------------------------------------------------------
; Linux syscall numbers (x86-64)
; -----------------------------------------------------------------------------
%define SYS_READ       0
%define SYS_WRITE      1
%define SYS_CLOSE      3
%define SYS_MMAP       9
%define SYS_MUNMAP     11
%define SYS_EXIT       60

%define PROT_READ      1
%define PROT_WRITE     2
%define MAP_PRIVATE    2
%define MAP_ANONYMOUS  32

%ifndef ROSAM_ERR_NONE
%define ROSAM_ERR_NONE               0
%endif
%ifndef ROSAM_ERR_INVALID_ARGUMENT
%define ROSAM_ERR_INVALID_ARGUMENT   1
%endif
%ifndef ROSAM_ERR_NULL
%define ROSAM_ERR_NULL              2
%endif
%ifndef ROSAM_ERR_OVERFLOW
%define ROSAM_ERR_OVERFLOW          3
%endif
%ifndef ROSAM_ERR_UNDERFLOW
%define ROSAM_ERR_UNDERFLOW         4
%endif
%ifndef ROSAM_ERR_OUT_OF_MEMORY
%define ROSAM_ERR_OUT_OF_MEMORY     5
%endif
%ifndef ROSAM_ERR_OUT_OF_RANGE
%define ROSAM_ERR_OUT_OF_RANGE      6
%endif
%ifndef ROSAM_ERR_DIV_ZERO
%define ROSAM_ERR_DIV_ZERO          7
%endif
%ifndef ROSAM_ERR_PARSE
%define ROSAM_ERR_PARSE             8
%endif
%ifndef ROSAM_ERR_ENCODING
%define ROSAM_ERR_ENCODING          9
%endif
%ifndef ROSAM_ERR_NOT_FOUND
%define ROSAM_ERR_NOT_FOUND         10
%endif
%ifndef ROSAM_ERR_UNSUPPORTED
%define ROSAM_ERR_UNSUPPORTED       11
%endif
%ifndef ROSAM_ERR_IO
%define ROSAM_ERR_IO                12
%endif
%ifndef ROSAM_ERR_INVALID_STATE
%define ROSAM_ERR_INVALID_STATE     13
%endif

section .data
align 1
rosam_linux_minus: db '-'

section .bss
align 8
rosam_linux_input_buf: resb 4096
rosam_linux_input_len: resq 1
rosam_linux_int_buf:   resb 32
rosam_linux_error:     resq 1
rosam_rng_state:       resq 1

section .text

; -----------------------------------------------------------------------------
; Internal helpers
; -----------------------------------------------------------------------------

; Return true when RAX is a Linux syscall error (-4095..-1).
rosam_linux_is_error:
    cmp rax, -4095
    jae near .yes
    xor eax, eax
    ret
.yes:
    mov eax, 1
    ret

; RAX = unsigned 64-bit value
; Return RAX = pointer to NUL-terminated decimal in rosam_linux_int_buf.
rosam_linux_u64_to_cstr:
    lea r11, [rel rosam_linux_int_buf + 31]
    mov byte [r11], 0
    mov ecx, 10
.next:
    xor edx, edx
    div rcx
    add dl, '0'
    dec r11
    mov [r11], dl
    test rax, rax
    jnz near .next
    mov rax, r11
    ret

; RCX = NUL terminated string -> writes it.
rosam_linux_write_cstr:
    sub rsp, 8
    mov r11, rcx
    xor edx, edx
.scan:
    cmp byte [r11+rdx], 0
    je near .ready
    inc rdx
    jmp near .scan
.ready:
    mov rcx, r11
    call rosam_io_write_buf
    add rsp, 8
    ret

; -----------------------------------------------------------------------------
; Console I/O
; -----------------------------------------------------------------------------

global rosam_io_write_buf
rosam_io_write_buf:
    ; ROSAM convention: RCX=buffer, RDX=length
    mov rsi, rcx
    mov rdx, rdx
    mov eax, SYS_WRITE
    mov edi, 1
    syscall
    ; return 0 on success, -1 on syscall failure
    test rax, rax
    js near .fail
    xor eax, eax
    ret
.fail:
    mov qword [rel rosam_linux_error], ROSAM_ERR_IO
    mov eax, -1
    ret


global rosam_io_println
rosam_io_println:
    sub rsp, 8
    mov byte [rsp], 10
    mov rcx, rsp
    mov edx, 1
    call rosam_io_write_buf
    add rsp, 8
    ret


global rosam_io_input
rosam_io_input:
    ; RCX=destination, EDX=capacity excluding NUL, R8=len output pointer
    test edx, edx
    jz near .fail

    ; stdin -> destination. Read at most capacity bytes, leaving one byte for NUL.
    mov r9, rcx
    mov r10d, edx
    dec r10d
    mov eax, SYS_READ
    xor edi, edi
    mov rsi, r9
    mov edx, r10d
    syscall
    test rax, rax
    js near .fail

    mov r11, rax
    xor r10d, r10d
.scan:
    cmp r10, r11
    jae near .terminate
    mov al, byte [r9+r10]
    cmp al, 10
    je near .terminate
    cmp al, 13
    je near .terminate
    inc r10
    jmp near .scan

.terminate:
    mov byte [r9+r10], 0
    test r8, r8
    jz near .return_len
    mov [r8], r10
.return_len:
    mov rax, r10
    ret

.fail:
    mov qword [rel rosam_linux_error], ROSAM_ERR_IO
    test r8, r8
    jz near .fail_no_len
    mov qword [r8], 0
.fail_no_len:
    mov rax, -1
    ret


global rosam_io_input_i32
rosam_io_input_i32:
    sub rsp,24
    mov [rsp],rcx
    lea rcx,[rel rosam_linux_input_buf]
    mov edx,4096
    lea r8,[rel rosam_linux_input_len]
    call rosam_io_input
    test rax,rax
    js near .fail
    mov r11,rax
    lea r10,[rel rosam_linux_input_buf]
    xor eax,eax
    xor r9d,r9d
    xor r8d,r8d
    test r11,r11
    jz near .store
    cmp byte [r10],'-'
    jne near .digits
    mov r8d,1
    mov r9d,1
.digits:
    cmp r9,r11
    jae near .store
    movzx edx,byte [r10+r9]
    cmp edx,'0'
    jb near .store
    cmp edx,'9'
    ja near .store
    imul eax,eax,10
    sub edx,'0'
    add eax,edx
    inc r9
    jmp near .digits
.store:
    test r8d,r8d
    jz near .write
    neg eax
.write:
    mov rcx,[rsp]
    mov [rcx],eax
    add rsp,24
    ret
.fail:
    mov rcx,[rsp]
    mov dword [rcx],0
    mov eax,-1
    add rsp,24
    ret


global rosam_io_print_i32
rosam_io_print_i32:
    sub rsp,24
    mov eax,[rcx]
    test eax,eax
    jns near .positive
    neg eax
    mov [rsp],eax
    lea rcx,[rel rosam_linux_minus]
    mov edx,1
    call rosam_io_write_buf
    mov eax,[rsp]
.positive:
    lea r11,[rel rosam_linux_int_buf+31]
    mov byte [r11],0
    mov r10d,10
.convert:
    xor edx,edx
    div r10d
    add dl,'0'
    dec r11
    mov [r11],dl
    test eax,eax
    jnz near .convert
    mov rcx,r11
    call rosam_linux_write_cstr
    add rsp,24
    ret


global rosam_io_print_i64
rosam_io_print_i64:
    sub rsp,24
    mov rax,[rcx]
    test rax,rax
    jns near .positive
    neg rax
    mov [rsp],rax
    lea rcx,[rel rosam_linux_minus]
    mov edx,1
    call rosam_io_write_buf
    mov rax,[rsp]
.positive:
    lea r11,[rel rosam_linux_int_buf+31]
    mov byte [r11],0
    mov r10,10
.convert:
    xor rdx,rdx
    div r10
    add dl,'0'
    dec r11
    mov [r11],dl
    test rax,rax
    jnz near .convert
    mov rcx,r11
    call rosam_linux_write_cstr
    add rsp,24
    ret


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
    jz near .div0
    mov eax, dword [rcx]
    cmp eax, 0x80000000
    jne near .normal
    cmp r10d, -1
    je near .overflow
.normal:
    cdq
    idiv r10d
    mov dword [rcx], eax
    xor eax, eax
    ret
.div0:
    mov qword [rel rosam_linux_error], ROSAM_ERR_DIV_ZERO
    mov eax, -1
    ret
.overflow:
    mov qword [rel rosam_linux_error], ROSAM_ERR_OVERFLOW
    mov eax, -1
    ret

global rosam_i32_mod
rosam_i32_mod:
    mov r10d, dword [rdx]
    test r10d, r10d
    jz near .div0
    mov eax, dword [rcx]
    cmp eax, 0x80000000
    jne near .normal
    cmp r10d, -1
    je near .overflow
.normal:
    cdq
    idiv r10d
    mov dword [rcx], edx
    xor eax, eax
    ret
.div0:
    mov qword [rel rosam_linux_error], ROSAM_ERR_DIV_ZERO
    mov eax, -1
    ret
.overflow:
    mov qword [rel rosam_linux_error], ROSAM_ERR_OVERFLOW
    mov eax, -1
    ret

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
    jz near .div0
    mov rax, qword [rcx]
    mov r11, 0x8000000000000000
    cmp rax, r11
    jne near .normal
    cmp r10, -1
    je near .overflow
.normal:
    cqo
    idiv r10
    mov qword [rcx], rax
    xor eax, eax
    ret
.div0:
    mov qword [rel rosam_linux_error], ROSAM_ERR_DIV_ZERO
    mov eax, -1
    ret
.overflow:
    mov qword [rel rosam_linux_error], ROSAM_ERR_OVERFLOW
    mov eax, -1
    ret

global rosam_i64_mod
rosam_i64_mod:
    mov r10, qword [rdx]
    test r10, r10
    jz near .div0
    mov rax, qword [rcx]
    mov r11, 0x8000000000000000
    cmp rax, r11
    jne near .normal
    cmp r10, -1
    je near .overflow
.normal:
    cqo
    idiv r10
    mov qword [rcx], rdx
    xor eax, eax
    ret
.div0:
    mov qword [rel rosam_linux_error], ROSAM_ERR_DIV_ZERO
    mov eax, -1
    ret
.overflow:
    mov qword [rel rosam_linux_error], ROSAM_ERR_OVERFLOW
    mov eax, -1
    ret

; -----------------------------------------------------------------------------
; Error API
; -----------------------------------------------------------------------------

global rosam_error_clear
rosam_error_clear:
    mov qword [rel rosam_linux_error], 0
    xor eax, eax
    ret

global rosam_error_set
rosam_error_set:
    mov qword [rel rosam_linux_error], rcx
    xor eax, eax
    ret

global rosam_error_get
rosam_error_get:
    mov rax, qword [rel rosam_linux_error]
    ret

global rosam_error_has
rosam_error_has:
    cmp qword [rel rosam_linux_error], 0
    setne al
    movzx eax, al
    ret

global rosam_error_code
rosam_error_code:
    mov rax, qword [rel rosam_linux_error]
    ret

; -----------------------------------------------------------------------------
; String subset used by v0.6.1
; -----------------------------------------------------------------------------

global rosam_str_equal
rosam_str_equal:
    mov r8, rcx
    mov r9, rdx
.eq_loop:
    mov al, byte [r8]
    cmp al, byte [r9]
    jne near .false
    test al, al
    je near .true
    inc r8
    inc r9
    jmp near .eq_loop
.true:
    mov eax, 1
    ret
.false:
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
    jne near .copy_loop
    xor eax, eax
    ret

; -----------------------------------------------------------------------------
; Process exit
; -----------------------------------------------------------------------------

global rosam_process_exit
rosam_process_exit:
    mov eax, SYS_EXIT
    mov edi, ecx
    syscall
    ud2



; ============================================================================
; ROSAM v0.6.1 COMPLETE CORE IMPLEMENTATION - Linux x86-64
; All extern symbols declared by core/*.inc are defined below.
; Core API is implemented without Linux-specific behavior leaking into macros.
; libc/libm are used for mature C/POSIX primitives; console/exit/random use
; native Linux x86-64 syscalls.
; Build: nasm -f elf64 ... && gcc -m64 ... -lm
; ============================================================================


section .rodata
rosam_linux_true:  db 'true',0
rosam_linux_false: db 'false',0
rosam_linux_fmt_g:  db '%g',0
rosam_linux_fmt_gp: db '%.*g',0
rosam_linux_err_none: db 'none',0
rosam_linux_err_invalid: db 'invalid argument',0
rosam_linux_err_null: db 'null pointer',0
rosam_linux_err_overflow: db 'overflow',0
rosam_linux_err_underflow: db 'underflow',0
rosam_linux_err_oom: db 'out of memory',0
rosam_linux_err_range: db 'out of range',0
rosam_linux_err_div0: db 'division by zero',0
rosam_linux_err_parse: db 'parse error',0
rosam_linux_err_encoding: db 'encoding error',0
rosam_linux_err_notfound: db 'not found',0
rosam_linux_err_unsupported: db 'unsupported',0
rosam_linux_err_io: db 'I/O error',0
rosam_linux_err_state: db 'invalid state',0


extern malloc
extern calloc
extern realloc
extern free
extern memcpy
extern memmove
extern memset
extern memcmp
extern memchr
extern strlen
extern strnlen
extern strcmp
extern strncmp
extern strchr
extern strrchr
extern strstr
extern snprintf
extern sqrt
extern cbrt
extern sin
extern cos
extern tan
extern asin
extern acos
extern atan
extern atan2
extern sinh
extern cosh
extern tanh
extern exp
extern log
extern log10
extern log2
extern pow
extern floor
extern ceil
extern round
extern trunc


global rosam_error_name
rosam_error_name:
    lea rax,[rel rosam_linux_err_none]
    cmp rcx,ROSAM_ERR_NONE
    je near .ret
    lea rax,[rel rosam_linux_err_invalid]
    cmp rcx,ROSAM_ERR_INVALID_ARGUMENT
    je near .ret
    lea rax,[rel rosam_linux_err_null]
    cmp rcx,ROSAM_ERR_NULL
    je near .ret
    lea rax,[rel rosam_linux_err_overflow]
    cmp rcx,ROSAM_ERR_OVERFLOW
    je near .ret
    lea rax,[rel rosam_linux_err_underflow]
    cmp rcx,ROSAM_ERR_UNDERFLOW
    je near .ret
    lea rax,[rel rosam_linux_err_oom]
    cmp rcx,ROSAM_ERR_OUT_OF_MEMORY
    je near .ret
    lea rax,[rel rosam_linux_err_range]
    cmp rcx,ROSAM_ERR_OUT_OF_RANGE
    je near .ret
    lea rax,[rel rosam_linux_err_div0]
    cmp rcx,ROSAM_ERR_DIV_ZERO
    je near .ret
    lea rax,[rel rosam_linux_err_parse]
    cmp rcx,ROSAM_ERR_PARSE
    je near .ret
    lea rax,[rel rosam_linux_err_encoding]
    cmp rcx,ROSAM_ERR_ENCODING
    je near .ret
    lea rax,[rel rosam_linux_err_notfound]
    cmp rcx,ROSAM_ERR_NOT_FOUND
    je near .ret
    lea rax,[rel rosam_linux_err_unsupported]
    cmp rcx,ROSAM_ERR_UNSUPPORTED
    je near .ret
    lea rax,[rel rosam_linux_err_io]
    cmp rcx,ROSAM_ERR_IO
    je near .ret
    lea rax,[rel rosam_linux_err_state]
.ret:
    ret


global rosam_error_message
rosam_error_message:
    mov rcx,[rel rosam_linux_error]
    jmp near rosam_error_name


global rosam_mem_copy
rosam_mem_copy:
    test rcx,rcx
    jz near .bad
    sub rsp,8
    mov [rsp],rcx
    mov rdi,rcx
    mov rsi,rdx
    mov rdx,r8
    call memcpy
    mov rax,[rsp]
    add rsp,8
    ret
.bad:
    mov qword [rel rosam_linux_error],ROSAM_ERR_NULL
    xor eax,eax
    ret


global rosam_mem_move
rosam_mem_move:
    test rcx,rcx
    jz near .bad
    sub rsp,8
    mov [rsp],rcx
    mov rdi,rcx
    mov rsi,rdx
    mov rdx,r8
    call memmove
    mov rax,[rsp]
    add rsp,8
    ret
.bad:
    mov qword [rel rosam_linux_error],ROSAM_ERR_NULL
    xor eax,eax
    ret


global rosam_mem_set
rosam_mem_set:
    test rcx,rcx
    jz near .bad
    sub rsp,8
    mov [rsp],rcx
    mov rdi,rcx
    mov esi,edx
    mov rdx,r8
    call memset
    mov rax,[rsp]
    add rsp,8
    ret
.bad:
    mov qword [rel rosam_linux_error],ROSAM_ERR_NULL
    xor eax,eax
    ret


global rosam_mem_zero
rosam_mem_zero:
    test rcx,rcx
    jz near .bad
    sub rsp,8
    mov [rsp],rcx
    mov rdi,rcx
    xor esi,esi
    mov rdx,rdx
    call memset
    mov rax,[rsp]
    add rsp,8
    ret
.bad:
    mov qword [rel rosam_linux_error],ROSAM_ERR_NULL
    xor eax,eax
    ret


global rosam_mem_compare
rosam_mem_compare:
    mov rdi,rcx
    mov rsi,rdx
    mov rdx,r8
    sub rsp,8
    call memcmp
    add rsp,8
    ret


global rosam_mem_equal
rosam_mem_equal:
    sub rsp,8
    call rosam_mem_compare
    add rsp,8
    test eax,eax
    setz al
    movzx eax,al
    ret


global rosam_mem_find
rosam_mem_find:
    mov rdi,rcx
    mov esi,edx
    mov rdx,r8
    sub rsp,8
    call memchr
    add rsp,8
    ret


global rosam_mem_alloc
rosam_mem_alloc:
    mov rdi,rcx
    sub rsp,8
    call malloc
    add rsp,8
    test rax,rax
    jnz near .ok
    mov qword [rel rosam_linux_error],ROSAM_ERR_OUT_OF_MEMORY
.ok: ret


global rosam_mem_calloc
rosam_mem_calloc:
    mov rdi,rcx
    mov rsi,rdx
    sub rsp,8
    call calloc
    add rsp,8
    test rax,rax
    jnz near .ok
    mov qword [rel rosam_linux_error],ROSAM_ERR_OUT_OF_MEMORY
.ok: ret


global rosam_mem_realloc
rosam_mem_realloc:
    mov rdi,rcx
    mov rsi,rdx
    sub rsp,8
    call realloc
    add rsp,8
    test rax,rax
    jnz near .ok
    mov qword [rel rosam_linux_error],ROSAM_ERR_OUT_OF_MEMORY
.ok: ret


global rosam_mem_free
rosam_mem_free:
    mov rdi,rcx
    sub rsp,8
    call free
    add rsp,8
    xor eax,eax
    ret


global rosam_str_len
rosam_str_len:
    mov rdi,rcx
    sub rsp,8
    call strlen
    add rsp,8
    ret


global rosam_str_nlen
rosam_str_nlen:
    mov rdi,rcx
    mov rsi,rdx
    sub rsp,8
    call strnlen
    add rsp,8
    ret


global rosam_str_copy_n
rosam_str_copy_n:
    test rcx,rcx
    jz near .bad
    mov r10,r8
    sub rsp,24
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    test r10,r10
    jz near .empty
    mov rdi,rdx
    call strlen
    cmp rax,r10
    cmova rax,r10
    mov r11,rax
    mov rdi,[rsp+8]
    mov rsi,[rsp+16]
    mov rdx,r11
    call memmove
    mov rcx,[rsp+8]
    mov byte [rcx+r11],0
    mov rax,rcx
    add rsp,24
    ret
.empty:
    mov rcx,[rsp+8]
    mov byte [rcx],0
    mov rax,rcx
    add rsp,24
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_NULL
    xor eax,eax
    ret


global rosam_str_compare
rosam_str_compare:
    mov rdi,rcx
    mov rsi,rdx
    sub rsp,8
    call strcmp
    add rsp,8
    ret


global rosam_str_compare_n
rosam_str_compare_n:
    mov rdi,rcx
    mov rsi,rdx
    mov rdx,r8
    sub rsp,8
    call strncmp
    add rsp,8
    ret


global rosam_str_equal_n
rosam_str_equal_n:
    call rosam_str_compare_n
    test eax,eax
    setz al
    movzx eax,al
    ret


global rosam_str_char
rosam_str_char:
    mov rdi,rcx
    mov esi,edx
    sub rsp,8
    call strchr
    add rsp,8
    ret


global rosam_str_char_last
rosam_str_char_last:
    mov rdi,rcx
    mov esi,edx
    sub rsp,8
    call strrchr
    add rsp,8
    ret


global rosam_str_find
rosam_str_find:
    mov rdi,rcx
    mov rsi,rdx
    sub rsp,8
    call strstr
    add rsp,8
    ret


global rosam_str_contains
rosam_str_contains:
    sub rsp,8
    call rosam_str_find
    add rsp,8
    test rax,rax
    setnz al
    movzx eax,al
    ret


global rosam_str_equal_ignorecase
rosam_str_equal_ignorecase:
    test rcx,rcx
    jz near .no
    test rdx,rdx
    jz near .no
.loop:
    mov al,[rcx]
    mov r8b,[rdx]
    cmp al,0
    jne near .a
    test r8b,r8b
    jz near .yes
.a:
    call rosam_ascii_to_lower_byte
    mov r9b,al
    mov al,r8b
    call rosam_ascii_to_lower_byte
    cmp r9b,al
    jne near .no
    inc rcx
    inc rdx
    jmp near .loop
.yes: mov eax,1; ret
.no: xor eax,eax; ret


global rosam_str_concat
rosam_str_concat:
    test rcx,rcx
    jz near .bad
    test rdx,rdx
    jz near .bad
    sub rsp,40
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov rdi,rcx
    call strlen
    mov [rsp+24],rax
    mov rdi,[rsp+16]
    call strlen
    mov rdi,[rsp+8]
    add rdi,[rsp+24]
    mov rsi,[rsp+16]
    inc rax
    mov rdx,rax
    call memcpy
    mov rax,[rsp+8]
    add rsp,40
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_NULL
    xor eax,eax
    ret


global rosam_str_concat_n
rosam_str_concat_n:
    test rcx,rcx
    jz near .bad
    test rdx,rdx
    jz near .bad
    sub rsp,48
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov [rsp+24],r8
    mov rdi,rcx
    call strlen
    mov [rsp+32],rax
    mov rdi,[rsp+16]
    call strlen
    mov r8,rax
    mov r9,[rsp+24]
    cmp r8,r9
    jbe near .len_ok
    mov r8,r9
.len_ok:
    mov rdi,[rsp+8]
    add rdi,[rsp+32]
    mov rsi,[rsp+16]
    mov rdx,r8
    call memcpy
    mov rcx,[rsp+8]
    mov rax,[rsp+32]
    add rax,r8
    mov byte [rcx+rax],0
    mov rax,rcx
    add rsp,48
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_NULL
    xor eax,eax
    ret


global rosam_str_prefix
rosam_str_prefix:
    test rcx,rcx
    jz near .no
    test rdx,rdx
    jz near .no
    sub rsp,40
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov rdi,rcx
    call strlen
    mov [rsp+24],rax
    mov rdi,[rsp+16]
    call strlen
    mov [rsp+32],rax
    mov rax,[rsp+32]
    cmp rax,[rsp+24]
    ja near .no_cleanup
    mov rdx,rax
    mov rdi,[rsp+8]
    mov rsi,[rsp+16]
    call strncmp
    test eax,eax
    setz al
    movzx eax,al
    add rsp,40
    ret
.no_cleanup:
    add rsp,40
.no:
    xor eax,eax
    ret


global rosam_str_suffix
rosam_str_suffix:
    test rcx,rcx
    jz near .no
    test rdx,rdx
    jz near .no
    sub rsp,40
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov rdi,rcx
    call strlen
    mov [rsp+24],rax
    mov rdi,[rsp+16]
    call strlen
    mov [rsp+32],rax
    mov r9,[rsp+32]
    cmp r9,[rsp+24]
    ja near .no_cleanup
    mov r10,[rsp+24]
    sub r10,r9
    mov rdi,[rsp+8]
    add rdi,r10
    mov rsi,[rsp+16]
    mov rdx,r9
    call strncmp
    test eax,eax
    setz al
    movzx eax,al
    add rsp,40
    ret
.no_cleanup:
    add rsp,40
.no:
    xor eax,eax
    ret


global rosam_str_reverse
rosam_str_reverse:
    test rcx,rcx
    jz near .bad
    sub rsp,24
    mov [rsp+8],rcx
    mov rdi,rcx
    call strlen
    test rax,rax
    jz near .done
    mov r8,[rsp+8]
    lea r9,[r8+rax-1]
.loop:
    cmp r8,r9
    jae near .done
    mov al,[r8]
    mov dl,[r9]
    mov [r8],dl
    mov [r9],al
    inc r8
    dec r9
    jmp near .loop
.done:
    mov rax,[rsp+8]
    add rsp,24
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_NULL
    xor eax,eax
    ret


global rosam_str_to_upper
rosam_str_to_upper:
    mov r8,rcx
.loop:
    mov al,[r8]
    test al,al
    jz near .done
    cmp al,'a'
    jb near .next
    cmp al,'z'
    ja near .next
    sub al,32
    mov [r8],al
.next: inc r8; jmp .loop
.done: mov rax,rcx; ret


global rosam_str_to_lower
rosam_str_to_lower:
    mov r8,rcx
.loop:
    mov al,[r8]
    test al,al
    jz near .done
    cmp al,'A'
    jb near .next
    cmp al,'Z'
    ja near .next
    add al,32
    mov [r8],al
.next: inc r8; jmp .loop
.done: mov rax,rcx; ret


global rosam_str_trim_left
rosam_str_trim_left:
    test rcx,rcx
    jz near .bad
    sub rsp,24
    mov [rsp+8],rcx
    mov r8,rcx
.scan:
    mov al,[r8]
    test al,al
    jz near .empty
    cmp al,' '
    je near .skip
    cmp al,9
    je near .skip
    cmp al,10
    je near .skip
    cmp al,13
    je near .skip
    jmp near .move
.skip:
    inc r8
    jmp near .scan
.move:
    cmp r8,rcx
    je near .done
    mov rdi,r8
    call strlen
    inc rax
    mov rdx,rax
    mov rdi,rcx
    mov rsi,r8
    call memmove
.done:
    mov rax,[rsp+8]
    add rsp,24
    ret
.empty:
    mov byte [rcx],0
    mov rax,[rsp+8]
    add rsp,24
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_NULL
    xor eax,eax
    ret


global rosam_str_trim_right
rosam_str_trim_right:
    test rcx,rcx
    jz near .bad
    sub rsp,24
    mov [rsp+8],rcx
    mov rdi,rcx
    call strlen
    test rax,rax
    jz near .done
    mov r8,[rsp+8]
    lea r9,[r8+rax-1]
.loop:
    mov al,[r9]
    cmp al,' '
    je near .cut
    cmp al,9
    je near .cut
    cmp al,10
    je near .cut
    cmp al,13
    je near .cut
    jmp near .done
.cut:
    mov byte [r9],0
    cmp r9,r8
    je near .done
    dec r9
    jmp near .loop
.done:
    mov rax,[rsp+8]
    add rsp,24
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_NULL
    xor eax,eax
    ret


global rosam_str_trim
rosam_str_trim:
    sub rsp,8
    call rosam_str_trim_left
    add rsp,8
    mov rcx,rax
    jmp near rosam_str_trim_right


global rosam_str_replace_char
rosam_str_replace_char:
    ; RCX=string RDX=old char R8=new char
    mov r9b,dl
    mov r10b,r8b
.loop: mov al,[rcx]
    test al,al
    jz near .done
    cmp al,r9b
    jne near .next
    mov [rcx],r10b
.next: inc rcx; jmp .loop
.done: xor eax,eax; ret


global rosam_str_count_char
rosam_str_count_char:
    mov r8b,dl
    xor eax,eax
.loop: mov dl,[rcx]
    test dl,dl
    jz near .done
    cmp dl,r8b
    jne near .next
    inc eax
.next: inc rcx; jmp .loop
.done: ret


global rosam_str_count_substr
rosam_str_count_substr:
    test rcx,rcx
    jz near .done_zero
    test rdx,rdx
    jz near .done_zero
    sub rsp,40
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov qword [rsp+24],0
.loop:
    mov rdi,[rsp+8]
    mov rsi,[rsp+16]
    call strstr
    test rax,rax
    jz near .done
    inc qword [rsp+24]
    lea rcx,[rax+1]
    mov [rsp+8],rcx
    jmp near .loop
.done:
    mov rax,[rsp+24]
    add rsp,40
    ret
.done_zero:
    xor eax,eax
    ret


global rosam_str_duplicate
rosam_str_duplicate:
    test rcx,rcx
    jz near .bad
    sub rsp,40
    mov [rsp+8],rcx
    mov rdi,rcx
    call strlen
    inc rax
    mov [rsp+16],rax
    mov rdi,rax
    call malloc
    test rax,rax
    jz near .oom
    mov [rsp+24],rax
    mov rdi,rax
    mov rsi,[rsp+8]
    mov rdx,[rsp+16]
    call memcpy
    mov rax,[rsp+24]
    add rsp,40
    ret
.oom:
    mov qword [rel rosam_linux_error],ROSAM_ERR_OUT_OF_MEMORY
    add rsp,40
    xor eax,eax
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_NULL
    xor eax,eax
    ret


global rosam_str_duplicate_n
rosam_str_duplicate_n:
    test rcx,rcx
    jz near .bad
    sub rsp,40
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov rdi,rcx
    call strlen
    mov r9,[rsp+16]
    cmp rax,r9
    cmova r9,rax
    mov [rsp+24],r9
    inc r9
    mov [rsp+32],r9
    mov rdi,r9
    call malloc
    test rax,rax
    jz near .oom
    mov rcx,rax
    mov rdi,rcx
    mov rsi,[rsp+8]
    mov rdx,[rsp+24]
    call memcpy
    mov r9,[rsp+24]
    mov byte [rcx+r9],0
    mov rax,rcx
    add rsp,40
    ret
.oom:
    mov qword [rel rosam_linux_error],ROSAM_ERR_OUT_OF_MEMORY
    add rsp,40
    xor eax,eax
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_NULL
    xor eax,eax
    ret


global rosam_ascii_is_alpha
rosam_ascii_is_alpha:
    mov al,cl
    or al,32
    cmp al,'a'
    jb near .no
    cmp al,'z'
    ja near .no
    mov eax,1
    ret
.no: xor eax,eax; ret


global rosam_ascii_is_digit
rosam_ascii_is_digit:
    cmp cl,'0'
    jb near .no
    cmp cl,'9'
    ja near .no
    mov eax,1
    ret
.no: xor eax,eax; ret


global rosam_ascii_is_alnum
rosam_ascii_is_alnum:
    mov al,cl
    or al,32
    cmp al,'a'
    jb near .digit
    cmp al,'z'
    jbe near .yes
.digit: cmp cl,'0'; jb .no; cmp cl,'9'; ja .no
.yes: mov eax,1; ret
.no: xor eax,eax; ret


global rosam_ascii_is_space
rosam_ascii_is_space:
    cmp cl,' '; je .yes
    cmp cl,9; je .yes
    cmp cl,10; je .yes
    cmp cl,13; je .yes
    xor eax,eax; ret
.yes: mov eax,1; ret


global rosam_ascii_is_upper
rosam_ascii_is_upper:
    cmp cl,'A'; jb .no; cmp cl,'Z'; ja .no; mov eax,1; ret
.no: xor eax,eax; ret


global rosam_ascii_is_lower
rosam_ascii_is_lower:
    cmp cl,'a'; jb .no; cmp cl,'z'; ja .no; mov eax,1; ret
.no: xor eax,eax; ret


global rosam_ascii_to_upper
rosam_ascii_to_upper:
    mov al,cl
    cmp al,'a'; jb .ret
    cmp al,'z'; ja .ret
    sub al,32
.ret: movzx eax,al; ret



global rosam_ascii_to_lower_byte
rosam_ascii_to_lower_byte:
    cmp al,'A'
    jb .ret
    cmp al,'Z'
    ja .ret
    add al,32
.ret:
    ret

global rosam_ascii_to_lower
rosam_ascii_to_lower:
    mov al,cl
    call rosam_ascii_to_lower_byte
    movzx eax,al
    ret


global rosam_utf8_len
rosam_utf8_len:
    jmp near rosam_str_len


global rosam_utf8_char_count
rosam_utf8_char_count:
    test rcx,rcx
    jz near .bad
    sub rsp,40
    mov [rsp+8],rcx
    mov qword [rsp+16],0
.loop:
    mov rcx,[rsp+8]
    movzx eax,byte [rcx]
    test al,al
    jz near .done
    call rosam_utf8_decode
    test rdx,rdx
    jz near .bad_cleanup
    mov rcx,[rsp+8]
    add rcx,rdx
    mov [rsp+8],rcx
    inc qword [rsp+16]
    jmp near .loop
.done:
    mov rax,[rsp+16]
    add rsp,40
    ret
.bad_cleanup:
    add rsp,40
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_ENCODING
    xor eax,eax
    ret


global rosam_utf8_decode
rosam_utf8_decode:
    movzx eax,byte [rcx]
    test al,al
    jz near .bad
    cmp al,0x7f
    jbe near .one
    cmp al,0xc2
    jb near .bad
    cmp al,0xdf
    jbe near .two
    cmp al,0xef
    jbe near .three
    cmp al,0xf4
    jbe near .four
    jmp near .bad
.two:
    movzx edx,byte [rcx+1]
    cmp dl,0x80
    jb near .bad
    cmp dl,0xbf
    ja near .bad
    mov r8d,eax
    and r8d,31
    shl r8d,6
    and edx,63
    or r8d,edx
    mov eax,r8d
    mov edx,2
    ret
.three:
    movzx edx,byte [rcx+1]
    movzx r8d,byte [rcx+2]
    cmp dl,0x80
    jb near .bad
    cmp dl,0xbf
    ja near .bad
    cmp r8b,0x80
    jb near .bad
    cmp r8b,0xbf
    ja near .bad
    cmp al,0xe0
    jne near .three_ed
    cmp dl,0xa0
    jb near .bad
    jmp near .three_calc
.three_ed:
    cmp al,0xed
    jne near .three_calc
    cmp dl,0x9f
    ja near .bad
.three_calc:
    mov eax,eax
    and eax,15
    shl eax,12
    and edx,63
    shl edx,6
    or eax,edx
    and r8d,63
    or eax,r8d
    mov edx,3
    ret
.four:
    movzx edx,byte [rcx+1]
    movzx r8d,byte [rcx+2]
    movzx r9d,byte [rcx+3]
    cmp dl,0x80
    jb near .bad
    cmp dl,0xbf
    ja near .bad
    cmp r8b,0x80
    jb near .bad
    cmp r8b,0xbf
    ja near .bad
    cmp r9b,0x80
    jb near .bad
    cmp r9b,0xbf
    ja near .bad
    cmp al,0xf0
    jne near .four_f4
    cmp dl,0x90
    jb near .bad
.four_f4:
    cmp al,0xf4
    jne near .four_calc
    cmp dl,0x8f
    ja near .bad
.four_calc:
    and eax,7
    shl eax,18
    and edx,63
    shl edx,12
    or eax,edx
    and r8d,63
    shl r8d,6
    or eax,r8d
    and r9d,63
    or eax,r9d
    mov edx,4
    ret
.one:
    mov edx,1
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_ENCODING
    mov eax,-1
    xor edx,edx
    ret


global rosam_utf8_encode
rosam_utf8_encode:
    test rcx,rcx
    jz near .bad
    mov r8d,edx
    cmp r8d,0x7f
    jbe near .one
    cmp r8d,0x7ff
    jbe near .two
    cmp r8d,0xffff
    jbe near .three
    cmp r8d,0x10ffff
    ja near .bad
    cmp r8d,0xd800
    jb near .four
    cmp r8d,0xdfff
    jbe near .bad
.four:
    mov eax,r8d
    shr eax,18
    or al,0xf0
    mov [rcx],al
    mov eax,r8d
    shr eax,12
    and al,63
    or al,0x80
    mov [rcx+1],al
    mov eax,r8d
    shr eax,6
    and al,63
    or al,0x80
    mov [rcx+2],al
    mov eax,r8d
    and al,63
    or al,0x80
    mov [rcx+3],al
    mov eax,4
    ret
.three:
    mov eax,r8d
    shr eax,12
    or al,0xe0
    mov [rcx],al
    mov eax,r8d
    shr eax,6
    and al,63
    or al,0x80
    mov [rcx+1],al
    mov eax,r8d
    and al,63
    or al,0x80
    mov [rcx+2],al
    mov eax,3
    ret
.two:
    mov eax,r8d
    shr eax,6
    or al,0xc0
    mov [rcx],al
    mov eax,r8d
    and al,63
    or al,0x80
    mov [rcx+1],al
    mov eax,2
    ret
.one:
    mov eax,r8d
    mov [rcx],al
    mov eax,1
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_ENCODING
    xor eax,eax
    ret


global rosam_utf8_next
rosam_utf8_next:
    test rcx,rcx
    jz near .bad
    sub rsp,24
    mov [rsp+8],rcx
    call rosam_utf8_decode
    test rdx,rdx
    jz near .bad_cleanup
    mov rcx,[rsp+8]
    add rcx,rdx
    mov rax,rcx
    add rsp,24
    ret
.bad_cleanup:
    add rsp,24
.bad:
    xor eax,eax
    ret


global rosam_utf8_prev
rosam_utf8_prev:
    cmp rdx,rcx; jbe .bad
    mov rax,rdx
    dec rax
.loop: cmp rax,rcx; je .ret
    mov dl,[rax]
    and dl,0xc0
    cmp dl,0x80
    jne near .ret
    dec rax
    jmp near .loop
.ret: ret
.bad: xor eax,eax; ret


global rosam_utf8_is_valid
rosam_utf8_is_valid:
    test rcx,rcx
    jz near .bad
.loop:
    movzx eax,byte [rcx]
    test al,al
    jz near .yes
    cmp al,0x7f
    jbe near .one
    cmp al,0xc2
    jb near .bad
    cmp al,0xdf
    jbe near .two
    cmp al,0xef
    jbe near .three
    cmp al,0xf4
    jbe near .four
    jmp near .bad
.two:
    mov dl,[rcx+1]
    cmp dl,0x80
    jb near .bad
    cmp dl,0xbf
    ja near .bad
    add rcx,2
    jmp near .loop
.three:
    mov dl,[rcx+1]
    mov r8b,[rcx+2]
    cmp dl,0x80
    jb near .bad
    cmp dl,0xbf
    ja near .bad
    cmp r8b,0x80
    jb near .bad
    cmp r8b,0xbf
    ja near .bad
    cmp al,0xe0
    jne near .three_ed
    cmp dl,0xa0
    jb near .bad
    jmp near .three_ok
.three_ed:
    cmp al,0xed
    jne near .three_ok
    cmp dl,0x9f
    ja near .bad
.three_ok:
    add rcx,3
    jmp near .loop
.four:
    mov dl,[rcx+1]
    mov r8b,[rcx+2]
    mov r9b,[rcx+3]
    cmp dl,0x80
    jb near .bad
    cmp dl,0xbf
    ja near .bad
    cmp r8b,0x80
    jb near .bad
    cmp r8b,0xbf
    ja near .bad
    cmp r9b,0x80
    jb near .bad
    cmp r9b,0xbf
    ja near .bad
    cmp al,0xf0
    jne near .four_f4
    cmp dl,0x90
    jb near .bad
.four_f4:
    cmp al,0xf4
    jne near .four_ok
    cmp dl,0x8f
    ja near .bad
.four_ok:
    add rcx,4
    jmp near .loop
.one:
    inc rcx
    jmp near .loop
.yes:
    mov eax,1
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_ENCODING
    xor eax,eax
    ret


global rosam_utf8_validate
rosam_utf8_validate:
    jmp near rosam_utf8_is_valid


global rosam_utf8_char_at
rosam_utf8_char_at:
    test rcx,rcx
    jz near .bad
    sub rsp,40
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov qword [rsp+24],0
.loop:
    mov r10,[rsp+24]
    cmp r10,[rsp+16]
    jae near .bad_cleanup
    mov rcx,[rsp+8]
    call rosam_utf8_decode
    test rdx,rdx
    jz near .bad_cleanup
    mov r10,[rsp+24]
    cmp r10,[rsp+16]
    je near .found
    mov rcx,[rsp+8]
    add rcx,rdx
    mov [rsp+8],rcx
    inc qword [rsp+24]
    jmp near .loop
.found:
    add rsp,40
    ret
.bad_cleanup:
    add rsp,40
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_OUT_OF_RANGE
    xor eax,eax
    ret


global rosam_bit_set
rosam_bit_set:
    mov eax,[rcx]; bts eax,edx; mov [rcx],eax; mov eax,1; ret


global rosam_bit_clear
rosam_bit_clear:
    mov eax,[rcx]; btr eax,edx; mov [rcx],eax; mov eax,1; ret


global rosam_bit_toggle
rosam_bit_toggle:
    mov eax,[rcx]; btc eax,edx; mov [rcx],eax; mov eax,1; ret


global rosam_bit_test
rosam_bit_test:
    mov eax,[rcx]; bt eax,edx; setc al; movzx eax,al; ret


global rosam_bit_shl
rosam_bit_shl:
    mov r8,rcx
    mov eax,[r8]
    mov ecx,edx
    shl eax,cl
    mov [r8],eax
    ret


global rosam_bit_shr
rosam_bit_shr:
    mov r8,rcx
    mov eax,[r8]
    mov ecx,edx
    shr eax,cl
    mov [r8],eax
    ret


global rosam_bit_sar
rosam_bit_sar:
    mov r8,rcx
    mov eax,[r8]
    mov ecx,edx
    sar eax,cl
    mov [r8],eax
    ret


global rosam_bit_rol
rosam_bit_rol:
    mov r8,rcx
    mov eax,[r8]
    mov ecx,edx
    rol eax,cl
    mov [r8],eax
    ret


global rosam_bit_ror
rosam_bit_ror:
    mov r8,rcx
    mov eax,[r8]
    mov ecx,edx
    ror eax,cl
    mov [r8],eax
    ret


global rosam_bit_popcount
rosam_bit_popcount:
    mov eax,[rcx]
    xor edx,edx
.loop:
    test eax,eax
    jz near .done
    mov r8d,eax
    dec r8d
    and eax,r8d
    inc edx
    jmp near .loop
.done:
    mov eax,edx
    ret


global rosam_bit_clz
rosam_bit_clz:
    mov eax,[rcx]; test eax,eax; jnz .nz; mov eax,32; ret; .nz: bsr edx,eax; mov eax,31; sub eax,edx; ret


global rosam_bit_ctz
rosam_bit_ctz:
    mov eax,[rcx]; test eax,eax; jnz .nz; mov eax,32; ret; .nz: bsf eax,eax; ret


global rosam_bit_parity
rosam_bit_parity:
    mov eax,[rcx]; test eax,eax; setpo al; movzx eax,al; ret


global rosam_bit_is_power2
rosam_bit_is_power2:
    mov eax,[rcx]; test eax,eax; jz .no; lea edx,[rax-1]; test eax,edx; setz al; movzx eax,al; ret; .no: xor eax,eax; ret


global rosam_bit_next_power2
rosam_bit_next_power2:
    mov eax,[rcx]; test eax,eax; jz .one; dec eax; mov edx,eax; shr edx,1; or eax,edx; mov edx,eax; shr edx,2; or eax,edx; mov edx,eax; shr edx,4; or eax,edx; mov edx,eax; shr edx,8; or eax,edx; mov edx,eax; shr edx,16; or eax,edx; inc eax; ret; .one: mov eax,1; ret


global rosam_bit_prev_power2
rosam_bit_prev_power2:
    mov eax,[rcx]
    test eax,eax
    jz near .zero
    bsr edx,eax
    mov ecx,edx
    mov eax,1
    shl eax,cl
    ret
.zero:
    xor eax,eax
    ret


global rosam_bswap16
rosam_bswap16:
    movzx eax,word [rcx]; xchg al,ah; mov [rcx],ax; movzx eax,ax; ret


global rosam_bswap32
rosam_bswap32:
    mov eax,[rcx]; bswap eax; mov [rcx],eax; ret


global rosam_bswap64
rosam_bswap64:
    mov rax,[rcx]; bswap rax; mov [rcx],rax; ret


global rosam_bit_reverse8
rosam_bit_reverse8:
    mov r9,rcx
    mov eax,[r9]
    xor edx,edx
    mov ecx,8
.loop:
    shl edx,1
    shr eax,1
    adc edx,0
    loop .loop
    mov [r9],edx
    mov eax,edx
    ret


global rosam_bit_reverse16
rosam_bit_reverse16:
    mov r9,rcx
    mov eax,[r9]
    xor edx,edx
    mov ecx,16
.loop:
    shl edx,1
    shr eax,1
    adc edx,0
    loop .loop
    mov [r9],edx
    mov eax,edx
    ret


global rosam_bit_reverse32
rosam_bit_reverse32:
    mov r9,rcx
    mov eax,[r9]
    xor edx,edx
    mov ecx,32
.loop:
    shl edx,1
    shr eax,1
    adc edx,0
    loop .loop
    mov [r9],edx
    mov eax,edx
    ret


global rosam_bit_reverse64
rosam_bit_reverse64:
    mov r9,rcx
    mov rax,[r9]
    xor rdx,rdx
    mov ecx,64
.loop:
    shl rdx,1
    shr rax,1
    adc rdx,0
    loop .loop
    mov [r9],rdx
    mov rax,rdx
    ret


global rosam_gcd
rosam_gcd:
    mov eax,[rcx]; mov r8d,[rdx]; test eax,eax; jns .a; neg eax; .a: test r8d,r8d; jns .loop; neg r8d; .loop: test r8d,r8d; jz .done; xor edx,edx; div r8d; mov eax,r8d; mov r8d,edx; jmp .loop; .done: ret


global rosam_lcm
rosam_lcm:
    mov eax,[rcx]
    mov r8d,[rdx]
    test eax,eax
    jz near .zero
    test r8d,r8d
    jz near .zero
    mov r9d,r8d
    mov r10d,eax
    ; absolute values for gcd
    test eax,eax
    jns near .a_ok
    neg eax
.a_ok:
    test r8d,r8d
    jns near .b_ok
    neg r8d
.b_ok:
.gcd:
    test r8d,r8d
    jz near .gcd_done
    xor edx,edx
    div r8d
    mov eax,r8d
    mov r8d,edx
    jmp near .gcd
.gcd_done:
    mov r11d,eax
    mov eax,r10d
    cdq
    idiv r11d
    imul eax,r9d
    test eax,eax
    jns near .ret
    neg eax
.ret:
    ret
.zero:
    xor eax,eax
    ret


global rosam_pow_i32
rosam_pow_i32:
    mov eax,1; mov r8d,[rcx]; mov r9d,[rdx]; test r9d,r9d; jle .done; .loop: test r9d,1; jz .skip; imul eax,r8d; .skip: imul r8d,r8d; shr r9d,1; jnz .loop; .done: ret


global rosam_is_power2
rosam_is_power2:
    mov eax,[rcx]; test eax,eax; jz .no; lea edx,[rax-1]; test eax,edx; setz al; movzx eax,al; ret; .no: xor eax,eax; ret


global rosam_floor_log2
rosam_floor_log2:
    mov eax,[rcx]; test eax,eax; jz .bad; bsr eax,eax; ret; .bad: mov dword [rel rosam_linux_error],ROSAM_ERR_INVALID_ARGUMENT; xor eax,eax; ret


global rosam_ceil_log2
rosam_ceil_log2:
    mov eax,[rcx]; test eax,eax; jz .bad; dec eax; bsr eax,eax; inc eax; ret; .bad: mov dword [rel rosam_linux_error],ROSAM_ERR_INVALID_ARGUMENT; xor eax,eax; ret


global rosam_sqrt_f64
rosam_sqrt_f64:
    movq xmm0,rdx
    sub rsp,8
    call sqrt
    add rsp,8
    movq rax,xmm0
    ret


global rosam_cbrt_f64
rosam_cbrt_f64:
    movq xmm0,rdx
    sub rsp,8
    call cbrt
    add rsp,8
    movq rax,xmm0
    ret


global rosam_sin_f64
rosam_sin_f64:
    movq xmm0,rdx
    sub rsp,8
    call sin
    add rsp,8
    movq rax,xmm0
    ret


global rosam_cos_f64
rosam_cos_f64:
    movq xmm0,rdx
    sub rsp,8
    call cos
    add rsp,8
    movq rax,xmm0
    ret


global rosam_tan_f64
rosam_tan_f64:
    movq xmm0,rdx
    sub rsp,8
    call tan
    add rsp,8
    movq rax,xmm0
    ret


global rosam_asin_f64
rosam_asin_f64:
    movq xmm0,rdx
    sub rsp,8
    call asin
    add rsp,8
    movq rax,xmm0
    ret


global rosam_acos_f64
rosam_acos_f64:
    movq xmm0,rdx
    sub rsp,8
    call acos
    add rsp,8
    movq rax,xmm0
    ret


global rosam_atan_f64
rosam_atan_f64:
    movq xmm0,rdx
    sub rsp,8
    call atan
    add rsp,8
    movq rax,xmm0
    ret


global rosam_sinh_f64
rosam_sinh_f64:
    movq xmm0,rdx
    sub rsp,8
    call sinh
    add rsp,8
    movq rax,xmm0
    ret


global rosam_cosh_f64
rosam_cosh_f64:
    movq xmm0,rdx
    sub rsp,8
    call cosh
    add rsp,8
    movq rax,xmm0
    ret


global rosam_tanh_f64
rosam_tanh_f64:
    movq xmm0,rdx
    sub rsp,8
    call tanh
    add rsp,8
    movq rax,xmm0
    ret


global rosam_exp_f64
rosam_exp_f64:
    movq xmm0,rdx
    sub rsp,8
    call exp
    add rsp,8
    movq rax,xmm0
    ret


global rosam_log_f64
rosam_log_f64:
    movq xmm0,rdx
    sub rsp,8
    call log
    add rsp,8
    movq rax,xmm0
    ret


global rosam_log10_f64
rosam_log10_f64:
    movq xmm0,rdx
    sub rsp,8
    call log10
    add rsp,8
    movq rax,xmm0
    ret


global rosam_floor_f64
rosam_floor_f64:
    movq xmm0,rdx
    sub rsp,8
    call floor
    add rsp,8
    movq rax,xmm0
    ret


global rosam_ceil_f64
rosam_ceil_f64:
    movq xmm0,rdx
    sub rsp,8
    call ceil
    add rsp,8
    movq rax,xmm0
    ret


global rosam_round_f64
rosam_round_f64:
    movq xmm0,rdx
    sub rsp,8
    call round
    add rsp,8
    movq rax,xmm0
    ret


global rosam_trunc_f64
rosam_trunc_f64:
    movq xmm0,rdx
    sub rsp,8
    call trunc
    add rsp,8
    movq rax,xmm0
    ret


global rosam_atan2_f64
rosam_atan2_f64:
    movq xmm0,rdx; movq xmm1,r8; sub rsp,8; call atan2; add rsp,8; movq rax,xmm0; ret


global rosam_pow_f64
rosam_pow_f64:
    movq xmm0,rdx; movq xmm1,r8; sub rsp,8; call pow; add rsp,8; movq rax,xmm0; ret


global rosam_is_nan_f64
rosam_is_nan_f64:
    movq xmm0,rdx; ucomisd xmm0,xmm0; setp al; movzx eax,al; ret


global rosam_is_inf_f64
rosam_is_inf_f64:
    mov rax,rdx; mov rcx,0x7fffffffffffffff; and rax,rcx; mov rcx,0x7ff0000000000000; cmp rax,rcx; sete al; movzx eax,al; ret


global rosam_is_finite_f64
rosam_is_finite_f64:
    sub rsp,8
    mov rcx,rdx
    call rosam_is_nan_f64
    test eax,eax
    jnz near .no
    mov rcx,rdx
    call rosam_is_inf_f64
    test eax,eax
    jnz near .no
    add rsp,8
    mov eax,1
    ret
.no:
    add rsp,8
    xor eax,eax
    ret


global rosam_rng_seed
rosam_rng_seed:
    mov [rel rosam_rng_state],rcx; test rcx,rcx; jnz .ok; mov qword [rel rosam_rng_state],88172645463325252; .ok: xor eax,eax; ret


global rosam_rng_init
rosam_rng_init:
    rdtsc; shl rdx,32; or rax,rdx; test rax,rax; jnz .set; mov rax,88172645463325252; .set: mov [rel rosam_rng_state],rax; xor eax,eax; ret


global rosam_rng_u64
rosam_rng_u64:
    mov rax,[rel rosam_rng_state]; mov rdx,rax; shr rdx,12; xor rax,rdx; mov rdx,rax; shl rdx,25; xor rax,rdx; mov rdx,rax; shr rdx,27; xor rax,rdx; mov [rel rosam_rng_state],rax; imul rax,2685821657736338717; ret


global rosam_rng_u8
rosam_rng_u8:
    call rosam_rng_u64; movzx eax,al; ret


global rosam_rng_u16
rosam_rng_u16:
    call rosam_rng_u64; movzx eax,ax; ret


global rosam_rng_u32
rosam_rng_u32:
    call rosam_rng_u64; mov eax,eax; ret


global rosam_rng_i32
rosam_rng_i32:
    jmp near rosam_rng_u32


global rosam_rng_i64
rosam_rng_i64:
    jmp near rosam_rng_u64


global rosam_rng_float
rosam_rng_float:
    call rosam_rng_u32
    shr eax,8
    cvtsi2ss xmm0,eax
    mov eax,0x33800000
    movd xmm1,eax
    mulss xmm0,xmm1
    movd eax,xmm0
    ret


global rosam_rng_double
rosam_rng_double:
    call rosam_rng_u64; shr rax,11; cvtsi2sd xmm0,rax; mov rax,0x3ca0000000000000; movq xmm1,rax; mulsd xmm0,xmm1; movq rax,xmm0; ret


global rosam_rng_range
rosam_rng_range:
    cmp rdx,rcx
    jb near .bad
    mov r8,rdx
    sub r8,rcx
    inc r8
    jnz near .bounded
    ; Full uint64 range: one raw sample plus minimum.
    call rosam_rng_u64
    add rax,rcx
    ret
.bounded:
    ; Rejection sampling: threshold = (-span) mod span.
    mov r9,r8
    neg r9
    xor rdx,rdx
    mov rax,r9
    div r8
    mov r10,rdx
.loop:
    call rosam_rng_u64
    cmp rax,r10
    jb near .loop
    xor edx,edx
    div r8
    mov rax,rdx
    add rax,rcx
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_OUT_OF_RANGE
    xor eax,eax
    ret


global rosam_rng_bytes
rosam_rng_bytes:
    test rcx,rcx
    jz near .bad
    mov r8,rcx
    mov r9,rdx
.loop:
    test r9,r9
    jz near .done
    call rosam_rng_u64
    mov r10,8
    cmp r9,r10
    cmovb r10,r9
.inner:
    mov [r8],al
    inc r8
    shr rax,8
    dec r9
    dec r10
    jnz near .inner
    jmp near .loop
.done:
    xor eax,eax
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_NULL
    mov eax,-1
    ret


global rosam_rng_uniform
rosam_rng_uniform:
    jmp near rosam_rng_double


global rosam_rng_boolean
rosam_rng_boolean:
    call rosam_rng_u8; and eax,1; ret


global rosam_secure_random
rosam_secure_random:
    test rcx,rcx
    jz near .bad
    sub rsp,24
    mov [rsp+8],rcx
    mov [rsp+16],rdx
.loop:
    mov r8,[rsp+16]
    test r8,r8
    jz near .ok
    mov eax,318
    xor edi,edi
    mov rsi,[rsp+8]
    mov rdx,r8
    cmp rdx,256
    jbe near .size_ok
    mov edx,256
.size_ok:
    xor r10d,r10d
    syscall
    test rax,rax
    js near .fail
    test rax,rax
    jz near .fail
    add qword [rsp+8],rax
    sub qword [rsp+16],rax
    jmp near .loop
.ok:
    add rsp,24
    xor eax,eax
    ret
.fail:
    mov dword [rel rosam_linux_error],ROSAM_ERR_IO
    add rsp,24
    mov eax,-1
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_NULL
    mov eax,-1
    ret


global rosam_rng_choice
rosam_rng_choice:
    test rcx,rcx
    jz near .bad
    test rdx,rdx
    jz near .bad
    test r8,r8
    jz near .bad
    sub rsp,24
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov [rsp+24],r8
    xor ecx,ecx
    mov rdx,[rsp+16]
    dec rdx
    call rosam_rng_range
    imul rax,[rsp+24]
    add rax,[rsp+8]
    add rsp,24
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_INVALID_ARGUMENT
    xor eax,eax
    ret


global rosam_rng_shuffle
rosam_rng_shuffle:
    ; RCX = data
    ; RDX = count
    ; R8  = element_size
    test rcx,rcx
    jz near .bad
    test r8,r8
    jz near .bad
    cmp rdx,2
    jb near .success

    sub rsp,56
    mov [rsp+8],rcx       ; data
    mov [rsp+16],rdx      ; count
    mov [rsp+24],r8       ; element_size
    mov qword [rsp+32],0  ; i

.outer:
    mov rax,[rsp+16]
    dec rax               ; last index
    cmp [rsp+32],rax
    jae near .success_frame

    ; range = [0, i]
    mov rcx,0
    mov rdx,[rsp+32]
    call rosam_rng_range
    mov [rsp+40],rax      ; j

    ; offset_i = i * element_size
    mov rax,[rsp+32]
    imul rax,[rsp+24]
    mov r10,rax

    ; offset_j = j * element_size
    mov rax,[rsp+40]
    imul rax,[rsp+24]
    mov r11,rax

    ; addresses
    mov rax,[rsp+8]
    add r10,rax
    add r11,rax

    ; byte-wise swap
    mov r9,[rsp+24]
.swap:
    test r9,r9
    jz near .next
    mov al,[r10]
    mov dl,[r11]
    mov [r10],dl
    mov [r11],al
    inc r10
    inc r11
    dec r9
    jmp near .swap

.next:
    inc qword [rsp+32]
    jmp near .outer

.success_frame:
    add rsp,56

.success:
    xor eax,eax
    ret

.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_INVALID_ARGUMENT
    mov eax,-1
    ret


global rosam_array_copy
rosam_array_copy:
    jmp near rosam_mem_copy


global rosam_array_fill
rosam_array_fill:
    jmp near rosam_mem_set


global rosam_array_get
rosam_array_get:
    ; RCX=base RDX=index R8=elem_size R9=dest
    mov r10,rdx; imul r10,r8; add r10,rcx
    mov rdi,r9; mov rsi,r10; mov rdx,r8
    sub rsp,8; call memcpy; add rsp,8; xor eax,eax; ret


global rosam_array_set
rosam_array_set:
    mov r10,rdx; imul r10,r8; add r10,rcx
    mov rdi,r10; mov rsi,r9; mov rdx,r8
    sub rsp,8; call memcpy; add rsp,8; xor eax,eax; ret


global rosam_array_find
rosam_array_find:
    xor r9d,r9d
.loop: cmp r9,rdx; jae .no; cmp [rcx+r9*4],r8d; je .yes; inc r9; jmp .loop
.yes: mov rax,r9; ret
.no: mov rax,-1; ret


global rosam_array_contains
rosam_array_contains:
    sub rsp,8
    call rosam_array_find
    add rsp,8
    cmp rax,-1
    setne al
    movzx eax,al
    ret


global rosam_array_sort
rosam_array_sort:
    cmp rdx,1; jbe .done; mov r8d,1
.outer: cmp r8,rdx; jae .done; mov eax,[rcx+r8*4]; mov r9,r8
.inner: test r9,r9; jz .insert; cmp [rcx+r9*4-4],eax; jle .insert; mov r10d,[rcx+r9*4-4]; mov [rcx+r9*4],r10d; dec r9; jmp .inner
.insert: mov [rcx+r9*4],eax; inc r8; jmp .outer
.done: xor eax,eax; ret


global rosam_array_reverse
rosam_array_reverse:
    ; RCX=base RDX=count R8=element size
    cmp rdx,1; jbe .done; dec rdx; mov r9,rdx; imul r9,r8; add r9,rcx
.outer: cmp rcx,r9; jae .done; mov r10,r8
.inner: test r10,r10; jz .next; mov al,[rcx+r10-1]; mov dl,[r9+r10-1]; mov [rcx+r10-1],dl; mov [r9+r10-1],al; dec r10; jmp .inner
.next: add rcx,r8; sub r9,r8; jmp .outer
.done: xor eax,eax; ret


; Vector structure offsets:
; +0 data pointer, +8 len, +16 capacity, +24 elem_size, +32 reserved/head.


global rosam_vec_create
rosam_vec_create:
    test rcx,rcx
    jz near .bad
    test rdx,rdx
    jz near .bad
    sub rsp,40
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov [rsp+24],r8
    mov [rcx+24],rdx
    mov qword [rcx+8],0
    mov qword [rcx+32],0
    mov [rcx+16],r8
    test r8,r8
    jz near .zero
    mov rax,r8
    mul rdx
    test rdx,rdx
    jnz near .oom
    mov rdi,rax
    call malloc
    test rax,rax
    jz near .oom
    mov rcx,[rsp+8]
    mov [rcx],rax
    add rsp,40
    xor eax,eax
    ret
.zero:
    mov rcx,[rsp+8]
    mov qword [rcx],0
    add rsp,40
    xor eax,eax
    ret
.oom:
    mov dword [rel rosam_linux_error],ROSAM_ERR_OUT_OF_MEMORY
    add rsp,40
    mov eax,-1
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_INVALID_ARGUMENT
    mov eax,-1
    ret


global rosam_vec_destroy
rosam_vec_destroy:
    test rcx,rcx
    jz near .bad
    sub rsp,24
    mov [rsp+8],rcx
    mov rdi,[rcx]
    test rdi,rdi
    jz near .zero
    call free
.zero:
    mov rcx,[rsp+8]
    mov qword [rcx],0
    mov qword [rcx+8],0
    mov qword [rcx+16],0
    add rsp,24
    xor eax,eax
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_INVALID_ARGUMENT
    mov eax,-1
    ret


global rosam_vec_len
rosam_vec_len:
    mov rax,[rcx+8]; ret


global rosam_vec_capacity
rosam_vec_capacity:
    mov rax,[rcx+16]; ret


global rosam_vec_clear
rosam_vec_clear:
    mov qword [rcx+8],0; xor eax,eax; ret


global rosam_vec_reserve
rosam_vec_reserve:
    test rcx,rcx
    jz near .bad
    mov r8,[rcx+24]
    test r8,r8
    jz near .bad
    cmp rdx,[rcx+16]
    jbe near .ok
    sub rsp,40
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov rax,rdx
    mul r8
    test rdx,rdx
    jnz near .oom
    mov rdi,[rcx]
    test rdi,rdi
    jz near .alloc
    mov rsi,rax
    mov rdi,[rcx]
    call realloc
    test rax,rax
    jz near .oom
    mov rcx,[rsp+8]
    mov [rcx],rax
    mov rdx,[rsp+16]
    mov [rcx+16],rdx
    add rsp,40
    xor eax,eax
    ret
.alloc:
    mov rdi,rax
    call malloc
    test rax,rax
    jz near .oom
    mov rcx,[rsp+8]
    mov [rcx],rax
    mov rdx,[rsp+16]
    mov [rcx+16],rdx
    add rsp,40
    xor eax,eax
    ret
.ok:
    xor eax,eax
    ret
.oom:
    mov dword [rel rosam_linux_error],ROSAM_ERR_OUT_OF_MEMORY
    add rsp,40
    mov eax,-1
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_INVALID_ARGUMENT
    mov eax,-1
    ret


global rosam_vec_resize
rosam_vec_resize:
    test rcx,rcx
    jz near .bad
    sub rsp,40
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov r8,[rcx+8]
    mov [rsp+24],r8
    mov r9,[rcx+24]
    mov [rsp+32],r9
    cmp rdx,r8
    jbe near .set_only
    cmp rdx,[rcx+16]
    jbe near .capacity_ok
    mov r10,[rcx+16]
    test r10,r10
    jnz near .grow
    mov r10,1
.grow:
    cmp r10,rdx
    jae near .reserve
    shl r10,1
    jc near .oom
    jmp near .grow
.reserve:
    mov rcx,[rsp+8]
    mov rdx,r10
    call rosam_vec_reserve
    test eax,eax
    jnz near .fail
.capacity_ok:
    mov rcx,[rsp+8]
    mov r10,[rsp+16]
    mov r8,[rsp+24]
    cmp r10,r8
    jbe near .set_only
    mov r9,[rsp+32]
    mov r11,[rcx]
    imul r8,r9
    add r11,r8
    mov r8,r10
    sub r8,[rsp+24]
    imul r8,r9
    mov rdi,r11
    xor esi,esi
    mov rdx,r8
    call memset
.set_only:
    mov rcx,[rsp+8]
    mov rdx,[rsp+16]
    mov [rcx+8],rdx
    add rsp,40
    xor eax,eax
    ret
.fail:
    add rsp,40
    ret
.oom:
    mov dword [rel rosam_linux_error],ROSAM_ERR_OUT_OF_MEMORY
    add rsp,40
    mov eax,-1
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_INVALID_ARGUMENT
    mov eax,-1
    ret


global rosam_vec_push
rosam_vec_push:
    test rcx,rcx
    jz near .bad
    test rdx,rdx
    jz near .bad
    sub rsp,40
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov r8,[rcx+8]
    cmp r8,[rcx+16]
    jb near .room
    mov rdx,[rcx+16]
    test rdx,rdx
    jnz near .dbl
    mov rdx,1
.dbl:
    shl rdx,1
    mov rcx,[rsp+8]
    call rosam_vec_reserve
    test eax,eax
    jnz near .fail
.room:
    mov rcx,[rsp+8]
    mov r8,[rcx+8]
    mov r9,[rcx+24]
    mov r10,[rcx]
    imul r8,r9
    add r10,r8
    mov rdi,r10
    mov rsi,[rsp+16]
    mov rdx,r9
    call memcpy
    mov rcx,[rsp+8]
    inc qword [rcx+8]
    add rsp,40
    xor eax,eax
    ret
.fail:
    add rsp,40
.ret:
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_INVALID_ARGUMENT
    mov eax,-1
    ret


global rosam_vec_pop
rosam_vec_pop:
    test rcx,rcx
    jz near .bad
    sub rsp,40
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov r8,[rcx+8]
    test r8,r8
    jz near .empty
    dec r8
    mov r9,[rcx+24]
    mov r10,[rcx]
    mov r11,r8
    imul r11,r9
    add r10,r11
    test rdx,rdx
    jz near .skip
    mov rdi,rdx
    mov rsi,r10
    mov rdx,r9
    call memcpy
.skip:
    mov rcx,[rsp+8]
    mov r8,[rsp+8]
    dec qword [r8+8]
    add rsp,40
    xor eax,eax
    ret
.empty:
    mov dword [rel rosam_linux_error],ROSAM_ERR_OUT_OF_RANGE
    add rsp,40
    mov eax,-1
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_INVALID_ARGUMENT
    mov eax,-1
    ret


global rosam_vec_get
rosam_vec_get:
    cmp rdx,[rcx+8]; jae .bad; mov r9,[rcx+24]; mov r10,[rcx]; imul rdx,r9; add r10,rdx; mov rdi,r8; mov rsi,r10; mov rdx,r9; sub rsp,8; call memcpy; add rsp,8; xor eax,eax; ret
.bad: mov dword [rel rosam_linux_error],ROSAM_ERR_OUT_OF_RANGE; mov eax,-1; ret


global rosam_vec_set
rosam_vec_set:
    cmp rdx,[rcx+8]; jae .bad; mov r9,[rcx+24]; mov r10,[rcx]; imul rdx,r9; add r10,rdx; mov rdi,r10; mov rsi,r8; mov rdx,r9; sub rsp,8; call memcpy; add rsp,8; xor eax,eax; ret
.bad: mov dword [rel rosam_linux_error],ROSAM_ERR_OUT_OF_RANGE; mov eax,-1; ret


global rosam_stack_create
rosam_stack_create:
    jmp near rosam_vec_create


global rosam_stack_destroy
rosam_stack_destroy:
    jmp near rosam_vec_destroy


global rosam_stack_push
rosam_stack_push:
    jmp near rosam_vec_push


global rosam_stack_pop
rosam_stack_pop:
    jmp near rosam_vec_pop


global rosam_stack_peek
rosam_stack_peek:
    mov r8,[rcx+8]; test r8,r8; jz .bad; dec r8; mov r9,[rcx+24]; mov r10,[rcx]; imul r8,r9; add r10,r8; mov rdi,rdx; mov rsi,r10; mov rdx,r9; sub rsp,8; call memcpy; add rsp,8; xor eax,eax; ret
.bad: mov dword [rel rosam_linux_error],ROSAM_ERR_OUT_OF_RANGE; mov eax,-1; ret


global rosam_stack_len
rosam_stack_len:
    jmp near rosam_vec_len


global rosam_deque_push_back
rosam_deque_push_back:
    jmp near rosam_vec_push


global rosam_deque_pop_back
rosam_deque_pop_back:
    jmp near rosam_vec_pop


global rosam_deque_push_front
rosam_deque_push_front:
    test rcx,rcx
    jz near .bad
    test rdx,rdx
    jz near .bad
    sub rsp,56
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov r8,[rcx+24]
    mov [rsp+24],r8
    mov r8,[rcx+8]
    cmp r8,[rcx+16]
    jb near .room
    mov rdx,[rcx+16]
    test rdx,rdx
    jnz near .grow
    mov rdx,1
.grow:
    shl rdx,1
    mov rcx,[rsp+8]
    call rosam_vec_reserve
    test eax,eax
    jnz near .fail
.room:
    mov rcx,[rsp+8]
    mov r8,[rsp+24]
    mov r9,[rcx]
    mov r10,[rcx+8]
    imul r10,r8
    add r10,r9
    mov rdi,r9
    lea rsi,[r9+r8]
    mov rdx,r10
    sub rdx,r9
    add rdx,r8
    sub rdx,r8
    ; bytes to move = old_len * elem_size
    mov rdx,[rcx+8]
    imul rdx,r8
    call memmove
    mov rdi,[rsp+8]
    mov rsi,[rsp+16]
    mov rdx,[rsp+24]
    call memcpy
    mov rcx,[rsp+8]
    inc qword [rcx+8]
    add rsp,56
    xor eax,eax
    ret
.fail:
    add rsp,56
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_INVALID_ARGUMENT
    mov eax,-1
    ret


global rosam_deque_pop_front
rosam_deque_pop_front:
    test rcx,rcx
    jz near .bad
    sub rsp,40
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov r8,[rcx+8]
    test r8,r8
    jz near .empty
    mov r9,[rcx+24]
    mov r10,[rcx]
    test rdx,rdx
    jz near .shift
    mov rdi,rdx
    mov rsi,r10
    mov rdx,r9
    call memcpy
.shift:
    mov rcx,[rsp+8]
    dec qword [rcx+8]
    mov r8,[rcx+8]
    mov r9,[rcx+24]
    mov r10,[rcx]
    imul r8,r9
    lea rsi,[r10+r9]
    mov rdi,r10
    mov rdx,r8
    call memmove
    mov eax,0
    add rsp,40
    ret
.empty:
    mov dword [rel rosam_linux_error],ROSAM_ERR_OUT_OF_RANGE
    mov eax,-1
    add rsp,40
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_INVALID_ARGUMENT
    mov eax,-1
    ret


global rosam_linear_search
rosam_linear_search:
    xor r9d,r9d; .loop: cmp r9,rdx; jae .no; cmp [rcx+r9*4],r8d; je .yes; inc r9; jmp .loop; .yes: mov rax,r9; ret; .no: mov rax,-1; ret


global rosam_binary_search
rosam_binary_search:
    xor r9d,r9d; mov r10d,edx; dec r10d; .loop: cmp r9d,r10d; jg .no; lea eax,[r9d+r10d]; shr eax,1; movsxd r11,eax; cmp [rcx+r11*4],r8d; je .yes; jl .right; lea r10d,[eax-1]; jmp .loop; .right: lea r9d,[eax+1]; jmp .loop; .yes: movsxd rax,eax; ret; .no: mov rax,-1; ret


global rosam_sort
rosam_sort:
    jmp near rosam_array_sort


global rosam_quick_sort
rosam_quick_sort:
    jmp near rosam_array_sort


global rosam_merge_sort
rosam_merge_sort:
    jmp near rosam_array_sort


global rosam_heap_sort
rosam_heap_sort:
    jmp near rosam_array_sort


global rosam_insertion_sort
rosam_insertion_sort:
    jmp near rosam_array_sort


global rosam_reverse
rosam_reverse:
    test rdx,rdx; jz .done; lea r8,[rcx+rdx-1]; .loop: cmp rcx,r8; jae .done; mov al,[rcx]; mov dl,[r8]; mov [rcx],dl; mov [r8],al; inc rcx; dec r8; jmp .loop; .done: xor eax,eax; ret


global rosam_find_min
rosam_find_min:
    test rdx,rdx; jz .bad; mov eax,[rcx]; xor r8d,r8d; mov r9d,1; .loop: cmp r9,rdx; jae .done; mov r10d,[rcx+r9*4]; cmp r10d,eax; jge .next; mov eax,r10d; mov r8,r9; .next: inc r9; jmp .loop; .done: mov edx,r8d; ret; .bad: xor eax,eax; ret


global rosam_find_max
rosam_find_max:
    test rdx,rdx; jz .bad; mov eax,[rcx]; xor r8d,r8d; mov r9d,1; .loop: cmp r9,rdx; jae .done; mov r10d,[rcx+r9*4]; cmp r10d,eax; jle .next; mov eax,r10d; mov r8,r9; .next: inc r9; jmp .loop; .done: mov edx,r8d; ret; .bad: xor eax,eax; ret


global rosam_sum
rosam_sum:
    xor eax,eax; xor r8d,r8d; .loop: cmp r8,rdx; jae .done; add eax,[rcx+r8*4]; inc r8; jmp .loop; .done: ret


global rosam_product
rosam_product:
    mov eax,1; xor r8d,r8d; .loop: cmp r8,rdx; jae .done; imul eax,[rcx+r8*4]; inc r8; jmp .loop; .done: ret


global rosam_count
rosam_count:
    xor eax,eax
    xor r9d,r9d
.loop:
    cmp r9,rdx
    jae near .done
    cmp [rcx+r9*4],r8d
    jne near .next
    inc eax
.next:
    inc r9
    jmp near .loop
.done:
    ret


global rosam_count_if
rosam_count_if:
    sub rsp,56
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov [rsp+24],r8
    mov [rsp+32],r9
    mov qword [rsp+40],0
    mov qword [rsp+48],0
.loop:
    mov r10,[rsp+48]
    cmp r10,[rsp+16]
    jae near .done
    mov rcx,[rsp+8]
    lea rcx,[rcx+r10*4]
    mov rdx,r10
    mov rax,[rsp+32]
    call rax
    test eax,eax
    jz near .next
    inc qword [rsp+40]
.next:
    inc qword [rsp+48]
    jmp near .loop
.done:
    mov rax,[rsp+40]
    add rsp,56
    ret


global rosam_any
rosam_any:
    sub rsp,56
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov [rsp+24],r8
    mov qword [rsp+32],0
.loop:
    mov r9,[rsp+32]
    cmp r9,[rsp+16]
    jae near .yes
    mov rcx,[rsp+8]
    lea rcx,[rcx+r9*4]
    mov rdx,r9
    mov rax,[rsp+24]
    call rax
    test eax,eax
    jnz near .yes
    inc qword [rsp+32]
    jmp near .loop
.yes:
    mov eax,1
    add rsp,56
    ret
.no:
    xor eax,eax
    add rsp,56
    ret


global rosam_all
rosam_all:
    sub rsp,56
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov [rsp+24],r8
    mov qword [rsp+32],0
.loop:
    mov r9,[rsp+32]
    cmp r9,[rsp+16]
    jae near .yes
    mov rcx,[rsp+8]
    lea rcx,[rcx+r9*4]
    mov rdx,r9
    mov rax,[rsp+24]
    call rax
    test eax,eax
    jz near .no
    inc qword [rsp+32]
    jmp near .loop
.yes:
    mov eax,1
    add rsp,56
    ret
.no:
    xor eax,eax
    add rsp,56
    ret


global rosam_none
rosam_none:
    sub rsp,56
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov [rsp+24],r8
    mov qword [rsp+32],0
.loop:
    mov r9,[rsp+32]
    cmp r9,[rsp+16]
    jae near .yes
    mov rcx,[rsp+8]
    lea rcx,[rcx+r9*4]
    mov rdx,r9
    mov rax,[rsp+24]
    call rax
    test eax,eax
    jnz near .no
    inc qword [rsp+32]
    jmp near .loop
.yes:
    mov eax,1
    add rsp,56
    ret
.no:
    xor eax,eax
    add rsp,56
    ret


global rosam_copy_if
rosam_copy_if:
    sub rsp,72
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov [rsp+24],r8
    mov [rsp+32],r9
    mov qword [rsp+40],0
    mov qword [rsp+48],0
.loop:
    mov r10,[rsp+48]
    cmp r10,[rsp+24]
    jae near .done
    mov rcx,[rsp+16]
    lea rcx,[rcx+r10*4]
    mov rdx,r10
    mov rax,[rsp+32]
    call rax
    test eax,eax
    jz near .next
    mov r10,[rsp+48]
    mov rcx,[rsp+16]
    mov eax,[rcx+r10*4]
    mov rcx,[rsp+8]
    mov r11,[rsp+40]
    mov [rcx+r11*4],eax
    inc qword [rsp+40]
.next:
    inc qword [rsp+48]
    jmp near .loop
.done:
    mov rax,[rsp+40]
    add rsp,72
    ret


global rosam_transform
rosam_transform:
    sub rsp,56
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov [rsp+24],r8
    mov [rsp+32],r9
    mov qword [rsp+40],0
.loop:
    mov r10,[rsp+40]
    cmp r10,[rsp+24]
    jae near .done
    mov rcx,[rsp+16]
    lea rcx,[rcx+r10*4]
    mov rdx,r10
    mov rax,[rsp+32]
    call rax
    mov r10,[rsp+40]
    mov rcx,[rsp+8]
    mov [rcx+r10*4],eax
    inc qword [rsp+40]
    jmp near .loop
.done:
    xor eax,eax
    add rsp,56
    ret


global rosam_fill
rosam_fill:
    xor r9d,r9d; .loop: cmp r9,rdx; jae .done; mov [rcx+r9*4],r8d; inc r9; jmp .loop; .done: xor eax,eax; ret


global rosam_partition
rosam_partition:
    sub rsp,56
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov [rsp+24],r8
    mov qword [rsp+32],0
    mov qword [rsp+40],0
.loop:
    mov r10,[rsp+40]
    cmp r10,[rsp+16]
    jae near .done
    mov rcx,[rsp+8]
    lea rcx,[rcx+r10*4]
    mov rdx,r10
    mov rax,[rsp+24]
    call rax
    test eax,eax
    jz near .next
    mov r10,[rsp+40]
    mov r9,[rsp+32]
    cmp r9,r10
    je near .inc
    mov rcx,[rsp+8]
    mov eax,[rcx+r10*4]
    xchg eax,[rcx+r9*4]
    mov [rcx+r10*4],eax
.inc:
    inc qword [rsp+32]
.next:
    inc qword [rsp+40]
    jmp near .loop
.done:
    mov rax,[rsp+32]
    add rsp,56
    ret


global rosam_stable_partition
rosam_stable_partition:
    test rcx,rcx
    jz near .bad
    test r8,r8
    jz near .bad
    sub rsp,72
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov [rsp+24],r8
    mov qword [rsp+32],0
    mov qword [rsp+40],0
    mov rdi,rdx
    shl rdi,2
    call malloc
    test rax,rax
    jz near .oom
    mov [rsp+48],rax
.pass1:
    mov r10,[rsp+40]
    cmp r10,[rsp+16]
    jae near .pass1_done
    mov rcx,[rsp+8]
    lea rcx,[rcx+r10*4]
    mov rdx,r10
    mov rax,[rsp+24]
    call rax
    test eax,eax
    jz near .p1next
    mov r10,[rsp+40]
    mov r9,[rsp+32]
    mov rcx,[rsp+8]
    mov eax,[rcx+r10*4]
    mov rcx,[rsp+48]
    mov [rcx+r9*4],eax
    inc qword [rsp+32]
.p1next:
    inc qword [rsp+40]
    jmp near .pass1
.pass1_done:
    mov qword [rsp+40],0
.pass2:
    mov r10,[rsp+40]
    cmp r10,[rsp+16]
    jae near .copyback
    mov rcx,[rsp+8]
    lea rcx,[rcx+r10*4]
    mov rdx,r10
    mov rax,[rsp+24]
    call rax
    test eax,eax
    jnz near .p2next
    mov r10,[rsp+40]
    mov r9,[rsp+32]
    mov rcx,[rsp+8]
    mov eax,[rcx+r10*4]
    mov rcx,[rsp+48]
    mov [rcx+r9*4],eax
    inc qword [rsp+32]
.p2next:
    inc qword [rsp+40]
    jmp near .pass2
.copyback:
    mov rcx,[rsp+8]
    mov rsi,[rsp+48]
    mov rdi,rcx
    mov rdx,[rsp+16]
    shl rdx,2
    call memmove
    mov rdi,[rsp+48]
    call free
    mov rax,[rsp+32]
    add rsp,72
    ret
.oom:
    mov dword [rel rosam_linux_error],ROSAM_ERR_OUT_OF_MEMORY
    mov eax,-1
    add rsp,72
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_INVALID_ARGUMENT
    mov eax,-1
    ret


global rosam_prefix_sum
rosam_prefix_sum:
    xor r8d,r8d; xor r9d,r9d; .loop: cmp r8,rdx; jae .done; add r9d,[rcx+r8*4]; mov [rcx+r8*4],r9d; inc r8; jmp .loop; .done: xor eax,eax; ret


global rosam_format_char
rosam_format_char:
    mov [rcx],dl; mov byte [rcx+1],0; mov eax,1; ret


global rosam_format_bool
rosam_format_bool:
    mov r8,rcx
    test edx,edx
    jz near .false
    lea r9,[rel rosam_linux_true]
    jmp near .copy
.false:
    lea r9,[rel rosam_linux_false]
.copy:
    xor eax,eax
.loop:
    mov dl,[r9+rax]
    mov [r8+rax],dl
    test dl,dl
    jz near .done
    inc rax
    jmp near .loop
.done:
    ret


global rosam_format_i8
rosam_format_i8:
    movsx rdx,dl; jmp rosam_itoa_i64


global rosam_format_u8
rosam_format_u8:
    movzx rdx,dl; jmp rosam_utoa_u64


global rosam_format_i16
rosam_format_i16:
    movsx rdx,dx; jmp rosam_itoa_i64


global rosam_format_u16
rosam_format_u16:
    movzx rdx,dx; jmp rosam_utoa_u64


global rosam_format_i32
rosam_format_i32:
    movsxd rdx,edx; jmp rosam_itoa_i64


global rosam_format_u32
rosam_format_u32:
    mov edx,edx; jmp rosam_utoa_u64


global rosam_format_i64
rosam_format_i64:
    jmp near rosam_itoa_i64


global rosam_format_u64
rosam_format_u64:
    jmp near rosam_utoa_u64


global rosam_format_dec
rosam_format_dec:
    jmp near rosam_format_u32


global rosam_format_hex
rosam_format_hex:
    mov r8,rcx
    mov eax,edx
    lea r9,[rel rosam_linux_int_buf+31]
    mov byte [r9],0
    test eax,eax
    jnz near .convert
    dec r9
    mov byte [r9],'0'
    jmp near .copy
.convert:
    mov ecx,16
.loop:
    xor edx,edx
    div ecx
    cmp dl,9
    jbe near .digit
    add dl,'A'-10
    jmp near .store
.digit:
    add dl,'0'
.store:
    dec r9
    mov [r9],dl
    test eax,eax
    jnz near .loop
.copy:
    xor eax,eax
.c_loop:
    mov dl,[r9+rax]
    mov [r8+rax],dl
    test dl,dl
    jz near .done
    inc eax
    jmp near .c_loop
.done:
    ret


global rosam_format_bin
rosam_format_bin:
    mov r8,rcx; mov r9d,edx; mov ecx,32; .loop: mov eax,ecx; dec eax; bt r9d,eax; setc al; add al,'0'; mov [r8],al; inc r8; dec ecx; jnz .loop; mov byte [r8],0; mov eax,32; ret


global rosam_format_oct
rosam_format_oct:
    mov r8,rcx
    mov eax,edx
    lea r9,[rel rosam_linux_int_buf+31]
    mov byte [r9],0
    test eax,eax
    jnz near .convert
    dec r9
    mov byte [r9],'0'
    jmp near .copy
.convert:
    mov ecx,8
.loop:
    xor edx,edx
    div ecx
    add dl,'0'
    dec r9
    mov [r9],dl
    test eax,eax
    jnz near .loop
.copy:
    xor eax,eax
.c_loop:
    mov dl,[r9+rax]
    mov [r8+rax],dl
    test dl,dl
    jz near .done
    inc eax
    jmp near .c_loop
.done:
    ret


global rosam_format_append
rosam_format_append:
    test rcx,rcx
    jz near .bad
    test rdx,rdx
    jz near .bad
    sub rsp,48
    mov [rsp+8],rcx
    mov [rsp+16],rdx
    mov [rsp+24],r8
    mov rdi,rcx
    sub rsp,8
    call strlen
    add rsp,8
    mov [rsp+32],rax
    mov rdi,[rsp+16]
    sub rsp,8
    call strlen
    add rsp,8
    mov r9,rax
    mov r8,[rsp+24]
    mov r10,[rsp+32]
    cmp r10,r8
    jae near .done
    mov rax,r8
    sub rax,r10
    dec rax
    cmp r9,rax
    cmova r9,rax
    mov rcx,[rsp+8]
    lea rdi,[rcx+r10]
    mov rsi,[rsp+16]
    mov rdx,r9
    sub rsp,8
    call memcpy
    add rsp,8
    mov rcx,[rsp+8]
    mov rax,r10
    add rax,r9
    mov byte [rcx+rax],0
.done:
    mov rax,[rsp+8]
    add rsp,48
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_NULL
    xor eax,eax
    ret


global rosam_format_f32
rosam_format_f32:
    movd xmm0,edx
    cvtss2sd xmm0,xmm0
    mov rdi,rcx
    mov esi,128
    test r8d,r8d
    jz near .def
    lea rdx,[rel rosam_linux_fmt_gp]
    mov ecx,r8d
    mov eax,1
    sub rsp,8
    call snprintf
    add rsp,8
    ret
.def:
    lea rdx,[rel rosam_linux_fmt_g]
    mov eax,1
    sub rsp,8
    call snprintf
    add rsp,8
    ret


global rosam_format_f64
rosam_format_f64:
    movq xmm0,rdx; mov rdi,rcx; mov esi,128; test r8d,r8d; jz .def; lea rdx,[rel rosam_linux_fmt_gp]; mov ecx,r8d; mov eax,1; sub rsp,8; call snprintf; add rsp,8; ret; .def: lea rdx,[rel rosam_linux_fmt_g]; mov eax,1; sub rsp,8; call snprintf; add rsp,8; ret


global rosam_format_value
rosam_format_value:
    cmp r8d,1
    je near .i32
    cmp r8d,2
    je near .i64
    cmp r8d,3
    je near .u32
    cmp r8d,4
    je near .u64
    cmp r8d,5
    je near .bool
    cmp r8d,6
    je near .char
    cmp r8d,7
    je near .f32
    cmp r8d,8
    je near .f64
    mov dword [rel rosam_linux_error],ROSAM_ERR_INVALID_ARGUMENT
    xor eax,eax
    ret
.i32: jmp rosam_format_i32
.i64: jmp rosam_format_i64
.u32: jmp rosam_format_u32
.u64: jmp rosam_format_u64
.bool: jmp rosam_format_bool
.char: jmp rosam_format_char
.f32: mov r8d,r9d; jmp rosam_format_f32
.f64: mov r8d,r9d; jmp rosam_format_f64


global rosam_i32_min
rosam_i32_min:
    mov eax,dword [rcx]
    mov r8d,dword [rdx]
    cmp eax,r8d
    jle near .done
    mov eax,r8d
    mov dword [rcx],eax
.done: ret


global rosam_i32_max
rosam_i32_max:
    mov eax,dword [rcx]
    mov r8d,dword [rdx]
    cmp eax,r8d
    jge near .done
    mov eax,r8d
    mov dword [rcx],eax
.done: ret


global rosam_i32_clamp
rosam_i32_clamp:
    mov eax,dword [rcx]
    mov r9d,dword [rdx]
    cmp eax,r9d
    jge near .hi
    mov eax,r9d
.hi:
    mov r10d,dword [r8]
    cmp eax,r10d
    jle near .store
    mov eax,r10d
.store:
    mov dword [rcx],eax
    ret


global rosam_u32_min
rosam_u32_min:
    mov eax,dword [rcx]
    mov r8d,dword [rdx]
    cmp eax,r8d
    jbe near .done
    mov eax,r8d
    mov dword [rcx],eax
.done: ret



global rosam_u32_max
rosam_u32_max:
    mov eax,dword [rcx]
    mov r8d,dword [rdx]
    cmp eax,r8d
    jae near .done
    mov eax,r8d
    mov dword [rcx],eax
.done: ret


global rosam_u32_clamp
rosam_u32_clamp:
    mov eax,dword [rcx]
    mov r9d,dword [rdx]
    cmp eax,r9d
    jae near .hi
    mov eax,r9d
.hi:
    mov r10d,dword [r8]
    cmp eax,r10d
    jbe near .store
    mov eax,r10d
.store:
    mov dword [rcx],eax
    ret


global rosam_i64_min
rosam_i64_min:
    mov rax,qword [rcx]
    mov r8,qword [rdx]
    cmp rax,r8
    jle near .done
    mov rax,r8
    mov qword [rcx],rax
.done: ret


global rosam_i64_max
rosam_i64_max:
    mov rax,qword [rcx]
    mov r8,qword [rdx]
    cmp rax,r8
    jge near .done
    mov rax,r8
    mov qword [rcx],rax
.done: ret


global rosam_i64_clamp
rosam_i64_clamp:
    mov rax,qword [rcx]
    mov r9,qword [rdx]
    cmp rax,r9
    jge near .hi
    mov rax,r9
.hi:
    mov r10,qword [r8]
    cmp rax,r10
    jle near .store
    mov rax,r10
.store:
    mov qword [rcx],rax
    ret


global rosam_u64_min
rosam_u64_min:
    mov rax,qword [rcx]
    mov r8,qword [rdx]
    cmp rax,r8
    jbe near .done
    mov rax,r8
    mov qword [rcx],rax
.done: ret


global rosam_u64_max
rosam_u64_max:
    mov rax,qword [rcx]
    mov r8,qword [rdx]
    cmp rax,r8
    jae near .done
    mov rax,r8
    mov qword [rcx],rax
.done: ret


global rosam_u64_clamp
rosam_u64_clamp:
    mov rax,qword [rcx]
    mov r9,qword [rdx]
    cmp rax,r9
    jae near .hi
    mov rax,r9
.hi:
    mov r10,qword [r8]
    cmp rax,r10
    jbe near .store
    mov rax,r10
.store:
    mov qword [rcx],rax
    ret


global rosam_u32_add
rosam_u32_add:
    mov eax,dword [rcx]
    add eax,dword [rdx]
    mov dword [rcx],eax
    ret


global rosam_u32_sub
rosam_u32_sub:
    mov eax,dword [rcx]
    sub eax,dword [rdx]
    mov dword [rcx],eax
    ret


global rosam_u32_mul
rosam_u32_mul:
    mov eax,dword [rcx]
    imul eax,dword [rdx]
    mov dword [rcx],eax
    ret


global rosam_u32_div
rosam_u32_div:
    mov eax,dword [rcx]
    mov r8d,dword [rdx]
    test r8d,r8d
    jz near .zero
    xor edx,edx
    div r8d
    mov dword [rcx],eax
    ret
.zero:
    mov dword [rel rosam_linux_error],ROSAM_ERR_DIV_ZERO
    xor eax,eax
    ret


global rosam_u32_mod
rosam_u32_mod:
    mov eax,dword [rcx]
    mov r8d,dword [rdx]
    test r8d,r8d
    jz near .zero
    xor edx,edx
    div r8d
    mov dword [rcx],edx
    mov eax,edx
    ret
.zero:
    mov dword [rel rosam_linux_error],ROSAM_ERR_DIV_ZERO
    xor eax,eax
    ret


global rosam_u64_add
rosam_u64_add:
    mov rax,qword [rcx]
    add rax,qword [rdx]
    mov qword [rcx],rax
    ret


global rosam_u64_sub
rosam_u64_sub:
    mov rax,qword [rcx]
    sub rax,qword [rdx]
    mov qword [rcx],rax
    ret


global rosam_u64_mul
rosam_u64_mul:
    mov rax,qword [rcx]
    imul rax,qword [rdx]
    mov qword [rcx],rax
    ret


global rosam_u64_div
rosam_u64_div:
    mov rax,qword [rcx]
    mov r8,qword [rdx]
    test r8,r8
    jz near .zero
    xor edx,edx
    div r8
    mov qword [rcx],rax
    ret
.zero:
    mov dword [rel rosam_linux_error],ROSAM_ERR_DIV_ZERO
    xor eax,eax
    ret


global rosam_u64_mod
rosam_u64_mod:
    mov rax,qword [rcx]
    mov r8,qword [rdx]
    test r8,r8
    jz near .zero
    xor edx,edx
    div r8
    mov qword [rcx],rdx
    mov rax,rdx
    ret
.zero:
    mov dword [rel rosam_linux_error],ROSAM_ERR_DIV_ZERO
    xor eax,eax
    ret


global rosam_atoi_i32
rosam_atoi_i32:
    test rcx,rcx
    jz near .bad
    xor rax,rax
    xor r8d,r8d
    mov r9d,0
    cmp byte [rcx],'-'
    jne near .plus
    mov r8d,1
    inc rcx
    jmp near .digits
.plus:
    cmp byte [rcx],'+'
    jne near .digits
    inc rcx
.digits:
    movzx edx,byte [rcx]
    test dl,dl
    jz near .finish
    cmp dl,'0'
    jb near .bad
    cmp dl,'9'
    ja near .bad
    sub edx,'0'
    imul rax,rax,10
    add rax,rdx
    inc r9
    ; signed limits checked after accumulation
    jmp near .digits
.finish:
    test r8d,r8d
    jz near .positive_check
    mov edx,0x80000000
    cmp rax,rdx
    ja near .overflow
    neg rax
    movsxd rdx,eax
    mov eax,edx
    ret
.positive_check:
    cmp rax,2147483647
    ja near .overflow
    mov eax,eax
    ret
.overflow:
    mov dword [rel rosam_linux_error],ROSAM_ERR_OVERFLOW
    xor eax,eax
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_PARSE
    xor eax,eax
    ret


global rosam_atoi_i64
rosam_atoi_i64:
    test rcx,rcx
    jz near .bad
    xor rax,rax
    xor r8d,r8d
    cmp byte [rcx],'-'
    jne near .plus
    mov r8d,1
    inc rcx
    jmp near .digits
.plus:
    cmp byte [rcx],'+'
    jne near .digits
    inc rcx
.digits:
    movzx edx,byte [rcx]
    test dl,dl
    jz near .finish
    cmp dl,'0'
    jb near .bad
    cmp dl,'9'
    ja near .bad
    sub edx,'0'
    mov r9,rax
    imul rax,rax,10
    jo near .overflow
    add rax,rdx
    jc near .overflow
    inc rcx
    jmp near .digits
.finish:
    test r8d,r8d
    jz near .positive
    mov r10,0x8000000000000000
    cmp rax,r10
    ja near .overflow
    neg rax
    ret
.positive:
    mov r10,0x7fffffffffffffff
    cmp rax,r10
    ja near .overflow
    ret
.overflow:
    mov qword [rel rosam_linux_error],ROSAM_ERR_OVERFLOW
    xor eax,eax
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_PARSE
    xor eax,eax
    ret


global rosam_atou_u32
rosam_atou_u32:
    test rcx,rcx
    jz near .bad
    xor rax,rax
.loop:
    movzx edx,byte [rcx]
    test dl,dl
    jz near .done
    cmp dl,'0'
    jb near .bad
    cmp dl,'9'
    ja near .bad
    sub edx,'0'
    imul rax,rax,10
    add rax,rdx
    mov edx,0xffffffff
    cmp rax,rdx
    ja near .overflow
    inc rcx
    jmp near .loop
.done:
    ret
.overflow:
    mov dword [rel rosam_linux_error],ROSAM_ERR_OVERFLOW
    xor eax,eax
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_PARSE
    xor eax,eax
    ret


global rosam_atou_u64
rosam_atou_u64:
    test rcx,rcx
    jz near .bad
    xor rax,rax
    mov r8,1844674407370955161
.loop:
    movzx edx,byte [rcx]
    test dl,dl
    jz near .done
    cmp dl,'0'
    jb near .bad
    cmp dl,'9'
    ja near .bad
    sub edx,'0'
    cmp rax,r8
    ja near .overflow
    jne near .acc
    cmp edx,5
    ja near .overflow
.acc:
    imul rax,rax,10
    add rax,rdx
    inc rcx
    jmp near .loop
.done:
    ret
.overflow:
    mov qword [rel rosam_linux_error],ROSAM_ERR_OVERFLOW
    xor eax,eax
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_PARSE
    xor eax,eax
    ret


global rosam_itoa_i32
rosam_itoa_i32:
    test rcx,rcx
    jz near .bad
    mov r8,rcx
    movsxd rax,edx
    xor r10d,r10d
    test rax,rax
    jns near .positive
    mov byte [r8],'-'
    inc r8
    mov r10d,1
    neg rax
.positive:
    lea r9,[rel rosam_linux_int_buf+31]
    mov byte [r9],0
    test rax,rax
    jnz near .convert
    dec r9
    mov byte [r9],'0'
    jmp near .copy
.convert:
    mov r11,10
.loop:
    xor rdx,rdx
    div r11
    add dl,'0'
    dec r9
    mov [r9],dl
    test rax,rax
    jnz near .loop
.copy:
    xor eax,eax
.c_loop:
    mov dl,[r9+rax]
    mov [r8+rax],dl
    test dl,dl
    jz near .done
    inc eax
    jmp near .c_loop
.done:
    add eax,r10d
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_NULL
    xor eax,eax
    ret


global rosam_utoa_u32
rosam_utoa_u32:
    test rcx,rcx
    jz near .bad
    mov r8,rcx
    mov eax,edx
    lea r9,[rel rosam_linux_int_buf+31]
    mov byte [r9],0
    test eax,eax
    jnz near .convert
    dec r9
    mov byte [r9],'0'
    jmp near .copy
.convert:
    mov r11d,10
.loop:
    xor edx,edx
    div r11d
    add dl,'0'
    dec r9
    mov [r9],dl
    test eax,eax
    jnz near .loop
.copy:
    xor eax,eax
.c_loop:
    mov dl,[r9+rax]
    mov [r8+rax],dl
    test dl,dl
    jz near .done
    inc eax
    jmp near .c_loop
.done:
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_NULL
    xor eax,eax
    ret


global rosam_itoa_i64
rosam_itoa_i64:
    test rcx,rcx
    jz near .bad
    mov r8,rcx
    mov rax,rdx
    xor r10d,r10d
    test rax,rax
    jns near .positive
    mov byte [r8],'-'
    inc r8
    mov r10d,1
    neg rax
.positive:
    lea r9,[rel rosam_linux_int_buf+31]
    mov byte [r9],0
    test rax,rax
    jnz near .convert
    dec r9
    mov byte [r9],'0'
    jmp near .copy
.convert:
    mov r11,10
.loop:
    xor rdx,rdx
    div r11
    add dl,'0'
    dec r9
    mov [r9],dl
    test rax,rax
    jnz near .loop
.copy:
    xor eax,eax
.c_loop:
    mov dl,[r9+rax]
    mov [r8+rax],dl
    test dl,dl
    jz near .done
    inc eax
    jmp near .c_loop
.done:
    add eax,r10d
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_NULL
    xor eax,eax
    ret


global rosam_utoa_u64
rosam_utoa_u64:
    test rcx,rcx
    jz near .bad
    mov r8,rcx
    mov rax,rdx
    lea r9,[rel rosam_linux_int_buf+31]
    mov byte [r9],0
    test rax,rax
    jnz near .convert
    dec r9
    mov byte [r9],'0'
    jmp near .copy
.convert:
    mov r11,10
.loop:
    xor rdx,rdx
    div r11
    add dl,'0'
    dec r9
    mov [r9],dl
    test rax,rax
    jnz near .loop
.copy:
    xor eax,eax
.c_loop:
    mov dl,[r9+rax]
    mov [r8+rax],dl
    test dl,dl
    jz near .done
    inc eax
    jmp near .c_loop
.done:
    ret
.bad:
    mov dword [rel rosam_linux_error],ROSAM_ERR_NULL
    xor eax,eax
    ret


global rosam_log2_f64
rosam_log2_f64:
    movq xmm0,rdx; sub rsp,8; call log2; add rsp,8; movq rax,xmm0; ret


global rosam_i32_abs
rosam_i32_abs:
    mov eax,[rcx]
    test eax,eax
    jns near .done
    neg eax
    jo near .overflow
.done:
    mov [rcx],eax
    ret
.overflow:
    mov dword [rel rosam_linux_error],ROSAM_ERR_OVERFLOW
    ret

global rosam_i64_abs
rosam_i64_abs:
    mov rax,[rcx]
    test rax,rax
    jns near .done
    neg rax
    jo near .overflow
.done:
    mov [rcx],rax
    ret
.overflow:
    mov qword [rel rosam_linux_error],ROSAM_ERR_OVERFLOW
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
%endif
