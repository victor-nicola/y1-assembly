.global power
.global main

.data

fmt_exponent: .asciz "%ld"
fmt_base: .asciz "%ld"

base_val: .quad 0
exponent_val: .quad 0

fmt_result: .asciz "result = %ld\n"

.text

pow:
    pushq %rbp
    movq %rsp, %rbp
    movq $1, %rax

loop:
    cmpq $0, %rsi
    je end_loop
    imulq %rdi, %rax
    decq %rsi
    jmp loop

end_loop:
    popq %rbp
    ret

scanf_base:
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rax
    leaq fmt_base(%rip), %rdi
    leaq base_val(%rip), %rsi
    call scanf

    popq %rbp
    ret

scanf_exponent:
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rax
    leaq fmt_exponent(%rip), %rdi
    leaq exponent_val(%rip), %rsi
    call scanf

    popq %rbp
    ret

main:
    pushq %rbp
    movq %rsp, %rbp

    call scanf_base #scan base
    call scanf_exponent #scan exponent


    movq base_val(%rip), %rdi # move base to rdi
    movq exponent_val(%rip), %rsi  # move exponent to rsi

    call pow
    movq %rax, %rsi
    leaq fmt_result(%rip), %rdi
    movq $0, %rax
    call printf

    movq $0, %rax

    popq %rbp
    ret
