.include "final.s"

.text
output: .asciz "%c"

print_char_loop:
    pushq %r15
    movq $0, %r15
    for_start:
        cmp %r13, %r15
        jge for_end

        movq $0, %rax
        movq $output, %rdi
        movq %r14, %rsi
        call printf

        incq %r15
        jmp for_start

    for_end:
        popq %r15
        ret

print_message:
    pushq %r12
    pushq %r13
    pushq %r14

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

    call print_char_loop

    cmp $0, %r12
    je print_message_end

    movq (%rbx, %r12, 8), %r8
    call print_message

print_message_end:
    popq %r14
    popq %r13
    popq %r12
    ret

.global main

main:
    pushq %rbp
    movq %rsp, %rbp

    leaq MESSAGE(%rip), %rbx
    movq (%rbx), %r8
    call print_message

    movq $0, %rdi
    movq %rbp, %rsp
    popq %rbp
    call exit
