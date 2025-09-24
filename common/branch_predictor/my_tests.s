.global main
.extern predict_branch
.extern actual_branch
.extern init
.extern printf

.section .text

.op_pointers:
    .quad 0x400500, 0x400508, 0x400510, 0x400518
    .quad 0x400520, 0x400528, 0x400530, 0x400538
    .quad 0x400540, 0x400548, 0x400550, 0x400558
    .quad 0x400560, 0x400568, 0x400570, 0x400578
    .quad 0x400580, 0x400588, 0x400590, 0x400598
    .quad 0x4005A0, 0x4005A8, 0x4005B0, 0x4005B8
    .quad 0x4005C0, 0x4005C8, 0x4005D0, 0x4005D8
    .quad 0x4005E0, 0x4005E8, 0x4005F0, 0x4005F8
    .quad 0x400600, 0x400608, 0x400610, 0x400618
    .quad 0x400620, 0x400628, 0x400630, 0x400638
    .quad 0x400640, 0x400648, 0x400650, 0x400658
    .quad 0x400660, 0x400668, 0x400670, 0x400678
    .quad 0x400680, 0x400688, 0x400690, 0x400698
    .quad 0x4006A0, 0x4006A8, 0x4006B0, 0x4006B8
    .quad 0x4006C0, 0x4006C8, 0x4006D0, 0x4006D8
    .quad 0x4006E0, 0x4006E8, 0x4006F0, 0x4006F8

.branch_outcomes:
    .quad 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0
    .quad 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0
    .quad 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0
    .quad 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0

main:
    pushq %rbp
    movq %rsp, %rbp
    subq $8, %rsp

    call init

    movq $.op_pointers, %r15          # Base address of instruction pointers
    movq $.branch_outcomes, %r11     # Base address of branch outcomes
    xorq %r12, %r12                  # Total score
    xorq %r13, %r13                  # Current branch index
    movq $64, %r14                   # Total number of branches to test

test_loop:
    cmpq %r14, %r13
    je test_end

    # Pass instruction pointer as first argument (rdi).
    movq (%r15, %r13, 8), %rdi
    
    # Load the actual branch outcome as second argument (rsi)
    movq (%r11, %r13, 8), %rsi

    call predict_branch

    cmpq %rax, %rsi
    jne actual_branch_call

    incq %r12
    jmp end_actual_branch_call

actual_branch_call:
    # Pass instruction pointer as first argument (rdi)
    movq (%r15, %r13, 8), %rdi
    
    # Pass the actual branch outcome as second argument (rsi)
    movq (%r11, %r13, 8), %rsi
    
    call actual_branch

end_actual_branch_call:
    incq %r13
    jmp test_loop

test_end:
    movq %r12, %rax
    movq $100, %rdx
    mulq %rdx
    divq %r14

    movq $format_str, %rdi
    movq %r12, %rsi
    movq %rax, %rdx
    xorq %rax, %rax

    call printf

    addq $8, %rsp
    movq %rbp, %rsp
    popq %rbp
    ret

.section .data
format_str:
    .string "Branch Prediction Score: %d / 64, or %d%% correct.\n"
