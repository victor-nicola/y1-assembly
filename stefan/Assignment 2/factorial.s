.global main

.data

fmt_exponent: .asciz "%ld"
fmt_base: .asciz "%ld"

base_val: .quad 0
exponent_val: .quad 0
n: .quad 0

fmt_result: .asciz "result = %ld\n"

.text

factorial:
    pushq %rbp
    movq %rsp, %rbp

    cmpq $1, %rcx
    je end_factorial
    imulq %rcx, %rax
    decq %rcx
    cmpq $1, %rcx
    je end_factorial
    call factorial

end_factorial:
    popq %rbp
    ret

scanf_n:

    movq $0, %rax
    leaq fmt_exponent(%rip), %rdi
    leaq n(%rip), %rsi
    call scanf

    ret

main:
    pushq %rbp
    movq %rsp, %rbp

    sub $8, %rsp #align stack
    call scanf_n #scan n
    add $8, %rsp #restore stack

    movq n(%rip), %rcx # move n to rcx for factorial
    movq $1, %rax # factorial result init to 1
    call factorial
    movq %rax, %rsi
    leaq fmt_result(%rip), %rdi
    movq $0, %rax
    call printf

    movq $0, %rax

    popq %rbp
    ret
