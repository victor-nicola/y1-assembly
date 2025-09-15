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

    cmpq $1, %rdi
    jle base_case
    imulq %rdi, %rax
    decq %rdi
    cmpq $1, %rdi
    je end_factorial
    call factorial

base_case:
    movq $1, %rax

end_factorial:
    popq %rbp
    ret

scanf_n:
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rax
    leaq fmt_exponent(%rip), %rdi
    leaq n(%rip), %rsi
    call scanf

    popq %rbp
    ret

main:
    pushq %rbp
    movq %rsp, %rbp

    call scanf_n #scan n

    movq n(%rip), %rdi # move n to rdi for factorial
    call factorial
    leaq fmt_result(%rip), %rdi
    movq %rax, %rsi

    movq $0, %rax

    call printf

    popq %rbp
    ret
