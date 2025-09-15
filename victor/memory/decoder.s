.include "final.s"

.text
output: .asciz "%c"


print_char:
    pushq %rbp
    movq %rsp, %rbp

    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    movq $0, %r15
    loop:
        cmp %r13, %r15
        jge for_end

        movq $0, %rax
        movq $output, %rdi
        movq %r14, %rsi
        call printf

        incq %r15
        jmp for_start

    loop_end:
        popq %r15
        popq %r14
        popq %r13
        popq %r12

        movq %rbp, %rsp
        popq %rbp
        ret

print_message:
    pushq %rbp
    movq %rsp, %rbp

    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    loop:
        movq $0xFFFFFF, %rcx

        # next address
        movq %rdi, %r12 # moved the current element into the next address variable
        shr $16, %r12
        and %rcx, %r12

        movq $0xFF, %rcx
        # no of repetitions
        movq %rdi, %r13 # moved the current element into the no of repetitions variable
        shr $8, %r13
        and %rcx, %r13

        # character
        movq %rdi, %r14 # moved the current element into the character variable
        and %rcx, %r14

        call print_char

        cmp $0, %r12
        je loop_end

        movq (%rbx, %r12, 8), %r8
        jmp print_message

    loop_end:
        popq %r15
        popq %r14
        popq %r13
        popq %r12

        movq %rbp, %rsp
        popq %rbp
        ret

.global main

main:
    pushq %rbp
    movq %rsp, %rbp

    leaq MESSAGE(%rip), %rbx
    movq (%rbx), %rdi
    call print_message

    movq %rbp, %rsp
    popq %rbp
    call exit
