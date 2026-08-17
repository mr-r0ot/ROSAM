# ROSAM v0.6.1 API Reference

This document describes the public API contract represented by `core/*.inc`.

## Memory

```text
rosam_mem_copy
rosam_mem_move
rosam_mem_set
rosam_mem_zero
rosam_mem_compare
rosam_mem_equal
rosam_mem_find
rosam_mem_alloc
rosam_mem_calloc
rosam_mem_realloc
rosam_mem_free
```

## String

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

## Text

```text
rosam_ascii_is_alpha
rosam_ascii_is_digit
rosam_ascii_is_alnum
rosam_ascii_is_space
rosam_ascii_is_upper
rosam_ascii_is_lower
rosam_ascii_to_upper
rosam_ascii_to_lower

rosam_utf8_len
rosam_utf8_char_count
rosam_utf8_next
rosam_utf8_prev
rosam_utf8_decode
rosam_utf8_encode
rosam_utf8_is_valid
rosam_utf8_validate
rosam_utf8_char_at
```

## Number

```text
rosam_i32_add
rosam_i32_sub
rosam_i32_mul
rosam_i32_div
rosam_i32_mod
rosam_i32_abs
rosam_i32_min
rosam_i32_max
rosam_i32_clamp

rosam_i64_add
rosam_i64_sub
rosam_i64_mul
rosam_i64_div
rosam_i64_mod
rosam_i64_abs
rosam_i64_min
rosam_i64_max
rosam_i64_clamp

rosam_u32_add
rosam_u32_sub
rosam_u32_mul
rosam_u32_div
rosam_u32_mod
rosam_u32_min
rosam_u32_max
rosam_u32_clamp

rosam_u64_add
rosam_u64_sub
rosam_u64_mul
rosam_u64_div
rosam_u64_mod
rosam_u64_min
rosam_u64_max
rosam_u64_clamp
```

Conversions:

```text
rosam_atoi_i32
rosam_itoa_i32
rosam_atoi_i64
rosam_itoa_i64
rosam_atou_u32
rosam_utoa_u32
rosam_atou_u64
rosam_utoa_u64
```

## Math

```text
rosam_gcd
rosam_lcm
rosam_pow_i32
rosam_is_power2
rosam_floor_log2
rosam_ceil_log2

rosam_sqrt_f64
rosam_cbrt_f64
rosam_sin_f64
rosam_cos_f64
rosam_tan_f64
rosam_asin_f64
rosam_acos_f64
rosam_atan_f64
rosam_atan2_f64
rosam_sinh_f64
rosam_cosh_f64
rosam_tanh_f64
rosam_exp_f64
rosam_log_f64
rosam_log10_f64
rosam_log2_f64
rosam_pow_f64
rosam_floor_f64
rosam_ceil_f64
rosam_round_f64
rosam_trunc_f64
rosam_is_nan_f64
rosam_is_inf_f64
rosam_is_finite_f64
```

## Bit operations

```text
rosam_bit_set
rosam_bit_clear
rosam_bit_toggle
rosam_bit_test
rosam_bit_shl
rosam_bit_shr
rosam_bit_sar
rosam_bit_rol
rosam_bit_ror
rosam_bit_popcount
rosam_bit_clz
rosam_bit_ctz
rosam_bit_parity
rosam_bit_is_power2
rosam_bit_next_power2
rosam_bit_prev_power2
rosam_bswap16
rosam_bswap32
rosam_bswap64
rosam_bit_reverse8
rosam_bit_reverse16
rosam_bit_reverse32
rosam_bit_reverse64
```

## Arrays and containers

```text
rosam_array_copy
rosam_array_fill
rosam_array_reverse
rosam_array_find
rosam_array_contains
rosam_array_sort
rosam_array_get
rosam_array_set

rosam_vec_create
rosam_vec_destroy
rosam_vec_push
rosam_vec_pop
rosam_vec_get
rosam_vec_set
rosam_vec_len
rosam_vec_capacity
rosam_vec_reserve
rosam_vec_resize
rosam_vec_clear

rosam_stack_create
rosam_stack_destroy
rosam_stack_push
rosam_stack_pop
rosam_stack_peek
rosam_stack_len

rosam_deque_push_front
rosam_deque_push_back
rosam_deque_pop_front
rosam_deque_pop_back
```

## Algorithms

```text
rosam_linear_search
rosam_binary_search
rosam_sort
rosam_quick_sort
rosam_merge_sort
rosam_heap_sort
rosam_insertion_sort
rosam_reverse
rosam_find_min
rosam_find_max
rosam_sum
rosam_product
rosam_count
rosam_count_if
rosam_any
rosam_all
rosam_none
rosam_copy_if
rosam_transform
rosam_fill
rosam_partition
rosam_stable_partition
rosam_prefix_sum
```

## Random

```text
rosam_rng_init
rosam_rng_seed
rosam_rng_u8
rosam_rng_u16
rosam_rng_u32
rosam_rng_u64
rosam_rng_i32
rosam_rng_i64
rosam_rng_float
rosam_rng_double
rosam_rng_range
rosam_rng_bytes
rosam_rng_uniform
rosam_rng_boolean
rosam_rng_shuffle
rosam_rng_choice
rosam_secure_random
```

## Formatting

```text
rosam_format_i8
rosam_format_i16
rosam_format_i32
rosam_format_i64
rosam_format_u8
rosam_format_u16
rosam_format_u32
rosam_format_u64
rosam_format_bin
rosam_format_oct
rosam_format_dec
rosam_format_hex
rosam_format_f32
rosam_format_f64
rosam_format_char
rosam_format_bool
rosam_format_append
rosam_format_value
```

## Error

```text
rosam_error_clear
rosam_error_set
rosam_error_get
rosam_error_has
rosam_error_code
rosam_error_name
rosam_error_message
```

The public core contract is broader than the high-level convenience macros. That separation is deliberate.
