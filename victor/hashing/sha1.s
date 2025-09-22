.global sha1_chunk
print_nr: .asciz "\nmy print: %ld\n"

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

    mov $16, %r9d # index
    mov $80, %r8d # loop limit
    leftrotate_loop:
        cmp %r8d, %r9d
        jge after_leftrotate_loop

        # get the index (i - 3)
        movslq %r9d, %rax
        sub $3, %rax

        # get the value
        mov (%rsi, %rax, 4), %ecx

        # get the index (i - 8)
        movslq %r9d, %rax
        sub $8, %rax

        # get the value
        mov (%rsi, %rax, 4), %edx
        xor %edx, %ecx # w[i - 3] xor w[i - 8]

        # get the index (i - 14)
        movslq %r9d, %rax
        sub $14, %rax

        # get the value
        mov (%rsi, %rax, 4), %edx
        xor %edx, %ecx # w[i - 3] xor w[i - 8] xor w[i - 14]

        # get the index (i - 16)
        movslq %r9d, %rax
        sub $16, %rax

        # get the value
        mov (%rsi, %rax, 4), %edx
        xor %edx, %ecx # w[i - 3] xor w[i - 8] xor w[i - 14] xor w[i - 16]
        
        # leftrotate %ecx by 1
        rol $1, %ecx
        movslq %r9d, %rax
        mov %ecx, (%rsi, %rax, 4)
        
        inc %r9d
        jmp leftrotate_loop
    
    after_leftrotate_loop:
        mov (%rdi), %r10d   # a = h0
        mov 4(%rdi), %r11d  # b = h1
        mov 8(%rdi), %r12d  # c = h2
        mov 12(%rdi), %r13d # d = h3
        mov 16(%rdi), %r14d # e = h4

        mov $0, %r9d  # index
        mov $80, %r8d # loop limit
        main_loop:
            cmp %r8d, %r9d
            jge after_main_loop

            cmp $19, %r9d
            jle first_case

            cmp $39, %r9d
            jle second_case

            cmp $59, %r9d
            jle third_case

            cmp $79, %r9d
            jle fourth_case

            # f = %eax
            # k = %ebx
            mov $0, %eax
            mov $0, %ebx
            jmp operations

            first_case:
                # %eax = b and c
                mov %r11d, %eax
                and %r12d, %eax

                # %ebx = (not b) and d
                mov %r11d, %ebx
                not %ebx
                and %r13d, %ebx
                
                or %ebx, %eax # %eax = result
                mov $0x5A827999, %ebx
                jmp operations
            
            second_case:
                # %eax = b xor c xor d
                mov %r11d, %eax
                xor %r12d, %eax
                xor %r13d, %eax
                mov $0x6ED9EBA1, %ebx
                jmp operations
            
            third_case:
                # %eax = b and c
                mov %r11d, %eax
                and %r12d, %eax

                # %ebx = b and d
                mov %r11d, %ebx
                and %r13d, %ebx

                or %ebx, %eax # %eax = (b and c) or (b and d)

                # %ebx = c and d
                mov %r12d, %ebx
                and %r13d, %ebx

                or %ebx, %eax # %eax = (b and c) or (b and d) or (c and d)

                mov $0x8F1BBCDC, %ebx
                jmp operations

            fourth_case:
                # %eax = b xor c xor d
                mov %r11d, %eax
                xor %r12d, %eax
                xor %r13d, %eax
                mov $0xCA62C1D6, %ebx
                jmp operations

            # f = %eax
            # k = %ebx
            operations:
                # temp = %ecx = a leftrotate 5
                mov %r10d, %ecx
                rol $5, %ecx

                add %eax, %ecx            # (a leftrotate 5) + f
                add %r14d, %ecx           # (a leftrotate 5) + f + e
                add %ebx, %ecx            # (a leftrotate 5) + f + e + k
                movslq %r9d, %rdx
                add (%rsi, %rdx, 4), %ecx # (a leftrotate 5) + f + e + k + w[i]

                mov %r13d, %r14d # e = d
                mov %r12d, %r13d # d = c
                
                mov %r11d, %eax
                rol $30, %eax # b leftrotate 30
                mov %eax, %r12d # c = b leftrotate 30

                mov %r10d, %r11d # b = a
                mov %ecx, %r10d # a = temp
            
            inc %r9d
            jmp main_loop

        after_main_loop:
            addl %r10d, (%rdi)
            addl %r11d, 4(%rdi)
            addl %r12d, 8(%rdi)
            addl %r13d, 12(%rdi)
            addl %r14d, 16(%rdi)

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
