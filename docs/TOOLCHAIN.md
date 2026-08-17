# ROSAM Toolchain and `roasm.py`

## Overview

`roasm.py` is the build manager for ROSAM.

```text
source
  ↓
project discovery
  ↓
toolchain detection
  ↓
static analysis
  ↓
NASM
  ↓
object
  ↓
target linker/GCC
  ↓
executable
```

---

## Commands

### Run

```bash
python roasm.py run examples/test.asm
```

`run` automatically chooses the current host target.

It is intentionally not a cross-target command.

### Build

```bash
python roasm.py build examples/test.asm --target windows-x64
```

Target is required because cross-compilation must be explicit.

### Object only

```bash
python roasm.py obj examples/test.asm --target windows-x64
```

### Check

```bash
python roasm.py check examples/test.asm --target windows-x64
```

### Info

```bash
python roasm.py info examples/test.asm
```

---

## Target names

Current target names in the v0.6.1-oriented manager:

```text
windows-x86
windows-x64
linux-x86
linux-x64
macos-x64
```

Backends and toolchains determine what can actually be built.

---

## Custom tools

NASM executable:

```bash
--nasm "C:\Program Files\NASM\nasm.exe"
```

GCC executable:

```bash
--gcc "C:\msys64\mingw64\bin\gcc.exe"
```

A directory is also accepted:

```bash
--nasm "C:\Program Files\NASM"
--gcc "C:\msys64\mingw64\bin"
```

---

## Custom project root

```bash
--root C:\Projects\ROSAM
```

The manager also searches upward from the source directory.

---

## Output

```bash
-o build/my_program.exe
```

or:

```bash
-o build/my_program.obj
```

The manager creates missing parent directories.

---

## Safety controls

### External output

By default:

```text
output must stay inside the ROSAM project
```

To intentionally write elsewhere:

```bash
--allow-external-output
```

### External includes

Absolute includes outside the project are rejected by the project checker unless:

```bash
--allow-external-includes
```

is provided.

### Strict mode

```bash
--strict
```

converts advisory warnings into check failures.

### Disable analysis

```bash
--no-safety-scan
```

This should be reserved for specialized low-level experiments.

---

## Why `shell=False`?

The manager invokes programs directly rather than constructing a shell command line. This reduces accidental shell interpretation and is the correct approach when command arguments are already structured.

---

## Important cross-compilation rule

Do not assume:

```text
Windows GCC == Linux GCC
```

A MinGW GCC typically targets Windows:

```text
x86_64-w64-mingw32
```

A Linux cross compiler may target:

```text
x86_64-linux-gnu
```

The object format, ABI and linker target must agree.

---

## Smart backend selection

ROSAM source may already include the platform backend through:

```asm
%include "rosam.inc"
```

The build manager must not blindly assemble the same backend as a second object.

Correct dependency logic is:

```text
backend already in source include graph?
        │
      yes ───► don't compile it again
        │
       no
        │
        ▼
compile the selected backend as a companion object
```

This avoids linker errors such as:

```text
multiple definition of rosam_i32_add
```

---

## Typical Windows x64 build

```cmd
python roasm.py build examples\test.asm ^
    --target windows-x64 ^
    --nasm "C:\Program Files\NASM\nasm.exe" ^
    --gcc C:\msys64\mingw64\bin ^
    -o build\test.exe
```

---

## Typical Linux x64 build

On a Linux host:

```bash
python roasm.py build examples/test.asm \
    --target linux-x64 \
    -o build/test
```

On Windows, building Linux requires a Linux-targeting cross-linker/toolchain.

---

## Typical run

```bash
python roasm.py run examples/test.asm
```

On Windows this means:

```text
detect Windows + x64
→ build Win64
→ run Windows executable
```

On Linux x86-64:

```text
detect Linux + x64
→ build ELF64
→ run Linux executable
```
