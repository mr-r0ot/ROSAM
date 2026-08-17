# ROSAM
ROSAM — A Low-Level Programming Language Compiled Directly to Native Assembly

**ROSAM — ROSTAM + ASM**

ROSAM is a small, assembly-oriented programming language and source/API layer designed to make low-level programming substantially easier to write, organize, learn, and port without hiding the underlying machine too aggressively.

Repository: **https://github.com/mr-r0ot/ROSAM**

> **Status:** ROSAM v0.6.1 is an experimental language/runtime architecture. The repository contains a broad API contract, macro-based language syntax, and platform backends. The stable demonstrated application subset is the Win64 console subset used by `fin.asm`; broader API parity depends on the backend.

---

## Note
1- README and .md files written by ai
2- python rich,base Designed by ai

---

## 1. Philosophy

Assembly is powerful, but raw assembly is an expensive programming interface.

A small program can quickly become dominated by:

- register preparation,
- syscall or OS ABI details,
- pointer setup,
- repetitive data declarations,
- manual comparison branches,
- function-call boilerplate,
- integer conversion,
- buffer management,
- platform-specific conventions.

ROSAM is an attempt to move one level upward without abandoning the fundamental properties that make assembly valuable.

The central idea is:

> **Keep the machine visible, but make the programmer spend their effort on the algorithm rather than repetitive ABI ceremony.**

ROSAM is therefore not intended to be a replacement for all assembly programming. It is intended to be a structured layer over assembly.

### Why the name ROSAM?

The name is a combination of:

**ROSTAM + ASM → ROSAM**

Rostam is one of the most recognizable heroic figures in Persian epic literature, especially the *Shahnameh*. The name was chosen as a cultural reference combined with **ASM**, the conventional abbreviation associated with assembly language.

The name reflects the project's intended character:

- low-level strength,
- directness,
- Persian identity,
- and assembly as the underlying foundation.

ROSAM is not an acronym for a collection of unrelated technical words. The name is primarily a **Rostam + Assembly** wordplay.

---

# 2. What ROSAM Actually Is

ROSAM is best understood as a **compiled assembly-oriented language layer**.

It has several layers:

```text
ROSAM source
     │
     ▼
ROSAM macros / language syntax
     │
     ▼
ABI-neutral API contracts
     │
     ▼
platform backend
     │
     ▼
NASM object file
     │
     ▼
system linker / GCC
     │
     ▼
native executable
```

A ROSAM program is still ultimately native machine code.

The important distinction is that the application author normally writes:

```asm
print welcome
input name
input_int firstnumber
add_i32 firstnumber, secondnumber
```

instead of manually preparing registers and invoking the OS ABI for every operation.

---

# 3. Core Characteristics

## 3.1 Assembly-level control

ROSAM does not introduce:

- a mandatory garbage collector,
- a hidden virtual machine,
- a bytecode runtime,
- a large managed runtime,
- automatic object allocation for ordinary variables.

The underlying model remains close to native memory and CPU execution.

## 3.2 A small language layer over assembly

Declarations, functions, control flow, I/O and arithmetic are exposed through macros and backend adapters.

For example:

```asm
i32 counter
i32 total

set_i32 counter, 10
set_i32 total, 0

add_i32 total, counter
```

This is still assembly-oriented code, but the repeated implementation details are encapsulated.

## 3.3 Platform separation

The public API is separated from platform implementation.

The project layout is approximately:

```text
ROSAM/
├── core/
├── macros/
├── platform/
├── examples/
├── rosam.inc
└── roasm.py
```

The important rule is:

> Application code consumes ROSAM. It should not normally contain WinAPI or raw Linux syscall implementation details just to perform ordinary language operations.

The platform layer is responsible for adapting ROSAM operations to the target ABI.

## 3.4 Explicit types

ROSAM exposes explicit storage types such as:

```asm
i8
i16
i32
i64

u8
u16
u32
u64

f32
f64
bool
char
ptr
```

The language does not attempt to erase the difference between integer widths.

That matters for low-level work.

---

# 4. Why Use ROSAM Instead of Raw Assembly?

Raw assembly remains better when:

- every instruction must be controlled manually,
- you are writing a tiny ABI boundary,
- you are developing a bootloader, kernel primitive, interrupt handler, or highly specialized optimized routine,
- instruction-level experimentation is the primary objective.

ROSAM becomes attractive when:

- you want assembly-level execution but faster application development,
- you repeatedly write console programs,
- you want reusable functions and data abstractions,
- you want a consistent API across platforms,
- you want a teaching language that exposes the machine instead of hiding it,
- you want to build medium-sized native programs without hand-writing every I/O and conversion sequence.

---

# 5. ROSAM vs C, C++, Rust, Python and Go

There is no universal "better" language. Each occupies a different point in the design space.

| Property | ROSAM | C | C++ | Rust | Go | Python |
|---|---|---|---|---|---|---|
| Abstraction level | Low | Low/medium | Medium/high | Medium/high | High | High |
| Native compilation | Yes | Yes | Yes | Yes | Yes | Usually bytecode/interpreter/JIT ecosystem |
| Direct assembly model | Core design | Possible | Possible | `unsafe`/inline mechanisms | Limited/advanced tooling | Via extensions/FFI |
| Manual memory model | Yes | Yes | Yes | Restricted by ownership rules | GC | GC/ref-counting implementation details |
| Garbage collector required | No | No | No | No | Yes | Yes |
| Ownership system | No | No | No | Yes | No | No |
| High-level standard library | Small by design | Large ecosystem | Very large ecosystem | Large ecosystem | Large standard library | Extremely large ecosystem |
| Runtime overhead | Potentially very low | Very low | Very low | Very low | Usually higher than C/Rust due to runtime/GC | High relative to native systems languages |
| Learning the machine | Excellent | Good | Moderate | Moderate | Lower | Low |
| Development speed | Medium | Medium | Medium/low | Medium | High | Very high |
| Memory safety guarantees | No automatic guarantee | No | No | Strong compile-time guarantees | GC-based | GC-based |
| Portability abstraction | ROSAM backend layer | Compiler/platform libraries | Compiler/platform libraries | Standard library/compiler targets | Excellent | Excellent |
| Best fit | Structured low-level native software | Systems programming | Large systems/software | Safe systems programming | Services/concurrency | Scripting/application development |

### ROSAM vs C

C is substantially more mature and has a vastly larger ecosystem.

ROSAM's advantage is not ecosystem size. Its advantage is that the programmer stays much closer to assembly while getting a reusable programming interface.

C gives you:

```c
int x = 10;
x += 5;
```

ROSAM intentionally exposes the low-level operation:

```asm
i32 x
set_i32 x, 10
add_i32 x, 5
```

That makes ROSAM more verbose than C but more explicit about the machine model.

### ROSAM vs C++

C++ provides far more abstraction:

- classes,
- templates,
- RAII,
- generic programming,
- exceptions,
- operator overloading,
- an enormous ecosystem.

ROSAM deliberately rejects most of that complexity.

ROSAM is therefore not a competitor to C++ for application-scale abstraction. It targets the opposite end of the design spectrum.

### ROSAM vs Rust

Rust is the strongest comparison from a systems-programming perspective.

Rust gives:

- ownership,
- borrowing,
- lifetimes,
- powerful generics,
- strong compile-time memory-safety guarantees,
- modern tooling.

ROSAM gives much more direct control over the underlying assembly model.

The trade-off is fundamental:

```text
Rust:
compiler proves many classes of memory errors.

ROSAM:
programmer has direct control and responsibility.
```

The current ROSAM source scanner can warn about suspicious memory operations, but those warnings are **not equivalent to Rust's ownership/borrow checker**.

### ROSAM vs Go

Go prioritizes productivity, simplicity, concurrency and a large standard library. Its official documentation describes it as statically typed, compiled and garbage-collected, with built-in concurrency mechanisms. citeturn191618view1

ROSAM makes almost the opposite trade:

```text
Go:
high productivity + runtime services

ROSAM:
low runtime abstraction + direct machine model
```

### ROSAM vs Python

Python emphasizes concise syntax, dynamic typing, high-level data structures and rapid application development. citeturn191618view2

ROSAM intentionally sacrifices that convenience for:

- deterministic low-level control,
- native memory visibility,
- explicit data widths,
- minimal runtime assumptions.

Python is dramatically better for most scripting, automation and rapid application development. ROSAM is dramatically closer to the machine.

---

# 6. When ROSAM Is a Good Choice

ROSAM is particularly interesting for:

- systems programming education,
- assembly education,
- algorithm experimentation,
- low-level utilities,
- small native applications,
- performance-sensitive routines,
- compiler/backend experimentation,
- OS internals education,
- embedded-oriented language experimentation,
- learning how high-level language constructs eventually map toward machine execution.

ROSAM is currently **not** the right choice if you need:

- a mature package ecosystem,
- production-grade memory safety,
- enterprise framework support,
- a massive standard library,
- a mature IDE ecosystem,
- stable multi-platform ABI parity across every advertised target.

---

# 7. Installation

ROSAM itself is source-based. You need:

- Python 3
- `rich`
- NASM
- GCC or a compatible target linker/toolchain

Install Rich:

```bash
python -m pip install rich
```

Verify:

```bash
python --version
nasm -v
gcc --version
```

For a non-host target, you need a compiler/linker that actually produces that target.

For example, a Windows MinGW GCC such as:

```text
x86_64-w64-mingw32-gcc
```

is a Windows-targeting compiler. It is **not** a Linux linker just because NASM can generate an ELF object.

---

# 8. `roasm.py`

`roasm.py` is the ROSAM project manager/build driver.

The main modes are:

```text
run
build
obj
check
info
```

## `run`

Builds for the current machine automatically and executes the resulting program.

```bash
python roasm.py run examples/test.asm
```

You do not specify `--target`.

The manager detects:

```text
Operating system
CPU architecture
```

and chooses the host target when a supported backend exists.

## `build`

Creates an executable.

The target must be explicit:

```bash
python roasm.py build examples/test.asm --target windows-x64
```

or:

```bash
python roasm.py build examples/test.asm --target linux-x64
```

You can specify an output:

```bash
python roasm.py build examples/test.asm \
    --target windows-x64 \
    -o build/my_program.exe
```

## `obj`

Produces an object file only.

```bash
python roasm.py obj examples/test.asm --target windows-x64
```

Linux:

```bash
python roasm.py obj examples/test.asm --target linux-x64
```

The exact object suffix depends on the target/toolchain convention.

---

# 9. Tool Paths

ROSAM can locate tools through `PATH`.

You can also explicitly specify them.

NASM executable:

```bash
python roasm.py build examples/test.asm \
    --target windows-x64 \
    --nasm "C:\Program Files\NASM\nasm.exe"
```

NASM directory:

```bash
python roasm.py build examples/test.asm \
    --target windows-x64 \
    --nasm "C:\Program Files\NASM"
```

GCC executable:

```bash
python roasm.py build examples/test.asm \
    --target windows-x64 \
    --gcc "C:\msys64\mingw64\bin\gcc.exe"
```

GCC directory:

```bash
python roasm.py build examples/test.asm \
    --target windows-x64 \
    --gcc "C:\msys64\mingw64\bin"
```

The toolchain is checked before compilation starts.

---

# 10. Project Root Detection

By default ROSAM searches upward for:

```text
core/
macros/
platform/
```

You can explicitly choose a project:

```bash
python roasm.py build examples/test.asm \
    --target windows-x64 \
    --root C:\Projects\ROSAM
```

You can also use:

```text
ROSAM_ROOT
```

as an environment variable.

---

# 11. ROSAM Source File Types

ROSAM accepts:

```text
.asm
.roasm
```

The current implementation uses NASM as the assembler backend.

The `.roasm` extension is therefore a source-language convention; the backend ultimately consumes NASM-compatible assembly syntax generated/expanded through ROSAM's macro layer.

---

# 12. What `roasm.py` Does

A normal build is conceptually:

```text
1. Locate source
2. Locate ROSAM project
3. Determine target
4. Locate NASM/GCC
5. Check dependencies
6. Analyze the source/include graph
7. Select platform backend
8. Assemble
9. Link
10. Verify output
11. Run if requested
```

---

# 13. Understanding the Build Output

A line such as:

```text
$ "C:\Program Files\NASM\nasm.exe" -f win64 ...
```

means the manager is invoking NASM.

This:

```text
-f win64
```

selects the NASM object format.

For Linux x86-64:

```text
-f elf64
```

For example:

```text
ROSAM_TARGET_WINDOWS_X64
```

is a build-time target definition.

It lets platform/backend code choose the selected implementation.

---

# 14. Safety and Static Analysis

ROSAM does not claim to be memory-safe in the Rust sense.

The current manager can inspect the source graph and report suspicious constructs such as:

- direct memory accesses,
- raw pointer/address use,
- manual allocation/free,
- unbounded string operations,
- direct syscalls,
- shell/process execution,
- destructive OS operations.

The important policy is:

> These are warnings, not a substitute for a formal memory-safety system.

Normal builds should not be stopped merely because the program intentionally uses low-level operations.

Use strict mode only when desired:

```bash
python roasm.py check examples/test.asm \
    --target windows-x64 \
    --strict
```

---

# 15. First ROSAM Program

A minimal program:

```asm
%include "rosam.inc"

section .data

str hello, "Hello, ROSAM!", 13, 10

section .text

export_fn main

fn main

    print hello
    return_value 0

endfn
```

The important structural pieces are:

```asm
%include "rosam.inc"
```

Loads the ROSAM public language/runtime layer.

```asm
section .data
```

Contains initialized static data.

```asm
section .text
```

Contains executable code.

```asm
export_fn main
```

Exports the program entry symbol for the external linker.

```asm
fn main
...
endfn
```

Defines a function.

---

# 16. Variables

ROSAM provides explicit declarations.

## Integer types

```asm
i8 a
i16 b
i32 c
i64 d

u8 e
u16 f
u32 g
u64 h
```

Floating point:

```asm
f32 x
f64 y
```

Boolean and character:

```asm
bool ready
char letter
```

Pointer storage:

```asm
ptr address
```

Constants:

```asm
const SIZE, 64
```

---

# 17. Strings

A static string:

```asm
str message, "Hello"
```

ROSAM adds a terminating NUL byte and creates:

```text
message
message_len
```

You can use:

```asm
print message
```

A larger buffer:

```asm
buffer name, 64
```

This creates:

```text
name
name_size
name_len
```

and is intended for runtime data.

---

# 18. Input

Console input:

```asm
buffer name, 64
input name
```

The current input macro uses the buffer's capacity and maintains its runtime length.

Integer input:

```asm
i32 age
input_int age
```

---

# 19. Output

Static string:

```asm
print message
```

Dynamic buffer:

```asm
print_buf name
```

New line:

```asm
println
```

Integers:

```asm
print_i32 number
print_i64 number
```

---

# 20. Arithmetic

ROSAM uses explicit arithmetic operations.

```asm
add_i32 a, b
sub_i32 a, b
mul_i32 a, b
div_i32 a, b
mod_i32 a, b
```

Likewise for 64-bit integers:

```asm
add_i64 a, b
sub_i64 a, b
mul_i64 a, b
div_i64 a, b
mod_i64 a, b
```

The exact operand semantics are defined by the backend API contract.

---

# 21. Assignment

```asm
set_i32 counter, 10
```

Copy a value from one i32 object to another:

```asm
copy_i32 destination, source
```

Zero a value:

```asm
zero_i32 counter
```

---

# 22. Increment and Decrement

```asm
inc_i32 counter
dec_i32 counter
```

These are ROSAM abstractions over the backend implementation.

---

# 23. Comparisons

Variable-to-variable:

```asm
if_i32_eq a, b, equal_label
if_i32_ne a, b, not_equal_label
if_i32_lt a, b, less_label
if_i32_le a, b, less_or_equal_label
if_i32_gt a, b, greater_label
if_i32_ge a, b, greater_or_equal_label
```

Variable-to-value:

```asm
if_i32_eq_val counter, 10, done
if_i32_gt_val counter, 10, large
```

---

# 24. Labels and Goto

Define a label:

```asm
label loop_start
```

Jump:

```asm
goto loop_start
```

This is deliberately low-level.

ROSAM does not pretend that a jump is something fundamentally different from a control-flow branch.

---

# 25. Loops

The current macro layer provides:

```asm
loop_dec_i32 counter, loop_start
```

Typical pattern:

```asm
set_i32 counter, 10

label loop_start

    print message

    dec_i32 counter
    if_i32_gt_val counter, 0, loop_start
```

For complex algorithms, explicit labels and branches are often clearer than trying to force every loop into a high-level syntax.

---

# 26. Functions

Define:

```asm
fn calculate
    ...
endfn
```

or:

```asm
fn calculate
    ...
    return
endfn
```

Return an i32:

```asm
return_i32 result
```

or:

```asm
return_value result
```

Call:

```asm
call_fn calculate
```

Export:

```asm
export_fn main
```

Declare an external function:

```asm
extern_fn some_function
```

---

# 27. Arrays

Fixed i32 arrays:

```asm
array_i32 values, 10
```

The macro also exposes:

```text
values_count
values_size
```

Runtime-index access:

```asm
array_get_i32 values, index, result
array_set_i32 values, index, value
```

This is one of the more important distinctions between ROSAM and writing every indexed-memory operation manually.

---

# 28. String API

The v0.6.1 core contract includes:

```text
rosam_str_len
rosam_str_nlen
rosam_str_copy
rosam_str_copy_n
rosam_str_concat
rosam_str_concat_n
rosam_str_compare
rosam_str_compare_n
rosam_str_equal
rosam_str_equal_n
rosam_str_equal_ignorecase
rosam_str_find
rosam_str_char
rosam_str_char_last
rosam_str_prefix
rosam_str_suffix
rosam_str_contains
rosam_str_reverse
rosam_str_to_upper
rosam_str_to_lower
rosam_str_trim
rosam_str_trim_left
rosam_str_trim_right
rosam_str_replace_char
rosam_str_duplicate
rosam_str_duplicate_n
rosam_str_count_char
rosam_str_count_substr
```

The high-level macro layer currently exposes the most common operations such as:

```asm
str_copy destination, source
str_equal a, b, label
```

The remaining API surface is available as the core/backend contract rather than necessarily having a dedicated high-level macro for every function.

---

# 29. Text and UTF-8

The text contract includes:

```text
ASCII classification:
    ascii_is_alpha
    ascii_is_digit
    ascii_is_alnum
    ascii_is_space
    ascii_is_upper
    ascii_is_lower

ASCII conversion:
    ascii_to_upper
    ascii_to_lower

UTF-8:
    utf8_len
    utf8_char_count
    utf8_next
    utf8_prev
    utf8_decode
    utf8_encode
    utf8_is_valid
    utf8_validate
    utf8_char_at
```

These operations exist because byte-oriented assembly and human text are not the same abstraction.

---

# 30. Memory API

Core memory operations include:

```text
mem_copy
mem_move
mem_set
mem_zero
mem_compare
mem_equal
mem_find

mem_alloc
mem_calloc
mem_realloc
mem_free
```

This is explicit memory management.

It is powerful, but it is also a responsibility.

---

# 31. Numeric API

Signed:

```text
i32_add
i32_sub
i32_mul
i32_div
i32_mod
i32_abs
i32_min
i32_max
i32_clamp

i64_add
i64_sub
i64_mul
i64_div
i64_mod
i64_abs
i64_min
i64_max
i64_clamp
```

Unsigned:

```text
u32_add
u32_sub
u32_mul
u32_div
u32_mod
u32_min
u32_max
u32_clamp

u64_add
u64_sub
u64_mul
u64_div
u64_mod
u64_min
u64_max
u64_clamp
```

String conversion:

```text
atoi_i32
itoa_i32
atoi_i64
itoa_i64
atou_u32
utoa_u32
atou_u64
utoa_u64
```

---

# 32. Mathematics

The math API includes integer functions:

```text
gcd
lcm
pow_i32
is_power2
floor_log2
ceil_log2
```

Floating-point functions:

```text
sqrt_f64
cbrt_f64

sin_f64
cos_f64
tan_f64

asin_f64
acos_f64
atan_f64
atan2_f64

sinh_f64
cosh_f64
tanh_f64

exp_f64
log_f64
log10_f64
log2_f64
pow_f64

floor_f64
ceil_f64
round_f64
trunc_f64

is_nan_f64
is_inf_f64
is_finite_f64
```

The implementation may depend on the platform's math facilities.

---

# 33. Bit Operations

The bit API contains:

```text
bit_set
bit_clear
bit_toggle
bit_test

bit_shl
bit_shr
bit_sar

bit_rol
bit_ror

bit_popcount
bit_clz
bit_ctz
bit_parity

bit_is_power2
bit_next_power2
bit_prev_power2

bswap16
bswap32
bswap64

bit_reverse8
bit_reverse16
bit_reverse32
bit_reverse64
```

This is especially useful for:

- binary protocols,
- packed data,
- parsers,
- cryptographic primitives,
- embedded work,
- serialization.

---

# 34. Arrays, Vectors, Stack and Deque

Array operations include:

```text
array_copy
array_fill
array_reverse
array_find
array_contains
array_sort
array_get
array_set
```

Dynamic vectors:

```text
vec_create
vec_destroy
vec_push
vec_pop
vec_get
vec_set
vec_len
vec_capacity
vec_reserve
vec_resize
vec_clear
```

Stack:

```text
stack_create
stack_destroy
stack_push
stack_pop
stack_peek
stack_len
```

Deque:

```text
deque_push_front
deque_push_back
deque_pop_front
deque_pop_back
```

---

# 35. Algorithms

The algorithm API includes:

```text
linear_search
binary_search

sort
quick_sort
merge_sort
heap_sort
insertion_sort

reverse
find_min
find_max
sum
product
count
count_if

any
all
none

copy_if
transform
fill
partition
stable_partition
prefix_sum
```

The exact callback/iterator contract is backend/API dependent. ROSAM keeps the API explicit because implicit high-level iteration can hide too much of the machine model.

---

# 36. Random Numbers

The API includes:

```text
rng_init
rng_seed

rng_u8
rng_u16
rng_u32
rng_u64

rng_i32
rng_i64

rng_float
rng_double

rng_range
rng_bytes
rng_uniform
rng_boolean

rng_shuffle
rng_choice

secure_random
```

`secure_random` should be treated differently from a normal pseudo-random generator. A cryptographic/security-sensitive application should still review the backend implementation and operating-system entropy source before relying on it for security credentials or cryptographic keys.

---

# 37. Formatting

Formatting operations:

```text
format_i8
format_i16
format_i32
format_i64

format_u8
format_u16
format_u32
format_u64

format_bin
format_oct
format_dec
format_hex

format_f32
format_f64

format_char
format_bool

format_append
format_value
```

This layer is intended to keep repetitive conversion logic out of application code.

---

# 38. Error Handling

The core API defines:

```text
ROSAM_ERR_NONE
ROSAM_ERR_INVALID_ARGUMENT
ROSAM_ERR_NULL
ROSAM_ERR_OVERFLOW
ROSAM_ERR_UNDERFLOW
ROSAM_ERR_OUT_OF_MEMORY
ROSAM_ERR_OUT_OF_RANGE
ROSAM_ERR_DIV_ZERO
ROSAM_ERR_PARSE
ROSAM_ERR_ENCODING
ROSAM_ERR_NOT_FOUND
ROSAM_ERR_UNSUPPORTED
ROSAM_ERR_IO
ROSAM_ERR_INVALID_STATE
```

Operations:

```asm
clear_error
set_error code
get_error
```

The core also exposes:

```text
error_clear
error_set
error_get
error_has
error_code
error_name
error_message
```

A systems language must expose failure states explicitly. ROSAM therefore does not assume that every operation succeeds.

---

# 39. Program Exit

The language exposes:

```asm
exit 0
```

and function-style return:

```asm
return_value 0
```

These are different concepts:

```text
return
    leaves a function

exit
    terminates the process
```

---

# 40. Complete Example

The following is a representative ROSAM program using the current stable console subset:

```asm
%include "rosam.inc"

section .data

str welcome, "Welcome to ROSAM!", 13, 10
str ask_name, "Name: "
str hello, "Hello "
str ask_a, "First number: "
str ask_b, "Second number: "
str result, "Result: "

section .bss

buffer name, 64
i32 a
i32 b

section .text

export_fn main

fn main

    print welcome

    print ask_name
    input name

    print hello
    print_buf name
    println

    print ask_a
    input_int a
    println

    print ask_b
    input_int b
    println

    add_i32 a, b

    print result
    print_i32 a
    println

    return_value 0

endfn
```

The application author never needs to write:

```text
Windows console handles
ReadFile/WriteFile calls
Linux syscalls
register preparation
calling-convention adapters
integer formatting implementation
```

Those belong to the runtime/backend.

---

# 41. The `fin.asm` Demonstration

`fin.asm` is intentionally a stress-test application rather than a language extension.

It demonstrates:

```text
Login system
├── username storage
├── password storage
├── multiple attempts
└── credential update

Calculator
├── addition
├── subtraction
├── multiplication
├── division
└── modulo

Algorithms
├── square
├── triangle
├── pyramid
└── hollow rectangle

Machine learning
└── online perceptron

Data structures
└── fixed runtime-indexed arrays
```

The included perceptron demonstrates a small actual training loop over an AND dataset rather than merely presenting an `if` statement under a "machine learning" label.

The project documentation currently describes a 10-epoch run that reaches 100% accuracy on the four-sample AND dataset.

---

# 42. Architecture

ROSAM separates responsibilities.

## `core/`

The core directory contains the API contract.

For example:

```text
core/string.inc
core/memory.inc
core/text.inc
core/number.inc
core/math.inc
core/bit.inc
core/array.inc
core/algorithm.inc
core/random.inc
core/format.inc
core/error.inc
```

These files declare the public runtime symbols.

## `macros/`

Macros provide the programmer-friendly source syntax.

For example:

```text
variables.asm
string.asm
arithmetic.asm
functions.asm
control.asm
arrays.asm
io.asm
misc.asm
```

The macros translate short ROSAM source statements into calls to the core API.

## `platform/`

Platform files implement the actual target-specific behavior.

A backend is responsible for:

- ABI conventions,
- operating-system interfaces,
- runtime primitives,
- target-specific calling rules,
- target-specific object/linking constraints.

## `rosam.inc`

This is the public entry point.

It selects the platform and then includes the core and macro layers.

---

# 43. Why the Platform Layer Exists

Assembly source is not automatically portable.

The same logical operation can require completely different mechanisms:

```text
Windows:
    Win32 / Windows x64 ABI

Linux:
    Linux x86-64 ABI / ELF

macOS:
    Mach-O / Darwin ABI
```

The goal of ROSAM is therefore not:

> "Write one magic assembly instruction that works everywhere."

The goal is:

> "Expose one logical ROSAM API and let each backend implement that API for the target."

That is real portability engineering.

---

# 44. Object Files and Linking

NASM does not create the final executable by itself.

Conceptually:

```text
ROSAM source
    ↓
NASM
    ↓
object file
    ↓
linker/compiler driver
    ↓
executable
```

For Windows x64:

```text
.asm
 ↓
NASM -f win64
 ↓
COFF/Win64 object
 ↓
GCC/MinGW linker
 ↓
.exe
```

For Linux x86-64:

```text
.asm
 ↓
NASM -f elf64
 ↓
ELF object
 ↓
Linux-compatible linker
 ↓
ELF executable
```

A Windows MinGW GCC is not automatically a Linux linker just because NASM can produce an ELF object. The compiler/linker target must match the object format and final target ABI.

---

# 45. Cross-Compilation

`build` and `obj` require an explicit target because cross-compilation must be intentional:

```bash
roasm build program.asm --target linux-x64
```

`run` is different:

```bash
roasm run program.asm
```

The driver detects the current host target because running a Linux executable on Windows is not equivalent to building one.

For cross-compilation, the appropriate assembler/linker/toolchain must exist.

---

# 46. Recommended Development Workflow

Start with:

```bash
python roasm.py check examples/test.asm
```

Then:

```bash
python roasm.py run examples/test.asm
```

For a release-style build:

```bash
python roasm.py build examples/test.asm \
    --target windows-x64 \
    -o build/test.exe
```

For object-only work:

```bash
python roasm.py obj examples/test.asm \
    --target windows-x64 \
    -o build/test.obj
```

Inspect project/toolchain information:

```bash
python roasm.py info examples/test.asm
```

---

# 47. Debugging Build Failures

When NASM reports:

```text
symbol X not defined
```

check:

1. Is the correct core declaration included?
2. Does the selected platform backend implement it?
3. Is the symbol name exact?
4. Is the backend already included by `rosam.inc`?
5. Did the build manager accidentally assemble/link the same backend twice?

When GCC reports:

```text
multiple definition of X
```

the usual cause is duplicate compilation of a platform implementation that was already `%include`d into the main source.

When GCC reports:

```text
undefined reference to ...
```

check:

- target ABI,
- required linker libraries,
- whether the correct platform backend is present,
- whether the selected GCC is actually targeting the requested OS/architecture.

When NASM reports:

```text
invalid effective address: too many registers
```

remember that x86 addressing is limited to a base plus an index, with an optional scale and displacement. Three independent registers cannot be placed directly inside one effective-address expression.

---

# 48. Design Principles

ROSAM follows several deliberately strict principles.

### Machine visibility

The language should remain close enough to assembly that the programmer can reason about generated behavior.

### Explicit data

Widths and storage are explicit.

### Small syntax

High-frequency operations should be short.

### Backend isolation

OS-specific code belongs in platform implementations.

### No project-specific language extensions

Examples such as `fin.asm` must consume the language rather than redefining it.

### Explicit failure

Errors should be representable in the API rather than silently ignored.

### Gradual safety

Static analysis may warn about suspicious low-level behavior without pretending that assembly can be made memory-safe by a simple lint pass.

---

# 49. What ROSAM Is Not

ROSAM is not:

- a C replacement,
- a Rust replacement,
- a garbage-collected language,
- a managed VM language,
- a universal optimizer,
- an OS abstraction that hides the machine,
- a guarantee of memory safety.

Its purpose is narrower:

> **Make structured native low-level programming easier without removing the underlying assembly model.**

---

# 50. Current Limitations

ROSAM v0.6.1 is an experimental project.

Important limitations include:

- platform parity is not yet identical,
- the broad core API is larger than the stable demonstrated application subset,
- memory safety is advisory rather than formally enforced,
- toolchain compatibility depends on the selected target,
- the macro system is intentionally close to NASM,
- APIs that require complex callback/iterator semantics are lower-level than their equivalents in modern high-level languages,
- cross-platform compilation requires actual target toolchains.

These are design/status facts, not hidden limitations.

---

# 51. Roadmap Direction

A natural future direction for ROSAM is:

```text
Current:
    macros
    core API
    platform backends
    roasm.py

Next:
    stronger type checking
    stronger static analysis
    better diagnostics
    target-aware toolchains
    automated backend tests
    debugger integration
    package/module model
    more complete backend parity
```

The important constraint is that new features should remain **language features**, not hacks added solely so one example program can compile.

---

# 52. License and Contributions

See the repository for the current license and contribution policy:

**https://github.com/mr-r0ot/ROSAM**

Contributions should preserve the separation between:

```text
core API
macros
platform implementation
application examples
build tooling
```

A new example should consume the language. It should not quietly become part of the runtime simply because the example needs a feature.

---

# 53. Final Mental Model

The simplest way to understand ROSAM is:

```text
                ROSAM PROGRAM
                       │
                       ▼
             Programmer-friendly
                 macro syntax
                       │
                       ▼
               ROSAM core API
                       │
                       ▼
              Platform backend
                       │
             ┌─────────┴─────────┐
             ▼                   ▼
          Win64                Linux
             ▼                   ▼
          NASM                 NASM
             ▼                   ▼
        Native object       Native object
             │                   │
             └─────────┬─────────┘
                       ▼
                    linker
                       ▼
                 native program
```

ROSAM's central proposition is therefore simple:

> **Keep the power and transparency of assembly, but give the programmer a small language and reusable runtime interface on top of it.**
