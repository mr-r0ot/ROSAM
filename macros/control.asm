%ifndef ROSAM_MACROS_CONTROL_INCLUDED
%define ROSAM_MACROS_CONTROL_INCLUDED 1

%macro if_i32_eq 3
    ROSAM_CMP_I32_EQ %1, %2, %3
%endmacro
%macro if_i32_ne 3
    ROSAM_CMP_I32_NE %1, %2, %3
%endmacro
%macro if_i32_lt 3
    ROSAM_CMP_I32_LT %1, %2, %3
%endmacro
%macro if_i32_le 3
    ROSAM_CMP_I32_LE %1, %2, %3
%endmacro
%macro if_i32_gt 3
    ROSAM_CMP_I32_GT %1, %2, %3
%endmacro
%macro if_i32_ge 3
    ROSAM_CMP_I32_GE %1, %2, %3
%endmacro

%macro if_i32_eq_val 3
    ROSAM_CMP_I32_EQ_VAL %1, %2, %3
%endmacro
%macro if_i32_ne_val 3
    ROSAM_CMP_I32_NE_VAL %1, %2, %3
%endmacro
%macro if_i32_lt_val 3
    ROSAM_CMP_I32_LT_VAL %1, %2, %3
%endmacro
%macro if_i32_le_val 3
    ROSAM_CMP_I32_LE_VAL %1, %2, %3
%endmacro
%macro if_i32_gt_val 3
    ROSAM_CMP_I32_GT_VAL %1, %2, %3
%endmacro
%macro if_i32_ge_val 3
    ROSAM_CMP_I32_GE_VAL %1, %2, %3
%endmacro

%macro label 1
%1:
%endmacro

%macro goto 1
    jmp %1
%endmacro

%macro inc_i32 1
    ROSAM_I32_INC %1
%endmacro

%macro dec_i32 1
    ROSAM_I32_DEC %1
%endmacro

%macro loop_dec_i32 2
    ROSAM_LOOP_DEC_I32 %1, %2
%endmacro

%endif
