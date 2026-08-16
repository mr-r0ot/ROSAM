%ifndef ROSAM_CORE_ERROR_INC_INCLUDED
%define ROSAM_CORE_ERROR_INC_INCLUDED 1
%define ROSAM_ERR_NONE              0
%define ROSAM_ERR_INVALID_ARGUMENT  1
%define ROSAM_ERR_NULL              2
%define ROSAM_ERR_OVERFLOW          3
%define ROSAM_ERR_UNDERFLOW         4
%define ROSAM_ERR_OUT_OF_MEMORY     5
%define ROSAM_ERR_OUT_OF_RANGE      6
%define ROSAM_ERR_DIV_ZERO          7
%define ROSAM_ERR_PARSE             8
%define ROSAM_ERR_ENCODING          9
%define ROSAM_ERR_NOT_FOUND         10
%define ROSAM_ERR_UNSUPPORTED       11
%define ROSAM_ERR_IO                12
%define ROSAM_ERR_INVALID_STATE     13
extern rosam_error_clear
extern rosam_error_set
extern rosam_error_get
extern rosam_error_has
extern rosam_error_code
extern rosam_error_name
extern rosam_error_message
%endif
