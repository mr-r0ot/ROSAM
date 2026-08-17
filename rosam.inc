%ifndef ROSAM_INC_INCLUDED
%define ROSAM_INC_INCLUDED 1

%ifdef ROSAM_TARGET_LINUX_X64
    %include "platform/linux_x64.asm"
%else
%ifdef ROSAM_TARGET_MACOS_X64
    %include "platform/macos_x64.asm"
%else
    %include "platform/windows_x64.asm"
%endif
%endif

%include "core/core.inc"
%include "macros/macros.inc"

%endif
