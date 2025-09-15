.include "final.s"

.text
output_normal: .asciz "\x1B[48;5;%ldm\x1B[38;5;%ldm%c"
output_reset: .asciz "\x1B[0m%c"
output_stop_blink: .asciz "\x1B[25m%c"
output_bold: .asciz "\x1B[1m%c"
output_faint: .asciz "\x1B[2m%c"
output_conceal: .asciz "\x1B[8m%c"
output_reveal: .asciz "\x1B[28m%c"
output_blink: .asciz "\x1B[5m%c"

decode:
    pushq %rbp
    movq %rsp, %rbp

    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    movq (%rdi), %r8

    loop:
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

        movq $0, %r15
        loop_char:
            cmp %r13, %r15
            jge after_loop_char

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
                pushq %rdi

                movq $0, %rax
                movq $output_normal, %rdi
                movq %r10, %rsi
                movq %r11, %rdx
                movq %r14, %rcx
                call printf
                
                popq %rdi
                popq %r11
                popq %r10

                jmp continue

            print_reset:
                pushq %r10
                pushq %r11
                pushq %rdi

                movq $0, %rax
                movq $output_reset, %rdi
                movq %r14, %rsi
                call printf

                popq %rdi
                popq %r11
                popq %r10

                jmp continue

            print_stop_blink:
                pushq %r10
                pushq %r11
                pushq %rdi

                movq $0, %rax
                movq $output_stop_blink, %rdi
                movq %r14, %rsi
                call printf

                popq %rdi
                popq %r11
                popq %r10

                jmp continue

            print_bold:
                pushq %r10
                pushq %r11
                pushq %rdi

                movq $0, %rax
                movq $output_bold, %rdi
                movq %r14, %rsi
                call printf

                popq %rdi
                popq %r11
                popq %r10

                jmp continue

            print_faint:
                pushq %r10
                pushq %r11
                pushq %rdi

                movq $0, %rax
                movq $output_faint, %rdi
                movq %r14, %rsi
                call printf

                popq %rdi
                popq %r11
                popq %r10

                jmp continue

            print_conceal:
                pushq %r10
                pushq %r11
                pushq %rdi

                movq $0, %rax
                movq $output_conceal, %rdi
                movq %r14, %rsi
                call printf
                
                popq %rdi
                popq %r11
                popq %r10

                jmp continue

            print_reveal:
                pushq %r10
                pushq %r11
                pushq %rdi

                movq $0, %rax
                movq $output_reveal, %rdi
                movq %r14, %rsi
                call printf

                popq %rdi
                popq %r11
                popq %r10

                jmp continue

            print_blink:
                pushq %r10
                pushq %r11
                pushq %rdi

                movq $0, %rax
                movq $output_blink, %rdi
                movq %r14, %rsi
                call printf

                popq %rdi
                popq %r11
                popq %r10

                jmp continue

            continue:
                incq %r15
                jmp loop_char
        
        after_loop_char:
            cmp $0, %r12
            je loop_end

            movq (%rdi, %r12, 8), %r8
            jmp loop

    loop_end:
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbx

        movq %rbp, %rsp
        popq %rbp
        ret

.global main

main:
    pushq %rbp
    movq %rsp, %rbp

    leaq MESSAGE(%rip), %rdi
    call decode

    movq %rbp, %rsp
    popq %rbp
    call exit
