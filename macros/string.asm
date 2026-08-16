%ifndef ROSAM_MACROS_STRING_INCLUDED
%define ROSAM_MACROS_STRING_INCLUDED 1

%macro str_copy 2
    ROSAM_ADDR_ADDR_CALL2 rosam_str_copy, %1, %2
%endmacro

%macro str_equal 3
    ROSAM_STR_EQUAL_BRANCH %1, %2, %3
%endmacro

%macro str_equal_to 3
    ROSAM_STR_EQUAL_STORE %1, %2, %3
%endmacro

%endif
