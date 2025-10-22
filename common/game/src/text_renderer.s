.section .note.GNU-stack,"",@progbits

.section .text
.global draw_text

# draw_text(string, x, y)
draw_text:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    # 8 for the string pointer (-8 to -1)
    # 4 for the x (-12 to -9)
    # 4 for the y (-16 to -13)

    movq %rdi, -8(%rbp) # string
    movss %xmm0, -12(%rbp) # x
    movss %xmm0, -16(%rbp) # y

    movq game_text(%rip), %rdi
    movq -8(%rbp), %rsi
    movq $0, %rdx
    call TTF_SetTextString

    movq game_text(%rip), %rdi
    movss -12(%rbp), %xmm0
    movss -16(%rbp), %xmm1
    call TTF_DrawRendererText

    addq $16, %rsp
    movq %rsp, %rbp
    popq %rbp
    ret
