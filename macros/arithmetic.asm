%ifndef ROSAM_MACROS_ARITHMETIC_INCLUDED
%define ROSAM_MACROS_ARITHMETIC_INCLUDED 1

%macro set_i32 2
    ROSAM_ADDR_IMM_CALL2 rosam_set_i32, %1, %2
%endmacro
%macro copy_i32 2
    ROSAM_ADDR_ADDR_CALL2 rosam_copy_i32, %1, %2
%endmacro
%macro zero_i32 1
    ROSAM_ADDR_CALL1 rosam_zero_i32, %1
%endmacro
%macro add_i32 2
    ROSAM_ADDR_ADDR_CALL2 rosam_i32_add, %1, %2
%endmacro
%macro sub_i32 2
    ROSAM_ADDR_ADDR_CALL2 rosam_i32_sub, %1, %2
%endmacro
%macro mul_i32 2
    ROSAM_ADDR_ADDR_CALL2 rosam_i32_mul, %1, %2
%endmacro
%macro div_i32 2
    ROSAM_ADDR_ADDR_CALL2 rosam_i32_div, %1, %2
%endmacro
%macro mod_i32 2
    ROSAM_ADDR_ADDR_CALL2 rosam_i32_mod, %1, %2
%endmacro
%macro add_i64 2
    ROSAM_ADDR_ADDR_CALL2 rosam_i64_add, %1, %2
%endmacro
%macro sub_i64 2
    ROSAM_ADDR_ADDR_CALL2 rosam_i64_sub, %1, %2
%endmacro
%macro mul_i64 2
    ROSAM_ADDR_ADDR_CALL2 rosam_i64_mul, %1, %2
%endmacro
%macro div_i64 2
    ROSAM_ADDR_ADDR_CALL2 rosam_i64_div, %1, %2
%endmacro
%macro mod_i64 2
    ROSAM_ADDR_ADDR_CALL2 rosam_i64_mod, %1, %2
%endmacro

%endif
