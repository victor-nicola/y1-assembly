.data
fmt: .asciz "%ld"

.text
.global main

main:
pushq   %rbp
movq    %rsp, %rbp

movq    $1, %rax
pushq   $8
pushq   $4
pushq   $7
movq    $5, %rdi
addq    $8, %rsp
call foo
movq    %rax, %rsi
leaq    fmt(%rip), %rdi

foo:
pushq   %rbp
movq    %rsp, %rbp

pushq   %rdi
mulq    -8(%rbp)
addq    16(%rbp), %rax

movq    %rbp, %rsp
popq    %rbp
ret
