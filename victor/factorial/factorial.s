.text
msg: .asciz "Input a number\n"
input_format: .asciz "%ld"
output_format: .asciz "Factorial of %ld is %ld\n"

factorial:
    pushq %rbp
    movq %rsp, %rbp

    cmp $1, %rdi        #check for 0/1
    jle base_case

    decq %rdi           #decrement rdi

    pushq %rdi
    pushq %rsi
    # basically the function decrements rdi to 1 recursively, and then for each return it gets incremented by 1
    call factorial
    popq %rsi
    popq %rdi

    incq %rdi           #increment rdi because of the decrementation before the call
    imulq %rdi, %rax    #multiply rax by rdi
    
    movq %rbp, %rsp
    popq %rbp
    ret

base_case:
    movq $1, %rax       #if 0/1 result = 1
    movq %rbp, %rsp
    popq %rbp
    ret

.global main
main:
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rax           
    movq $msg, %rdi         
    call printf

    subq $16, %rsp
    leaq -16(%rbp), %rsi

    movq $0, %rax
    movq $input_format, %rdi
    call scanf                          #read number

    movq -16(%rbp), %rdi
    call factorial                      #call function

    pushq %rax
    movq $output_format, %rdi
    movq -16(%rbp), %rsi
    movq %rax, %rdx
    movq $0, %rax
    call printf
    popq %rax

    movq %rbp, %rsp
    popq %rbp
    call exit
