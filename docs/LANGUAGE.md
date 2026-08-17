# ROSAM Language Reference

## 1. Source structure

A typical program has:

```asm
%include "rosam.inc"

section .data
; static initialized data

section .bss
; runtime storage

section .text
; code

export_fn main

fn main
    ...
    return_value 0
endfn
```

The syntax is intentionally NASM-compatible.

---

# 2. Sections

## `.data`

Use for initialized/static data:

```asm
section .data

str hello, "Hello", 13, 10
```

## `.bss`

Use for runtime storage:

```asm
section .bss

i32 value
buffer name, 64
array_i32 values, 10
```

## `.text`

Executable code:

```asm
section .text
```

---

# 3. Variables

```asm
i8 a
i16 b
i32 c
i64 d

u8 e
u16 f
u32 g
u64 h

f32 x
f64 y

bool ready
char ch
ptr p
```

Constants:

```asm
const LIMIT, 100
```

---

# 4. Strings

```asm
str hello, "Hello", 13, 10
```

Generated metadata:

```text
hello
hello_len
```

Buffers:

```asm
buffer input, 128
```

Generated metadata:

```text
input
input_size
input_len
```

---

# 5. Arrays

```asm
array_i32 values, 10
```

Metadata:

```text
values_count
values_size
```

Runtime access:

```asm
array_get_i32 values, index, result
array_set_i32 values, index, value
```

---

# 6. Input/output

```asm
print hello
println

input input
input_int number

print_buf input
print_i32 number
print_i64 big_number
```

---

# 7. Assignment and arithmetic

```asm
set_i32 x, 10
copy_i32 dst, src
zero_i32 x
```

```asm
add_i32 x, y
sub_i32 x, y
mul_i32 x, y
div_i32 x, y
mod_i32 x, y
```

```asm
add_i64 x, y
sub_i64 x, y
mul_i64 x, y
div_i64 x, y
mod_i64 x, y
```

---

# 8. Conditions

```asm
if_i32_eq a, b, equal
if_i32_ne a, b, different
if_i32_lt a, b, less
if_i32_le a, b, less_or_equal
if_i32_gt a, b, greater
if_i32_ge a, b, greater_or_equal
```

Value comparisons:

```asm
if_i32_eq_val counter, 0, done
if_i32_gt_val counter, 10, large
```

---

# 9. Flow control

```asm
label loop
goto loop
```

Increment/decrement:

```asm
inc_i32 counter
dec_i32 counter
```

A compact loop helper also exists:

```asm
loop_dec_i32 counter, loop
```

---

# 10. Functions

```asm
fn sum
    ...
endfn
```

Return:

```asm
return
```

Return i32:

```asm
return_i32 result
```

Return i64:

```asm
return_i64 result
```

Return a normal i32 value:

```asm
return_value result
```

Call:

```asm
call_fn sum
```

Exports:

```asm
export_fn main
```

External declaration:

```asm
extern_fn helper
```

---

# 11. String convenience macros

Copy:

```asm
str_copy dst, src
```

Branch on equality:

```asm
str_equal username, expected, login_ok
```

Store boolean result:

```asm
str_equal_to username, expected, matched
```

---

# 12. Error API

```asm
clear_error
set_error ROSAM_ERR_DIV_ZERO
get_error
```

Error codes:

```text
0  NONE
1  INVALID_ARGUMENT
2  NULL
3  OVERFLOW
4  UNDERFLOW
5  OUT_OF_MEMORY
6  OUT_OF_RANGE
7  DIV_ZERO
8  PARSE
9  ENCODING
10 NOT_FOUND
11 UNSUPPORTED
12 IO
13 INVALID_STATE
```

---

# 13. Exit

```asm
exit 0
```

or:

```asm
return_value 0
```

Inside `main`, returning a value is generally the cleaner form when using the ROSAM function abstraction.

---

# 14. Direct core API

When the macro layer does not expose an operation directly, the core symbols are available through the backend contract.

Examples:

```asm
call rosam_mem_zero
call rosam_str_len
call rosam_i64_mul
```

However, application code should prefer the higher-level ROSAM macros when an equivalent exists.

---

# 15. Design rule

Do not create an application-specific macro in `fin.asm` merely to hide a missing language feature.

If the feature is generally useful, it belongs in:

```text
core/
macros/
platform/
```

This keeps example programs as real users of the language.
