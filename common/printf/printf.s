.data
format: .asciz "My name is %s. I think I’ll get a %u %d %d %d %d for my exam. What does %r do? And %%?\n"
percent: .asciz "%"
minus: .asciz "-"
name: .asciz "Victor"

.text

printu:
    # prologue
    pushq %rbp
    movq %rsp, %rbp

    # preserve callee-saved registries
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $8, %rsp

    movq %rsp, %r12 # save initial stack pointer
    loop_get_digits:
        # set up a division by 10
        movq %rdi, %rax
        movq $0, %rdx # higher 64 bits
        movq $10, %rcx # number to divide by
        divq %rcx
        movq %rax, %rdi # what's left of the number
        addq $48, %rdx # convert to character
        pushq %rdx # save the last digit

        cmp $0, %rdi
        je loop_printu

        jmp loop_get_digits

    loop_printu:
        cmp %r12, %rsp # while we still have digits to pop
        je loop_printu_end

        movq $1, %rax # call sys_write
        movq $1, %rdi # write to stdout
        movq %rsp, %rsi # get digit address
        movq $1, %rdx # we only print one byte
        syscall

        addq $8, %rsp # pop the digit

        jmp loop_printu
    
    loop_printu_end:

    # get callee-saved registries
    addq $8, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx

    # epilogue
    movq %rbp, %rsp
    popq %rbp
    ret

printd:
    # prologue
    pushq %rbp
    movq %rsp, %rbp

    # preserve callee-saved registries
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $8, %rsp

    movq %rdi, %rax
    shr $63, %rax # get first bit

    cmp $1, %rax # if it's a negative number
    je negative_preprocess

    jmp print_number

    negative_preprocess:
        pushq %rdi # save the number
        subq $8, %rsp
        
        movq $1, %rax # call sys_write
        movq $1, %rdi # write to stdout
        movq $minus, %rsi # print sign
        movq $1, %rdx # we only print one byte
        syscall

        addq $8, %rsp
        
        popq %rdi # get the number
        
        # to get the absolute value we must
        # invert the bits and add 1
        notq %rdi
        addq $1, %rdi
    
    print_number:
        call printu
        


    # get callee-saved registries
    addq $8, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx

    # epilogue
    movq %rbp, %rsp
    popq %rbp
    ret

prints:
    # prologue
    pushq %rbp
    movq %rsp, %rbp

    # preserve callee-saved registries
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $8, %rsp

    movq %rdi, %r12 # keep the string safe
    movq $0, %r13 # index in the string
    loop_prints:
        cmpb $0, (%r12, %r13, 1)
        je loop_prints_end

        movq $1, %rax # call sys_write
        movq $1, %rdi # write to stdout
        movq %r12, %rsi # get the pointer to the string
        addq %r13, %rsi # get to the current position
        movq $1, %rdx # we only print one byte
        syscall

        incq %r13 # go to the next character
        jmp loop_prints
    
    loop_prints_end:

    # get callee-saved registries
    addq $8, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx

    # epilogue
    movq %rbp, %rsp
    popq %rbp
    ret

get_arg:
    # prologue
    pushq %rbp
    movq %rsp, %rbp

    # preserve callee-saved registries
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $8, %rsp

    # %rdi = index of arg
    # %rsi = old base pointer

    cmp $5, %rdi # we have max 5 register args
    jge get_stack_arg
    
    get_register_arg:
        incq %rdi # 0-index to 1-index
        movq %rdi, %rax
        movq $8, %rbx
        mul %rbx # get the position in the stack
        subq %rax, %rsi # get pointer
        movq (%rsi), %rax # put value in return register
        jmp after_get

    get_stack_arg:
        movq %rdi, %rax
        subq $5, %rax # get index into the stack portion of args
        addq $2, %rax # skip return address
        movq $8, %rbx
        mul %rbx # get the position in the stack
        addq %rax, %rsi # get pointer
        movq (%rsi), %rax # put value in return register
        jmp after_get

    after_get:

    # get callee-saved registries
    addq $8, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx

    # epilogue
    movq %rbp, %rsp
    popq %rbp
    ret

my_printf:
    # prologue
    pushq %rbp
    movq %rsp, %rbp

    # save parameter registries
    pushq %rsi
    pushq %rdx
    pushq %rcx
    pushq %r8
    pushq %r9
    sub $16, %rsp # align the stack

    # preserve callee-saved registries
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $8, %rsp

    movq %rdi, %r12 # keep the format string safe
    movq $0, %r13 # index in the string
    movq $0, %rbx # which argument is being printed
    loop_my_printf:
        cmpb $0, (%r12, %r13, 1)
        je loop_my_printf_end

        cmpb $37, (%r12, %r13, 1) # if the current character is %
        jne write_ch

        test_format:
            incq %r13 # go to the next character
            
            cmpb $100, (%r12, %r13, 1) # if the character is d
            je call_printd

            cmpb $117, (%r12, %r13, 1) # if the character is u
            je call_printu

            cmpb $115, (%r12, %r13, 1) # if the character is s
            je call_prints

            cmpb $37, (%r12, %r13, 1) # if the character is %
            je call_print_percent
            
            # if the format is unrecognized
            decq %r13 # go back to the current character

        write_ch:
            movq $1, %rax # call sys_write
            movq $1, %rdi # write to stdout
            movq %r12, %rsi # get the pointer to the string
            addq %r13, %rsi # get to the current position
            movq $1, %rdx # we only print one byte
            syscall
            jmp continue_loop_my_printf

        call_printd:
            movq %rbx, %rdi
            movq %rbp, %rsi
            call get_arg
            movq %rax, %rdi
            incq %rbx # go to the next arg
            call printd
            jmp continue_loop_my_printf

        call_printu:
            movq %rbx, %rdi
            movq %rbp, %rsi
            call get_arg
            movq %rax, %rdi
            incq %rbx # go to the next arg
            call printu
            jmp continue_loop_my_printf

        call_prints:
            movq %rbx, %rdi
            movq %rbp, %rsi
            call get_arg
            movq %rax, %rdi
            incq %rbx # go to the next arg
            call prints
            jmp continue_loop_my_printf

        call_print_percent:
            movq $1, %rax # call sys_write
            movq $1, %rdi # write to stdout
            movq $percent, %rsi # get the pointer to the string
            movq $1, %rdx # we only print one byte
            syscall

            jmp continue_loop_my_printf

        continue_loop_my_printf:
            incq %r13 # go to the next character
            jmp loop_my_printf
    
    loop_my_printf_end:

    # get callee-saved registries
    addq $8, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx

    # epilogue
    movq %rbp, %rsp
    popq %rbp
    ret

.global main

main:
    # prologue
    pushq %rbp
    movq %rsp, %rbp

    # test the function
    leaq format(%rip), %rdi
    leaq name(%rip), %rsi
    movq $-0xFFFFFF00, %rdx
    movq $-0xFFFFFF00, %rcx
    movq $10, %r8
    movq $18, %r9
    pushq %rdx
    call my_printf

    # epilogue
    movq %rbp, %rsp
    popq %rbp

    movq $60, %rax # sys_exit
    movq $0, %rdi # code 0
    syscall
