.data
samecardcounter: .long 1
pairs: .long 0
threeofakind: .long 0
straight: .long 1
flush: .long 0
fullhouse1: .long 0
fullhouse2: .long 0
fourofakind: .long 0


fmt: .asciz "%u %u %u %u %u \n" 

.text
.global main

rand52:
    pushq %rbp
    movq %rsp, %rbp

    subq $16, %rsp # reserve local space for buffer

    get_random_loop:
        # syscall for getrandom()
        movq %rsp, %rdi # buf -> pointer to stack
        movl $4, %esi   # buflen is 4 bytes because we want a 32 bit number to reduce the bias of the randomness
        xorq %rdx, %rdx  # flag is 0
        movq $318, %rax  # code for the syscall
        syscall

        # syscall returns the number of bytes read into %rax, and in case of an error it returns -1
        cmpl $4, %eax
        jne get_random_loop # try again if we got an error

        # move the randomly generated bits into rax
        movl (%rsp), %eax

        # here are 40 numbers that we cannot take though
        # discard if number >= lim (limit is floor(2^32/52) * 52, in hex it's 0xFFFFFFD0 = 4294967248)
        cmpl $0xFFFFFFD0, %eax
        jge get_random_loop

        # compute the remainder of number % 52 (this is because we have a possibly huge number)
        xorl %edx, %edx # make rdx 0 because this is where the remmainder is stored
        movl $52, %ecx
        divl %ecx # quotient in rax, remainder in rdx

        incl %edx # increase because we want numbers from 1 to 52, not 0-51
        movl %edx, %eax # final answer in %rax
        
        addq $16, %rsp

        movq %rbp, %rsp
        popq %rbp

        ret

rand5_unique_sorted:
    pushq %rbp
    movq %rsp, %rbp

    # save callee-saved registers we use
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    subq $8, %rsp # align stack

    movq %rdi, %r12 # save the pointer to the output array

    xorq %rbx, %rbx # i = 0

    outer_loop:
        call rand52
        movl %eax, %r13d # saving the random number in a temp register just in case
        xorq %rcx, %rcx # j = 0
        check_dup_loop:
            cmpq %rbx, %rcx
            je no_dup_found #i = j means current count reached so no duplicate

            movl (%r12, %rcx, 4), %edx
            cmpl %edx, %r13d
            je outer_loop # duplicate found, get new number

            incq %rcx # next number
            jmp check_dup_loop
        no_dup_found:
            movl %r13d, (%r12, %rbx, 4) #store number in array
            incq %rbx
            cmpq $5, %rbx # see if we reached the full 5 numbers needed
            jl outer_loop
    

    bubble_sort:
        xorq %rbx, %rbx # i = 0
        outer_sort_loop:
            xorq %rcx, %rcx # j = 0
            inner_sort_loop:
                movl 4(%r12, %rcx, 4), %edx # array[i] -> edx
                movl (%r12, %rcx, 4), %eax # array[i+1] -> eax

                cmpl %edx, %eax
                jl no_swap

                #swap numbers in array
                movl %edx, (%r12, %rcx, 4)
                movl %eax, 4(%r12, %rcx, 4)

            no_swap:
                incl %ecx
                cmpl $4, %ecx
                jl inner_sort_loop

                incl %ebx
                cmpl $4, %ebx
                jl outer_sort_loop

    movq %r12, %rax # move array pointer into rax

    addq $8, %rsp
    popq %r13
    popq %r12
    popq %rbx
    # pop callee-saved registers we used

    movq %rbp, %rsp
    popq %rbp

    ret

getcardsuit:
    cmpl $14, %eax
    jl clubs
    cmpl $27, %eax
    jl diamonds
    cmpl $40, %eax
    jl hearts
    jmp spades

    clubs:
        movq $1, %r10
        pushq %r10
    diamonds:
        movq $2, %r10
        pushq %r10
    hearts:
        movq $3, %r10
        pushq %r10
    spades:
        movq $4, %r10
        pushq %r10




get_poker_hand:
    pushq %rbp
    movq %rsp, %rbp

    subq $24, %rsp

    leaq (%rsp), %rdi
    call rand5_unique_sorted # get cards

    movq %rax, %r12 # save array pointer for cards in a temp register

    xorq %rax, %rax # zero out rax 

    xorq %rbx, %rbx # i = 0

    loop:
        movl (%r12, %rbx, 4), %eax # get first card (1-52)
        jmp getcardsuit # gets the suit of every card generated

        divq $13
        movl %edx, %eax # gets the card value (0-12, where 0 is king)

        movl %eax, %r13d

        movq %rbx, %rcx
        incq %rcx # j = i + 1

        movl $0, $samecardcounter
        same_counter:
            movl (%r12, %rcx, 4), %eax  # load 2nd card
            divq $13 
            movl %edx, %eax # get card value 
            cmpl %r13d, %eax # compare card values
            jne continue_loop
            count:
                incl $samecardcounter # increase the amount of same cards
                incq %rcx # go to next card
                jmp same_counter
    continue_loop:
        cmpl $2, $samecardcounter
        je pairsflag
        cmpl $3, $samecardcounter
        je threeofakindflag
        cmpl $4, $samecardcounter
        je fourofakindflag

        pairsflag:
            incl $pairs
            movl $1, $fullhouse1
            addq $1, %rbx
            # the pair 
            # in case we only have 2 same cards one after another 
            # we can skip the second card and go straight to the third 
        threeofakindflag:
            movl $1, $threeofakind
            movl $1, $fullhouse2
            addq $2, %rbx


        incq %rbx

        cmpq $4, %rbx # continue loop if we must
        jle loop





    


main:
    pushq %rbp
    movq %rsp, %rbp

    subq $24, %rsp

    leaq (%rsp), %rdi
    call rand5_unique_sorted

    leaq fmt(%rip), %rdi     # 1st arg: pointer to format string
    movl (%rax), %esi        # 2nd arg: nums[0]
    movl 4(%rax), %edx       # 3rd arg: nums[1]
    movl 8(%rax), %ecx       # 4th arg: nums[2]
    movl 12(%rax), %r8d      # 5th arg: nums[3]
    movl 16(%rax), %r9d      # 6th arg: nums[4]
    xor  %eax, %eax          # required: # of FP args in varargs (0)
    call printf

    xorq %rax, %rax

    addq $24, %rsp

    movq %rbp, %rsp
    popq %rbp

