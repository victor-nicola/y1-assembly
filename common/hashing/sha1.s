.global sha1_chunk
print_nr: .asciz "\nmy print: %ld\n"

leftrotate_loop:
    cmp %r8, %r9
    jge loop_end

    # do the leftrotate

    continue_loop:
        incq %r9
        jmp leftrotate_loop

loop_end:
    ret

sha1_chunk:
    # prologue
    pushq %rbp
    movq %rsp, %rbp

    # save the callee-saved registries
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    # actual code
    movq (%rdi), %r10       # h0
    movq (%r10, 1, 4), %r11 # h1
    movq (%r10, 2, 4), %r12 # h2
    movq (%r10, 3, 4), %r13 # h3
    movq (%r10, 4, 4), %r14 # h4

    movq %rsi, %r15 # w[0]
    movq $16, %r9   # index
    movq $80, %r8   # loop limit

    jmp leftrotate_loop

    jmp main_loop

    addq %r10, (%rdi)
    addq %r11, (%rdi, 1, 4)
    addq %r12, (%rdi, 2, 4)
    addq %r13, (%rdi, 3, 4)
    addq %r14, (%rdi, 4, 4)

    # get the callee-saved registries
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx

    # epilogue
    movq %rbp, %rsp
    popq %rbp
	
    ret
