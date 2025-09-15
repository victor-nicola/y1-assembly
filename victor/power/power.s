.text
    msg: .asciz "Input the base and the exponent\n"
    input_format: .asciz "%ld %ld"
    output_format: .asciz "%ld to the power of %ld is %ld\n"
    # output_format: .asciz "%ld %ld\n"

.global main
main:
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rax
    movq $msg, %rdi
    call printf

    call inout

    mov $0, %rdi
    call exit

inout:
    pushq %rbp
    movq %rsp, %rbp
    
    subq $32, %rsp
    movq $0, %rax
    movq $input_format, %rdi
    leaq -16(%rbp), %rsi
    leaq -32(%rbp), %rdx
    call scanf
    
    movq -16(%rbp), %rdi # base
    movq -32(%rbp), %rsi # exponent
    
    call pow

    movq %rax, %rcx
    movq $0, %rax
    movq $output_format, %rdi
    movq -16(%rbp), %rsi
    movq -32(%rbp), %rdx
    call printf

    movq %rbp, %rsp
    popq %rbp
    ret

pow:
    pushq %rbp
    movq %rsp, %rbp

    mov $0, %rcx
    mov $1, %rax
    for_start:
        cmpq %rsi, %rcx
        jge for_end

        imulq %rdi, %rax

        incq %rcx
        jmp for_start

    for_end:
        movq %rbp, %rsp
        popq %rbp
        ret
