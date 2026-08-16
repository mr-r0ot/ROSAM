%ifndef ROSAM_MACROS_VARIABLES_INCLUDED
%define ROSAM_MACROS_VARIABLES_INCLUDED 1

; Assembly data-definition helpers. Put declarations in the intended section.
%macro i8 1
%1: resb 1
%endmacro
%macro i16 1
%1: resw 1
%endmacro
%macro i32 1
%1: resd 1
%endmacro
%macro i64 1
%1: resq 1
%endmacro
%macro u8 1
%1: resb 1
%endmacro
%macro u16 1
%1: resw 1
%endmacro
%macro u32 1
%1: resd 1
%endmacro
%macro u64 1
%1: resq 1
%endmacro
%macro f32 1
%1: resd 1
%endmacro
%macro f64 1
%1: resq 1
%endmacro
%macro bool 1
%1: resb 1
%endmacro
%macro char 1
%1: resb 1
%endmacro
%macro ptr 1
%1: resq 1
%endmacro
%macro const 2
%1 equ %2
%endmacro

; str NAME, payload[, payload...]
; Emits a NUL terminator and exposes NAME_len excluding it.
; Greedy parameters are intentional and supported by NASM.
%macro str 2+
%1:
    db %2, 0
%1_len equ $ - %1 - 1
%endmacro

; buffer NAME, CAPACITY
; Data area has CAPACITY+1 bytes so input can always place NUL.
; NAME_size is compile-time capacity; NAME_len is runtime qword length.
%macro buffer 2
%1:
    resb (%2 + 1)
%1_size equ %2
%1_len:
    resq 1
%endmacro

%macro array_i32 2
%1: times %2 dd 0
%1_count equ %2
%1_size equ (%2 * 4)
%endmacro

%endif
