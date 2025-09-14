.global sha1_chunk
print_nr: .asciz "\nmy print: %ld\n"

# %edi = the number to leftrotate
# %sil = the number of bits to leftrotate by
leftrotate:
    # prologue
    pushq %rbp
    movq %rsp, %rbp

    # save the callee-saved registries
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    # calculate the number of bits that remain
    # %al = number of bits that remain
    mov $32, %al
    sub %sil, %al

    # get the first n bits in %ecx
    mov %edi, %ecx
    mov %al, %cl
    shr %cl, %ecx

    # %ebx = mask to extract the bits that must remain
    mov $1, %ebx
    mov %al, %cl
    shl %cl, %ebx
    sub $1, %ebx

    # get the last bits
    and %ebx, %edi
    mov %sil, %cl
    shl %cl, %edi # make space for the first n bits
    add %ecx, %edi # add the first n bits to the end

    mov %edi, %eax # move the answer into the return register

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

leftrotate_loop:
    cmp %r8d, %r9d
    jge leftrotate_loop_end

    # get the index (i - 3)
    movslq %r9d, %rax
    sub $3, %rax

    # get the value
    mov (%r15, %rax, 4), %ecx

    # get the index (i - 8)
    movslq %r9d, %rax
    sub $8, %rax

    # get the value
    mov (%r15, %rax, 4), %edx
    xor %edx, %ecx

    # get the index (i - 14)
    movslq %r9d, %rax
    sub $14, %rax

    # get the value
    mov (%r15, %rax, 4), %edx
    xor %edx, %ecx

    # get the index (i - 16)
    movslq %r9d, %rax
    sub $16, %rax

    # get the value
    mov (%r15, %rax, 4), %edx
    xor %edx, %ecx
    
    # setup the call for the leftrotate
    mov %ecx, %edi
    mov $1, %sil
    call leftrotate
    movslq %r9d, %rax
    mov %eax, (%r15, %rax, 4)
    
    inc %r9d
    jmp leftrotate_loop
leftrotate_loop_end:
    ret

main_loop:
    cmp %r8d, %r9d
    jge main_loop_end

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
        xor %ebx, %eax # %eax = (b and c) xor (b and d)

        # %ebx = c and d
        mov %r12d, %ebx
        and %r13d, %ebx
        xor %ebx, %eax # %eax = (b and c) xor (b and d) xor (c and d)

        mov $0x8F1BBCDC, %ebx
        jmp operations

    fourth_case:
        # %eax = b xor c xor d
        mov %r11d, %eax
        xor %r12d, %eax
        xor %r13d, %eax
        mov $0xCA62C1D6, %ebx
        jmp operations

    operations:
        pushq %rax
        # temp = %eax = a leftrotate 5
        mov %r10d, %edi
        mov $5, %sil
        call leftrotate
        popq %rcx

        add %ecx, %eax
        add %r14d, %eax
        add %ebx, %eax
        movslq %r9d, %rdx
        add (%r15, %rdx, 4), %eax

        mov %r13d, %r14d # e = d
        mov %r12d, %r13d # d = c
        
        pushq %rax # save temp
        mov %r11d, %edi
        mov $30, %sil
        call leftrotate
        mov %eax, %r12d # c = b leftrotate 30
        popq %rax # get temp

        mov %r10d, %r11d # b = a
        mov %eax, %r10d # a = temp
    
    inc %r9d
    jmp main_loop

main_loop_end:
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

    mov (%rdi), %r10d   # h0
    mov 4(%rdi), %r11d  # h1
    mov 8(%rdi), %r12d  # h2
    mov 12(%rdi), %r13d # h3
    mov 16(%rdi), %r14d # h4
    mov %rsi, %r15 # w pointer

    mov $16, %r9d # index
    mov $80, %r8d # loop limit
    pushq %rdi
    call leftrotate_loop
    popq %rdi

    mov $0, %r9d  # index
    mov $80, %r8d # loop limit
    pushq %rdi
    call main_loop
    popq %rdi

    add %r10d, (%rdi)
    add %r11d, 4(%rdi)
    add %r12d, 8(%rdi)
    add %r13d, 12(%rdi)
    add %r14d, 16(%rdi)

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
