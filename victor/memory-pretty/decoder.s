.include "final.s"

.text
output_normal: .asciz "\x1B[48;5;%ldm\x1B[38;5;%ldm%c"
output_reset: .asciz "\x1B[0m"
output_stop_blink: .asciz "\x1B[25m"
output_bold: .asciz "\x1B[1m"
output_faint: .asciz "\x1B[2m"
output_conceal: .asciz "\x1B[8m"
output_reveal: .asciz "\x1B[28m"
output_blink: .asciz "\x1B[5m"
output_ch: .asciz "%c"

print_char_loop:
    pushq %rbp
    movq %rsp, %rbp
    
    pushq %r15
    movq $0, %r15
    jmp for_start

for_start:
    cmp %r13, %r15
    jge for_end

    cmp %r10, %r11
    je print_effect

    jmp print_normal

print_effect:
    cmp $0, %r10
    je print_reset

    cmp $37, %r10
    je print_stop_blink

    cmp $42, %r10
    je print_bold

    cmp $66, %r10
    je print_faint

    cmp $105, %r10
    je print_conceal

    cmp $153, %r10
    je print_reveal

    cmp $182, %r10
    je print_blink

    jmp continue

print_normal:
    pushq %r10
    pushq %r11

    movq $0, %rax
    movq $output_normal, %rdi
    movq %r10, %rsi
    movq %r11, %rdx
    movq %r14, %rcx
    call printf

    popq %r11
    popq %r10

    jmp continue

print_reset:
    pushq %r10
    pushq %r11

    movq $0, %rax
    movq $output_reset, %rdi
    call printf

    movq $0, %rax
    movq $output_ch, %rdi
    movq %r14, %rsi
    call printf

    popq %r11
    popq %r10

    jmp continue

print_stop_blink:
    pushq %r10
    pushq %r11

    movq $0, %rax
    movq $output_stop_blink, %rdi
    call printf

    movq $0, %rax
    movq $output_ch, %rdi
    movq %r14, %rsi
    call printf

    popq %r11
    popq %r10

    jmp continue

print_bold:
    pushq %r10
    pushq %r11

    movq $0, %rax
    movq $output_bold, %rdi
    call printf

    movq $0, %rax
    movq $output_ch, %rdi
    movq %r14, %rsi
    call printf

    popq %r11
    popq %r10

    jmp continue

print_faint:
    pushq %r10
    pushq %r11

    movq $0, %rax
    movq $output_faint, %rdi
    call printf

    movq $0, %rax
    movq $output_ch, %rdi
    movq %r14, %rsi
    call printf

    popq %r11
    popq %r10

    jmp continue

print_conceal:
    pushq %r10
    pushq %r11

    movq $0, %rax
    movq $output_conceal, %rdi
    call printf

    movq $0, %rax
    movq $output_ch, %rdi
    movq %r14, %rsi
    call printf

    popq %r11
    popq %r10

    jmp continue

print_reveal:
    pushq %r10
    pushq %r11

    movq $0, %rax
    movq $output_reveal, %rdi
    call printf

    movq $0, %rax
    movq $output_ch, %rdi
    movq %r14, %rsi
    call printf

    popq %r11
    popq %r10

    jmp continue

print_blink:
    pushq %r10
    pushq %r11

    movq $0, %rax
    movq $output_blink, %rdi
    call printf

    movq $0, %rax
    movq $output_ch, %rdi
    movq %r14, %rsi
    call printf

    popq %r11
    popq %r10

    jmp continue

continue:
    incq %r15
    jmp for_start

for_end:
    popq %r15
    
    movq %rbp, %rsp
    popq %rbp
    ret

print_message:
    pushq %rbp
    movq %rsp, %rbp
    
    pushq %r12
    pushq %r13
    pushq %r14

print_main_loop:
    movq $0xFFFFFF, %rcx

    # next address
    movq %r8, %r12 # moved the current element into the next address variable
    shr $16, %r12
    and %rcx, %r12

    movq $0xFF, %rcx

    # background color
    movq %r8, %r10 # moved the current element into the background color variable
    shr $56, %r10

    # foreground color
    movq %r8, %r11 # moved the current element into the foreground color variable
    shr $48, %r11
    and %rcx, %r11

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
    jmp print_main_loop

print_message_end:
    popq %r14
    popq %r13
    popq %r12

    movq %rbp, %rsp
    popq %rbp
    ret

.global main

main:
    pushq %rbp
    movq %rsp, %rbp

    leaq MESSAGE(%rip), %rbx
    movq (%rbx), %r8
    call print_message

    movq $0, %rax
    movq $output_reset, %rdi
    call printf

    movq $0, %rdi
    movq %rbp, %rsp
    popq %rbp
    call exit
