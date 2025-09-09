.text
msg: .asciz "Input a number\n"
input_format: .asciz "%ld"
output_format: .asciz "Factorial of %ld is %ld\n"

.factorial:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp

    cmp $1, %rdi
    jle .base_case

    decq %rdi
    call .factorial
    incq %rdi
    imulq %rdi, %rax
    
    movq %rbp, %rsp
    popq %rbp
    ret

.base_case:
    movq $1, %rax
    movq %rbp, %rsp
    popq %rbp
    ret

.global main
main:
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rax
    movq $msg, %rdi
    call printf

    subq $16, %rsp
    leaq -16(%rbp), %rsi

    movq $0, %rax
    movq $input_format, %rdi
    call scanf

    movq -16(%rbp), %rdi
    call .factorial

    movq $output_format, %rdi
    movq -16(%rbp), %rsi
    movq %rax, %rdx
    movq $0, %rax
    call printf

    movq $0, %rdi
    call exit