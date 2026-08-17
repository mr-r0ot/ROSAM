; ============================================================
; ROSAM FIN / Full Integration Program
; ============================================================
; This file intentionally uses ROSAM source/API only.
; No CPU mnemonic is used for program logic.
;
; Features demonstrated:
;   - First-run credential initialization
;   - Login with three attempts
;   - Credential update
;   - Full integer calculator
;   - Nested-loop star algorithms
;   - Fixed-array access with a runtime index
;   - Online perceptron (binary AND classifier)
;   - Functions, branches, loops, strings, arrays, arithmetic
; ============================================================

%include "rosam.inc"

; ------------------------------------------------------------
; Constants / text
; ------------------------------------------------------------
section .data

str app_title,          13, 10, "========== ROSAM FIN ==========", 13, 10
str app_subtitle,       "Assembly-oriented application stress test", 13, 10

str login_title,        13, 10, "---------- LOGIN ----------", 13, 10
str username_prompt,    "Username: "
str password_prompt,    "Password: "
str login_ok_msg,       "Login successful.", 13, 10
str login_bad_msg,      "Invalid username or password.", 13, 10
str login_locked_msg,   "Too many attempts. Program terminated.", 13, 10

str menu_text,  13, 10, "========== MAIN MENU ==========", 13, 10
str menu_1,     "1. Calculator", 13, 10
str menu_2,     "2. Change login", 13, 10
str menu_3,     "3. Star algorithms", 13, 10
str menu_4,     "4. Machine learning", 13, 10
str menu_5,     "5. Logout", 13, 10
str menu_0,     "0. Exit", 13, 10
str choice_prompt, "Choice: "

str calc_title,       13, 10, "---------- CALCULATOR ----------", 13, 10
str calc_ops,         "+ = 1   - = 2   * = 3   / = 4   % = 5   Back = 0", 13, 10
str calc_first,       "First number: "
str calc_second,      "Second number: "
str calc_result,      "Result: "
str calc_div_zero,    "Error: division by zero.", 13, 10
str calc_invalid,     "Invalid calculator operation.", 13, 10

str change_title,     13, 10, "---------- CHANGE LOGIN ----------", 13, 10
str new_username,     "New username: "
str new_password,     "New password: "
str change_ok,        "Login information updated.", 13, 10

str star_title,       13, 10, "---------- STAR ALGORITHMS ----------", 13, 10
str star_square,      "1. Square", 13, 10
str star_triangle,    "2. Right triangle", 13, 10
str star_pyramid,     "3. Pyramid", 13, 10
str star_hollow,      "4. Hollow rectangle", 13, 10
str star_back,        "0. Back", 13, 10
str star_size_prompt, "Size: "
str star_width_prompt,"Width: "
str star_char,        "*"
str space_char,       " "

str ml_title,         13, 10, "---------- MACHINE LEARNING ----------", 13, 10
str ml_intro,         "Online Perceptron trained on the AND dataset.", 13, 10
str ml_epochs_text,   "Epochs: "
str ml_accuracy_text, "Accuracy: "
str ml_percent,       "%", 13, 10
str ml_weights_text,  "Weights: w1="
str ml_w2_text,       " w2="
str ml_bias_text,     " bias="
str ml_predict_title, 13, 10, "Prediction test", 13, 10
str ml_x1_prompt,     "x1 (0/1): "
str ml_x2_prompt,     "x2 (0/1): "
str ml_prediction,    "Prediction: "
str ml_one,           "1", 13, 10
str ml_zero,          "0", 13, 10
str ml_done,          "Training complete.", 13, 10

str goodbye,          13, 10, "Goodbye.", 13, 10

; Default credentials live in program data and are copied into mutable buffers.
str default_username, "admin"
str default_password, "rosam123"

; ------------------------------------------------------------
; Variables / buffers / datasets
; ------------------------------------------------------------
section .bss

buffer current_username, 32
buffer current_password, 32
buffer entered_username, 32
buffer entered_password, 32
buffer new_username_buf, 32
buffer new_password_buf, 32

; General application state.
i32 login_attempts
i32 login_ok
i32 menu_choice
i32 operation

i32 calc_a
i32 calc_b
i32 calc_result_value

i32 one
i32 zero

i32 two

i32 height

i32 width

i32 row

i32 col

i32 stars

i32 spaces

i32 last_row

i32 last_col

i32 border

; Machine-learning state.
array_i32 ml_x1, 4
array_i32 ml_x2, 4
array_i32 ml_y,  4

i32 ml_value
i32 ml_epoch
i32 ml_epochs
i32 ml_sample
i32 ml_samples

i32 ml_x1_value
i32 ml_x2_value
i32 ml_label

i32 ml_weight1
i32 ml_weight2
i32 ml_bias

i32 ml_score
i32 ml_prediction_value
i32 ml_delta
i32 ml_temp

i32 ml_correct
i32 ml_accuracy

; ------------------------------------------------------------
; Functions
; ------------------------------------------------------------
section .text

export_fn main

; ------------------------------------------------------------
; Initialize credentials and common constants.
; ------------------------------------------------------------
fn init_program
    set_i32 one, 1
    set_i32 zero, 0
    set_i32 two, 2
    str_copy current_username, default_username
    str_copy current_password, default_password
    return_value 0
endfn

; ------------------------------------------------------------
; Login loop.
; Return EAX = 1 on success, 0 on failure.
; ------------------------------------------------------------
fn login
    set_i32 login_attempts, 0
    set_i32 login_ok, 0

    print login_title

label login_loop
    if_i32_ge_val login_attempts, 3, login_locked

    print username_prompt
    input entered_username

    print password_prompt
    input entered_password

    str_equal entered_username, current_username, login_username_ok
    goto login_failed_attempt

label login_username_ok
    str_equal entered_password, current_password, login_success
    goto login_failed_attempt

label login_failed_attempt
    print login_bad_msg
    inc_i32 login_attempts
    goto login_loop

label login_success
    set_i32 login_ok, 1
    print login_ok_msg
    return_i32 login_ok

label login_locked
    print login_locked_msg
    return_value 0
endfn

; ------------------------------------------------------------
; Calculator.
; ------------------------------------------------------------
fn calculator
    print calc_title
    print calc_ops
    print choice_prompt
    input_int operation

    if_i32_eq_val operation, 0, calculator_done
    if_i32_gt_val operation, 5, calculator_invalid

    print calc_first
    input_int calc_a

    print calc_second
    input_int calc_b

    if_i32_eq_val operation, 1, calculator_add
    if_i32_eq_val operation, 2, calculator_sub
    if_i32_eq_val operation, 3, calculator_mul
    if_i32_eq_val operation, 4, calculator_div
    if_i32_eq_val operation, 5, calculator_mod
    goto calculator_invalid

label calculator_add
    copy_i32 calc_result_value, calc_a
    add_i32 calc_result_value, calc_b
    goto calculator_print

label calculator_sub
    copy_i32 calc_result_value, calc_a
    sub_i32 calc_result_value, calc_b
    goto calculator_print

label calculator_mul
    copy_i32 calc_result_value, calc_a
    mul_i32 calc_result_value, calc_b
    goto calculator_print

label calculator_div
    if_i32_eq_val calc_b, 0, calculator_div_zero
    copy_i32 calc_result_value, calc_a
    div_i32 calc_result_value, calc_b
    goto calculator_print

label calculator_mod
    if_i32_eq_val calc_b, 0, calculator_div_zero
    copy_i32 calc_result_value, calc_a
    mod_i32 calc_result_value, calc_b
    goto calculator_print

label calculator_print
    print calc_result
    print_i32 calc_result_value
    println
    goto calculator_done

label calculator_div_zero
    print calc_div_zero
    goto calculator_done

label calculator_invalid
    print calc_invalid

label calculator_done
    return_value 0
endfn

; ------------------------------------------------------------
; Change current username/password.
; ------------------------------------------------------------
fn change_login
    print change_title

    print new_username
    input new_username_buf
    str_copy current_username, new_username_buf

    print new_password
    input new_password_buf
    str_copy current_password, new_password_buf

    print change_ok
    return_value 0
endfn

; ------------------------------------------------------------
; Square: O(n^2) nested loops.
; ------------------------------------------------------------
fn star_square_fn
    print star_size_prompt
    input_int height

    set_i32 row, 0

label square_row_loop
    if_i32_ge row, height, square_done
    set_i32 col, 0

label square_col_loop
    if_i32_ge col, height, square_next_row
    print star_char
    inc_i32 col
    goto square_col_loop

label square_next_row
    println
    inc_i32 row
    goto square_row_loop

label square_done
    return_value 0
endfn

; ------------------------------------------------------------
; Right triangle: O(n^2).
; ------------------------------------------------------------
fn star_triangle_fn
    print star_size_prompt
    input_int height

    set_i32 row, 0

label triangle_row_loop
    if_i32_ge row, height, triangle_done

    set_i32 stars, 0

label triangle_star_loop
    copy_i32 last_row, row
    inc_i32 last_row
    if_i32_ge stars, last_row, triangle_next_row
    print star_char
    inc_i32 stars
    goto triangle_star_loop

label triangle_next_row
    println
    inc_i32 row
    goto triangle_row_loop

label triangle_done
    return_value 0
endfn

; ------------------------------------------------------------
; Pyramid: O(n^2), two nested inner loops.
; ------------------------------------------------------------
fn star_pyramid_fn
    print star_size_prompt
    input_int height

    set_i32 row, 0

label pyramid_row_loop
    if_i32_ge row, height, pyramid_done

    ; spaces = height - row - 1
    copy_i32 spaces, height
    sub_i32 spaces, row
    sub_i32 spaces, one

    set_i32 col, 0

label pyramid_space_loop
    if_i32_ge col, spaces, pyramid_star_setup
    print space_char
    inc_i32 col
    goto pyramid_space_loop

label pyramid_star_setup
    ; stars = 2 * row + 1
    copy_i32 stars, row
    mul_i32 stars, two
    add_i32 stars, one
    set_i32 col, 0

label pyramid_star_loop
    if_i32_ge col, stars, pyramid_next_row
    print star_char
    inc_i32 col
    goto pyramid_star_loop

label pyramid_next_row
    println
    inc_i32 row
    goto pyramid_row_loop

label pyramid_done
    return_value 0
endfn

; ------------------------------------------------------------
; Hollow rectangle: border detection with nested loops.
; ------------------------------------------------------------
fn star_hollow_fn
    print star_size_prompt
    input_int height
    print star_width_prompt
    input_int width

    copy_i32 last_row, height
    sub_i32 last_row, one
    copy_i32 last_col, width
    sub_i32 last_col, one

    set_i32 row, 0

label hollow_row_loop
    if_i32_ge row, height, hollow_done
    set_i32 col, 0

label hollow_col_loop
    if_i32_ge col, width, hollow_next_row

    set_i32 border, 0

    if_i32_eq_val row, 0, hollow_border
    if_i32_eq row, last_row, hollow_border
    if_i32_eq_val col, 0, hollow_border
    if_i32_eq col, last_col, hollow_border
    goto hollow_draw

label hollow_border
    set_i32 border, 1

label hollow_draw
    if_i32_eq_val border, 1, hollow_star
    print space_char
    goto hollow_next_col

label hollow_star
    print star_char

label hollow_next_col
    inc_i32 col
    goto hollow_col_loop

label hollow_next_row
    println
    inc_i32 row
    goto hollow_row_loop

label hollow_done
    return_value 0
endfn

; ------------------------------------------------------------
; Star menu.
; ------------------------------------------------------------
fn stars_menu
label stars_menu_loop
    print star_title
    print star_square
    print star_triangle
    print star_pyramid
    print star_hollow
    print star_back
    print choice_prompt
    input_int operation

    if_i32_eq_val operation, 0, stars_menu_done
    if_i32_eq_val operation, 1, stars_square_call
    if_i32_eq_val operation, 2, stars_triangle_call
    if_i32_eq_val operation, 3, stars_pyramid_call
    if_i32_eq_val operation, 4, stars_hollow_call
    goto stars_menu_loop

label stars_square_call
    call_fn star_square_fn
    goto stars_menu_loop

label stars_triangle_call
    call_fn star_triangle_fn
    goto stars_menu_loop

label stars_pyramid_call
    call_fn star_pyramid_fn
    goto stars_menu_loop

label stars_hollow_call
    call_fn star_hollow_fn
    goto stars_menu_loop

label stars_menu_done
    return_value 0
endfn

; ------------------------------------------------------------
; Prepare the AND dataset for the perceptron.
; ------------------------------------------------------------
fn ml_prepare_dataset
    ; X1 = [0, 0, 1, 1]
    set_i32 ml_value, 0
    array_set_i32 ml_x1, 0, ml_value
    array_set_i32 ml_x1, 1, ml_value
    set_i32 ml_value, 1
    array_set_i32 ml_x1, 2, ml_value
    array_set_i32 ml_x1, 3, ml_value

    ; X2 = [0, 1, 0, 1]
    set_i32 ml_value, 0
    array_set_i32 ml_x2, 0, ml_value
    set_i32 ml_value, 1
    array_set_i32 ml_x2, 1, ml_value
    set_i32 ml_value, 0
    array_set_i32 ml_x2, 2, ml_value
    set_i32 ml_value, 1
    array_set_i32 ml_x2, 3, ml_value

    ; Y = [0, 0, 0, 1]
    set_i32 ml_value, 0
    array_set_i32 ml_y, 0, ml_value
    array_set_i32 ml_y, 1, ml_value
    array_set_i32 ml_y, 2, ml_value
    set_i32 ml_value, 1
    array_set_i32 ml_y, 3, ml_value

    return_value 0
endfn

; ------------------------------------------------------------
; Compute perceptron score for current ml_x1_value/ml_x2_value.
; score = x1*w1 + x2*w2 + bias
; ------------------------------------------------------------
fn ml_score_fn
    copy_i32 ml_score, ml_x1_value
    mul_i32 ml_score, ml_weight1

    copy_i32 ml_temp, ml_x2_value
    mul_i32 ml_temp, ml_weight2
    add_i32 ml_score, ml_temp
    add_i32 ml_score, ml_bias

    set_i32 ml_prediction_value, 0
    if_i32_gt_val ml_score, 0, ml_score_positive
    return_value 0

label ml_score_positive
    set_i32 ml_prediction_value, 1
    return_value 0
endfn

; ------------------------------------------------------------
; Train online perceptron.
; ------------------------------------------------------------
fn ml_train
    call_fn ml_prepare_dataset

    set_i32 ml_epochs, 10
    set_i32 ml_samples, 4
    set_i32 ml_weight1, 0
    set_i32 ml_weight2, 0
    set_i32 ml_bias, -1
    set_i32 ml_epoch, 0

label ml_epoch_loop
    if_i32_ge ml_epoch, ml_epochs, ml_training_done

    set_i32 ml_sample, 0

label ml_sample_loop
    if_i32_ge ml_sample, ml_samples, ml_next_epoch

    array_get_i32 ml_x1, ml_sample, ml_x1_value
    array_get_i32 ml_x2, ml_sample, ml_x2_value
    array_get_i32 ml_y,  ml_sample, ml_label

    call_fn ml_score_fn

    ; delta = label - prediction
    copy_i32 ml_delta, ml_label
    sub_i32 ml_delta, ml_prediction_value

    ; w1 += delta * x1
    copy_i32 ml_temp, ml_delta
    mul_i32 ml_temp, ml_x1_value
    add_i32 ml_weight1, ml_temp

    ; w2 += delta * x2
    copy_i32 ml_temp, ml_delta
    mul_i32 ml_temp, ml_x2_value
    add_i32 ml_weight2, ml_temp

    ; bias += delta
    add_i32 ml_bias, ml_delta

    inc_i32 ml_sample
    goto ml_sample_loop

label ml_next_epoch
    inc_i32 ml_epoch
    goto ml_epoch_loop

label ml_training_done
    print ml_done

    ; Accuracy = correct * 100 / sample_count
    set_i32 ml_correct, 0
    set_i32 ml_sample, 0

label ml_accuracy_loop
    if_i32_ge ml_sample, ml_samples, ml_accuracy_done

    array_get_i32 ml_x1, ml_sample, ml_x1_value
    array_get_i32 ml_x2, ml_sample, ml_x2_value
    array_get_i32 ml_y,  ml_sample, ml_label

    call_fn ml_score_fn

    if_i32_eq ml_prediction_value, ml_label, ml_correct_one
    goto ml_accuracy_next

label ml_correct_one
    inc_i32 ml_correct

label ml_accuracy_next
    inc_i32 ml_sample
    goto ml_accuracy_loop

label ml_accuracy_done
    ; percent = correct * 100 / samples
    copy_i32 ml_accuracy, ml_correct
    set_i32 ml_value, 100
    mul_i32 ml_accuracy, ml_value
    div_i32 ml_accuracy, ml_samples

    print ml_accuracy_text
    print_i32 ml_accuracy
    print ml_percent

    print ml_weights_text
    print_i32 ml_weight1
    print ml_w2_text
    print_i32 ml_weight2
    print ml_bias_text
    print_i32 ml_bias
    println

    return_value 0
endfn

; ------------------------------------------------------------
; Test the trained perceptron on a user-provided binary pair.
; ------------------------------------------------------------
fn ml_predict
    print ml_predict_title
    print ml_x1_prompt
    input_int ml_x1_value
    print ml_x2_prompt
    input_int ml_x2_value

    call_fn ml_score_fn

    print ml_prediction
    if_i32_eq_val ml_prediction_value, 1, ml_print_one
    print ml_zero
    return_value 0

label ml_print_one
    print ml_one
    return_value 0
endfn

; ------------------------------------------------------------
; Machine-learning entrypoint.
; ------------------------------------------------------------
fn machine_learning
    print ml_title
    print ml_intro
    call_fn ml_train
    call_fn ml_predict
    return_value 0
endfn

; ------------------------------------------------------------
; Main application loop.
; ------------------------------------------------------------
fn main
    print app_title
    print app_subtitle
    call_fn init_program

label login_again
    call_fn login
    if_i32_eq_val login_ok, 1, login_success_dispatch
    goto program_exit

label login_success_dispatch
label main_menu_loop
    print menu_text
    print menu_1
    print menu_2
    print menu_3
    print menu_4
    print menu_5
    print menu_0
    print choice_prompt
    input_int menu_choice

    if_i32_eq_val menu_choice, 1, menu_calculator
    if_i32_eq_val menu_choice, 2, menu_change_login
    if_i32_eq_val menu_choice, 3, menu_stars
    if_i32_eq_val menu_choice, 4, menu_ml
    if_i32_eq_val menu_choice, 5, menu_logout
    if_i32_eq_val menu_choice, 0, program_exit
    goto main_menu_loop

label menu_calculator
    call_fn calculator
    goto main_menu_loop

label menu_change_login
    call_fn change_login
    goto main_menu_loop

label menu_stars
    call_fn stars_menu
    goto main_menu_loop

label menu_ml
    call_fn machine_learning
    goto main_menu_loop

label menu_logout
    goto login_again

label program_exit
    print goodbye
    return_value 0
endfn
