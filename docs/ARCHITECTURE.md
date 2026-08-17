# ROSAM Project Architecture

## Directory layout

```text
ROSAM/
│
├── core/
│   ├── memory.inc
│   ├── string.inc
│   ├── text.inc
│   ├── number.inc
│   ├── math.inc
│   ├── bit.inc
│   ├── array.inc
│   ├── algorithm.inc
│   ├── random.inc
│   ├── format.inc
│   ├── error.inc
│   └── core.inc
│
├── macros/
│   ├── variables.asm
│   ├── string.asm
│   ├── arithmetic.asm
│   ├── functions.asm
│   ├── control.asm
│   ├── arrays.asm
│   ├── io.asm
│   ├── misc.asm
│   └── macros.inc
│
├── platform/
│   ├── platform.inc
│   ├── windows_x64.asm
│   ├── linux_x64.asm
│   └── macos_x64.asm
│
├── examples/
├── rosam.inc
└── roasm.py
```

---

## Core

`core/` defines the public API contract.

It should not be responsible for:

- Windows handles,
- Linux syscall numbers,
- macOS system calls,
- compiler-specific linker details.

---

## Macros

`macros/` is the user-facing convenience layer.

Example:

```asm
add_i32 a, b
```

maps to the appropriate backend API adapter.

This lets application syntax remain stable while the ABI implementation changes.

---

## Platform

`platform/` contains target-specific implementations and adapter macros.

A backend is where things such as:

```text
calling convention
register allocation
OS primitives
ABI rules
object format
runtime implementation
```

belong.

---

## Application

`examples/` demonstrates the language.

A healthy architecture has:

```text
example → language API
```

not:

```text
example → private runtime
```

This is why `fin.asm` is treated as a stress test and not as a runtime extension.

---

# Include flow

`rosam.inc` selects the backend:

```asm
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
```

Then the application sees:

```text
platform
+
core API
+
macros
```

as one language environment.

---

# Portability model

Portability is achieved by preserving a stable logical API.

For example:

```text
rosam_io_write_buf
```

is a logical operation.

The Windows backend can implement it with Windows console APIs.

The Linux backend can implement it using Linux/POSIX mechanisms.

The application does not need to know the difference.

---

# Why this is important

If platform details leak into every program, ROSAM becomes:

```text
WinROSAM
LinuxROSAM
MacROSAM
```

instead of one language with several implementations.

The platform layer prevents that fragmentation.
