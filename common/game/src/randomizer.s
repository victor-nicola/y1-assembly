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

bmpfmt: .asciz "../assets/cards/%u.bmp"
handfmt: .asciz "Hand Detected (0=High Card, 1=Pair, 9=Royal Flush): %u\n"


.text
.global main
.extern render_hand

rand52:
    pushq %rbp
    movq %rsp, %rbp

    subq $16, %rsp 

    get_random_loop:
        movq %rsp, %rdi
        movl $4, %esi
        xorq %rdx, %rdx
        movq $318, %rax
        syscall

        cmpl $4, %eax
        jne get_random_loop

        movl (%rsp), %eax

        cmpl $0xFFFFFFD0, %eax
        jge get_random_loop

        xorl %edx, %edx
        movl $52, %ecx
        divl %ecx

        incl %edx
        movl %edx, %eax
        
        addq $16, %rsp

        movq %rbp, %rsp
        popq %rbp

        ret

rand5_unique_sorted:
    pushq %rbp
    movq %rsp, %rbp

    pushq   %rbx
    pushq   %r12
    pushq   %r13
    subq $8, %rsp

    movq %rdi, %r12

    xorq %rbx, %rbx

    outer_loop:
        call rand52
        movl %eax, %r13d
        xorq %rcx, %rcx
        check_dup_loop:
            cmpq %rbx, %rcx
            je no_dup_found

            movl (%r12, %rcx, 4), %edx
            cmpl %edx, %r13d
            je outer_loop

            incq %rcx
            jmp check_dup_loop
        no_dup_found:
            movl %r13d, (%r12, %rbx, 4)
            incq %rbx
            cmpq $5, %rbx
            jl outer_loop
    

    bubble_sort:
        xorq %rbx, %rbx
        outer_sort_loop:
            xorq %rcx, %rcx
            inner_sort_loop:
                movl 4(%r12, %rcx, 4), %edx
                movl (%r12, %rcx, 4), %eax

                cmpl %edx, %eax
                jl no_swap

                movl %edx, (%r12, %rcx, 4)
                movl %eax, 4(%r12, %rcx, 4)

            no_swap:
                incl %ecx
                cmpl $4, %ecx
                jl inner_sort_loop

                incl %ebx
                cmpl $4, %ebx
                jl outer_sort_loop

    movq %r12, %rax

    addq $8, %rsp
    popq %r13
    popq %r12
    popq %rbx

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
    movl $1, straight(%rip)
    movl (%r13), %eax
    
    movq $1, %rcx
    straight_loop:
        movl (%r13, %rcx, 4), %edx
        
        movl %eax, %ebx
        addl %ecx, %ebx
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
    movl $1, flush(%rip)
    movl (%r12), %eax
    call getcardsuit
    movl %eax, %r14d

    movq $1, %rcx
    flush_loop:
        movl (%r12, %rcx, 4), %eax
        call getcardsuit

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

.global get_poker_hand

get_poker_hand:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12 
    pushq %r13
    pushq %r14

    subq $240, %rsp

    leaq -40(%rbp), %rdi
    call rand5_unique_sorted 

    movq %rax, %r12

    xorq %rbx, %rbx
    sprintf_loop:
        movq %rbx, %rdi
        imulq $32, %rdi
        leaq -80(%rbp), %rsi
        addq %rsi, %rdi
        leaq bmpfmt(%rip), %rsi
        movl (%r12, %rbx, 4), %edx
        xorl %eax, %eax
        call sprintf
        incq %rbx
        cmpq $5, %rbx
        jl sprintf_loop

    leaq -80(%rbp), %rdi
    call render_hand

    movq %rax, %r15

    leaq -60(%rbp), %r13
    xorq %rbx, %rbx
    create_rank_array_loop:
        movl (%r12, %rbx, 4), %eax
        subl $1, %eax
        movl $13, %ecx
        xorl %edx, %edx
        divl %ecx
        movl %edx, (%r13, %rbx, 4)
        incq %rbx
        cmpq $5, %rbx
        jl create_rank_array_loop

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

    movl $0, group1_size(%rip)
    movl $0, group2_size(%rip)

    xorq %rbx, %rbx
    pair_check_loop:
        movl $1, samecardcounter(%rip)
        movl (%r13, %rbx, 4), %r14d

        movq %rbx, %rcx
        incq %rcx
        
        inner_pair_check_loop:
            cmpq $5, %rcx
            jge end_inner_pair_loop

            movl (%r13, %rcx, 4), %eax
            cmpl %r14d, %eax
            jne end_inner_pair_loop 

            incl samecardcounter(%rip)
            incq %rcx
            jmp inner_pair_check_loop
    
    end_inner_pair_loop:
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
        call check_straight
        call check_flush

    movl $0, %eax
    
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
    jmp end_getpoker_hand

hand_is_flush_or_better:
    movl straight(%rip), %ecx
    cmpl $1, %ecx
    jne hand_is_flush
    
    movl (%r13), %eax
    cmpl $1, %eax
    je hand_is_royalflush
    
    movl $8, %eax
    jmp end_getpoker_hand

hand_is_pair:
    movl $1, %eax
    jmp end_getpoker_hand
hand_is_2pair:
    movl $2, %eax
    jmp end_getpoker_hand
hand_is_threeofakind:
    movl $3, %eax
    jmp end_getpoker_hand
hand_is_straight:
    movl $4, %eax
    jmp end_getpoker_hand
hand_is_flush:
    movl $5, %eax
    jmp end_getpoker_hand
hand_is_fullhouse:
    movl $6, %eax
    jmp end_getpoker_hand
hand_is_fourofakind:
    movl $7, %eax
    jmp end_getpoker_hand
hand_is_royalflush:
    movl $9, %eax

end_getpoker_hand:

    addq $240, %rsp
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    movq %rbp, %rsp
    popq %rbp
    ret
