%ifndef ROSAM_MACROS_IO_INCLUDED
%define ROSAM_MACROS_IO_INCLUDED 1
%macro print 1
    ROSAM_ADDR_IMM_CALL2 rosam_io_write_buf, %1, %1_len
%endmacro
%macro print_buf 1
    ROSAM_ADDR_MEM_CALL2 rosam_io_write_buf, %1, %1_len
%endmacro
%macro println 0
    ROSAM_CALL0 rosam_io_println
%endmacro
%macro input 1
    ROSAM_ADDR_IMM_ADDR_CALL3 rosam_io_input, %1, %1_size, %1_len
%endmacro
%macro input_int 1
    ROSAM_ADDR_CALL1 rosam_io_input_i32, %1
%endmacro
%macro print_i32 1
    ROSAM_ADDR_CALL1 rosam_io_print_i32, %1
%endmacro
%macro print_i64 1
    ROSAM_ADDR_CALL1 rosam_io_print_i64, %1
%endmacro
%macro exit 1
    ROSAM_EXIT %1
%endmacro
%endif
