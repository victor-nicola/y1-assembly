.global power
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

    cmpq $1, %rcx
    je end_factorial
    imulq %rcx, %rax
    decq %rcx
    cmpq $1, %rcx
    je end_factorial
    call factorial

end_factorial:
    ret


power:
    movq $1, %rax

loop:
    cmpq $0, %rsi
    je end_loop
    imulq %rdi, %rax
    decq %rsi
    jmp loop

end_loop:
    ret

scanf_base:

    xor %rax, %rax
    leaq fmt_base(%rip), %rdi
    leaq base_val(%rip), %rsi
    call scanf

    ret

scanf_exponent:

    xor %rax, %rax
    leaq fmt_exponent(%rip), %rdi
    leaq exponent_val(%rip), %rsi
    call scanf

    ret

scanf_n:

    xor %rax, %rax
    leaq fmt_exponent(%rip), %rdi
    leaq n(%rip), %rsi
    call scanf

    ret

main:
    pushq %rbp
    movq %rsp, %rbp

    // sub $8, %rsp #align stack
    // call scanf_base #scan base
    // call scanf_exponent #scan exponent
    // add $8, %rsp #restore stack


    // movq base_val(%rip), %rdi # move base to rdi
    // movq exponent_val(%rip), %rsi  # move exponent to rsi

    // call power
    // movq %rax, %rsi
    // leaq fmt_result(%rip), %rdi
    sub $8, %rsp #align stack
    call scanf_n #scan n
    add $8, %rsp #restore stack

    movq n(%rip), %rcx # move n to rcx for factorial
    movq $1, %rax # factorial result init to 1
    call factorial
    movq %rax, %rsi
    leaq fmt_result(%rip), %rdi
    xor %rax, %rax
    call printf

    movq $0, %rax

    popq %rbp
    ret
