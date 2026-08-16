%ifndef ROSAM_MACROS_ARRAYS_INCLUDED
%define ROSAM_MACROS_ARRAYS_INCLUDED 1
%macro array_get_i32 3
    ROSAM_ARRAY_GET_I32 %1, %2, %3
%endmacro
%macro array_set_i32 3
    ROSAM_ARRAY_SET_I32 %1, %2, %3
%endmacro
%endif
