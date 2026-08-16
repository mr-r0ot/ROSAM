%ifndef ROSAM_MACROS_MISC_INCLUDED
%define ROSAM_MACROS_MISC_INCLUDED 1
%macro clear_error 0
    ROSAM_CALL0 rosam_error_clear
%endmacro
%macro set_error 1
    ROSAM_VALUE_CALL1 rosam_error_set, %1
%endmacro
%macro get_error 0
    ROSAM_CALL0 rosam_error_get
%endmacro
%endif
