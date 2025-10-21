.section .note.GNU-stack,"",@progbits
.data
samecardcounter: .long 1
group1_size: .long 0
group2_size: .long 0
straight: .long 1
flush: .long 1
fourofakind: .long 0
straightflush: .long 0
royalflush: .long 0


fmt: .asciz "%u %u %u %u %u \n"
bmpfmt: .asciz "../assets/cards/%u.bmp"
handfmt: .asciz "Hand Detected (0=High Card, 1=Pair, 9=Royal Flush): %u\n"


.text
.global main
.extern render_hand

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
                movl 4(%r12, %rcx, 4), %edx # array[j+1] -> edx
                movl (%r12, %rcx, 4), %eax # array[j] -> eax

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
    # input in %eax (1-52), returns suit (1-4) in %eax
    cmpl $14, %eax
    jl clubs
    cmpl $27, %eax
    jl diamonds
    cmpl $40, %eax
    jl hearts
    jmp spades

    clubs:
        movl $1, %eax
        ret
    diamonds:
        movl $2, %eax
        ret
    hearts:
        movl $3, %eax
        ret
    spades:
        movl $4, %eax
        ret

check_straight:
    # input: %r13 points to the sorted RANK array
    movl $1, straight(%rip)
    movl (%r13), %eax # get rank of first card
    
    movq $1, %rcx # indexing from the second card
    straight_loop:
        movl (%r13, %rcx, 4), %edx # get rank of current card
        
        movl %eax, %ebx
        addl %ecx, %ebx # expected rank = rank of first card + index
        cmpl %ebx, %edx 
        jne not_straight

        incq %rcx
        cmpq $5, %rcx
        jl straight_loop
        jmp straight_finish

    not_straight:
        movl $0, straight(%rip)
    straight_finish:
        ret

check_flush:
    # input: %r12 points to the original sorted card array
    movl $1, flush(%rip)
    movl (%r12), %eax
    call getcardsuit
    movl %eax, %r14d # Suit of first card

    movq $1, %rcx
    flush_loop:
        movl (%r12, %rcx, 4), %eax
        call getcardsuit # Suit of current card in %eax

        cmpl %eax, %r14d
        jne not_flush

        incq %rcx
        cmpq $5, %rcx
        jl flush_loop
        jmp flush_finish

    not_flush:
        movl $0, flush(%rip)
    flush_finish:
        ret


get_poker_hand:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12 
    pushq %r13
    pushq %r14

    subq $104, %rsp # 40 for strings, 20 for original, 20 for ranks, padding

    leaq -40(%rbp), %rdi
    call rand5_unique_sorted 

    movq %rax, %r12 # r12 has original sorted cards (1-52)

    # Loop to create filenames with sprintf
    xorq %rbx, %rbx
    sprintf_loop:
        movq %rbx, %rdi
        imulq $8, %rdi
        addq %rsp, %rdi         # Arg 1: Destination buffer for string
        leaq bmpfmt(%rip), %rsi # Arg 2: Format string
        movl (%r12, %rbx, 4), %edx      # Arg 3: Card number
        xorl %eax, %eax
        call sprintf
        incq %rbx
        cmpq $5, %rbx
        jl sprintf_loop

    movq %rsp, %rdi
    call render_hand

    movq %rax, %r15

    # Create and sort the rank-only array
    leaq -60(%rbp), %r13 # r13 will point to the rank array
    xorq %rbx, %rbx
    create_rank_array_loop:
        movl (%r12, %rbx, 4), %eax # Get card number
        subl $1, %eax
        movl $13, %ecx
        xorl %edx, %edx
        divl %ecx
        movl %edx, (%r13, %rbx, 4) # Store rank in new array
        incq %rbx
        cmpq $5, %rbx
        jl create_rank_array_loop

    # Bubble sort the rank array in r13
    xorq %rbx, %rbx 
    rank_sort_outer:
        xorq %rcx, %rcx 
        rank_sort_inner:
            movl 4(%r13, %rcx, 4), %edx 
            movl (%r13, %rcx, 4), %eax 
            cmpl %edx, %eax
            jl rank_no_swap
            movl %edx, (%r13, %rcx, 4)
            movl %eax, 4(%r13, %rcx, 4)
        rank_no_swap:
            incl %ecx
            cmpl $4, %ecx
            jl rank_sort_inner
        incl %ebx
        cmpl $4, %ebx
        jl rank_sort_outer

    # Reset group sizes and evaluate using the RANK array in r13
    movl $0, group1_size(%rip)
    movl $0, group2_size(%rip)

    xorq %rbx, %rbx # i = 0
    pair_check_loop:
        movl $1, samecardcounter(%rip)
        movl (%r13, %rbx, 4), %r14d # Get rank of card i

        movq %rbx, %rcx
        incq %rcx # j = i + 1
        
        inner_pair_check_loop:
            cmpq $5, %rcx
            jge end_inner_pair_loop

            movl (%r13, %rcx, 4), %eax # Get rank of card j
            cmpl %r14d, %eax
            jne end_inner_pair_loop 

            incl samecardcounter(%rip)
            incq %rcx
            jmp inner_pair_check_loop
    
    end_inner_pair_loop:
        # Update group sizes
        movl samecardcounter(%rip), %eax
        movl group1_size(%rip), %ecx
        cmpl %ecx, %eax
        jle check_group2
        movl %ecx, group2_size(%rip)
        movl %eax, group1_size(%rip)
        jmp continue_pair_loop
    check_group2:
        movl group2_size(%rip), %ecx
        cmpl %ecx, %eax
        jle continue_pair_loop
        movl %eax, group2_size(%rip)

    continue_pair_loop:
        movl samecardcounter(%rip), %eax
        addq %rax, %rbx 
        cmpq $5, %rbx
        jl pair_check_loop

    end_pair_check_loop:
        call check_straight # Must use RANK array, so r13 is implicitly used
        call check_flush    # Must use ORIGINAL array, so r12 is implicitly used

    # Final Hand Evaluation
    movl $0, %eax # Default to high card
    
    movl group1_size(%rip), %ecx
    cmpl $4, %ecx
    je hand_is_fourofakind
    
    movl group2_size(%rip), %edx
    cmpl $3, %ecx
    je is_group1_three
    cmpl $2, %ecx
    je is_group1_two
    jmp check_straights_and_flushes 

is_group1_three: 
    cmpl $2, %edx
    je hand_is_fullhouse
    jmp hand_is_threeofakind

is_group1_two: 
    cmpl $2, %edx
    je hand_is_2pair
    jmp hand_is_pair

check_straights_and_flushes:
    movl flush(%rip), %ecx
    cmpl $1, %ecx
    je hand_is_flush_or_better

    movl straight(%rip), %ecx
    cmpl $1, %ecx
    je hand_is_straight
    jmp end_getpokerhand

hand_is_flush_or_better:
    movl straight(%rip), %ecx
    cmpl $1, %ecx
    jne hand_is_flush
    
    movl (%r13), %eax # Check lowest RANK for royal flush
    cmpl $1, %eax # Rank 1 is Ace
    je hand_is_royalflush
    
    movl $8, %eax
    jmp end_getpokerhand

hand_is_pair:
    movl $1, %eax
    jmp end_getpokerhand
hand_is_2pair:
    movl $2, %eax
    jmp end_getpokerhand
hand_is_threeofakind:
    movl $3, %eax
    jmp end_getpokerhand
hand_is_straight:
    movl $4, %eax
    jmp end_getpokerhand
hand_is_flush:
    movl $5, %eax
    jmp end_getpokerhand
hand_is_fullhouse:
    movl $6, %eax
    jmp end_getpokerhand
hand_is_fourofakind:
    movl $7, %eax
    jmp end_getpokerhand
hand_is_royalflush:
    movl $9, %eax

end_getpoker_hand:
    addq $104, %rsp
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret
