; Backend contract. Each target must provide these adapter macros and symbols:
; ROSAM_CALL0, ROSAM_ADDR_CALL1, ROSAM_VALUE_CALL1,
; ROSAM_ADDR_ADDR_CALL2, ROSAM_ADDR_IMM_CALL2,
; ROSAM_ADDR_MEM_CALL2, ROSAM_ADDR_IMM_ADDR_CALL3,
; ROSAM_RETURN_I32, ROSAM_RETURN_I64, ROSAM_EXIT,
; comparison/loop/array adapters used by macros.
