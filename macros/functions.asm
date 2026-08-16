%ifndef ROSAM_MACROS_FUNCTIONS_INCLUDED
%define ROSAM_MACROS_FUNCTIONS_INCLUDED 1
%macro fn 1
%1:
%endmacro
%macro endfn 0
    ret
%endmacro
%macro return 0
    ret
%endmacro
%macro return_value 1
    ROSAM_RETURN_I32 %1
    ret
%endmacro
%macro return_i32 1
    ROSAM_RETURN_I32 %1
    ret
%endmacro
%macro return_i64 1
    ROSAM_RETURN_I64 %1
    ret
%endmacro
%macro call_fn 1
    ROSAM_CALL0 %1
%endmacro
%macro export_fn 1
    global %1
%endmacro
%macro extern_fn 1
    extern %1
%endmacro
%endif
