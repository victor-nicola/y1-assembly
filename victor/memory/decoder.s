.include "final.s"

.text
output: .asciz "%c"

decode:
    pushq %rbp
    movq %rsp, %rbp

    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    movq (%rdi), %r8

    loop:
        movq $0xFFFFFF, %rcx

        # next address
        movq %r8, %r12 # moved the current element into the next address variable
        shr $16, %r12
        and %rcx, %r12

        movq $0xFF, %rcx
        # no of repetitions
        movq %r8, %r13 # moved the current element into the no of repetitions variable
        shr $8, %r13
        and %rcx, %r13

        # character
        movq %r8, %r14 # moved the current element into the character variable
        and %rcx, %r14

        movq $0, %r15
        loop_char:
            cmp %r13, %r15
            jge after_loop_char

            pushq %rdi
            movq $0, %rax
            movq $output, %rdi
            movq %r14, %rsi
            call printf
            popq %rdi

            incq %r15
            jmp loop_char

        after_loop_char:
            cmp $0, %r12
            je loop_end

            movq (%rdi, %r12, 8), %r8
            jmp loop

    loop_end:
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbx

        movq %rbp, %rsp
        popq %rbp
        ret

.global main

main:
    pushq %rbp
    movq %rsp, %rbp

    leaq MESSAGE(%rip), %rdi
    call decode

    movq %rbp, %rsp
    popq %rbp
    call exit
