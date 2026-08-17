%include "rosam.inc"

section .data

str welcome, "Welcome To My Mini Application :) (By TahaGorji)", 13, 10
str ask_name, "Enter Your Name: "
str hello, "This is my assembly area, welcome "
str ask_first, "Please Enter The First Number: "
str ask_second, "Please Enter The Second Number: "
str result_msg, "Result: "

section .bss

buffer name, 64
i32 firstnumber
i32 secondnumber

section .text

export_fn main

fn main

    print welcome

    print ask_name
    input name

    println
    print hello
    print_buf name
    println

    print ask_first
    input_int firstnumber
    println

    print ask_second
    input_int secondnumber
    println

    add_i32 firstnumber, secondnumber

    print result_msg
    print_i32 firstnumber
    println

    return_value 0

endfn
