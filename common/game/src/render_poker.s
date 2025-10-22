.section .note.GNU-stack,"",@progbits

.global .cards_x
.global .card_y
.global .card_w
.global .card_h

.section .data
.extern window_width
.extern window_height
.extern game_ren
.extern SDL_LoadBMP
.extern SDL_CreateTextureFromSurface
.extern SDL_DestroySurface
.extern SDL_RenderTexture
.extern SDL_RenderPresent
.extern SDL_DestroyTexture

.menu_w: .long 920
.menu_h: .long 540
.menu_x: .long 0
.menu_y: .long 0

.card_padding: .long 10
.menu_x_padding: .long 240


.card_w: .long 88
.card_h: .long 124
.cards_x: .long 0,0,0,0,0
.card_y: .long 0

card1: .quad 0
card2: .quad 0
card3: .quad 0
card4: .quad 0
card5: .quad 0

.section .text
.global render_hand
.extern render_scene
.extern draw_text_texture

render_hand:
    pushq %rbp
    movq %rsp, %rbp
    subq $32, %rsp 

    pushq %r12
    pushq %rbx
    pushq %r9
    
    movq %rdi, %r12
    
    movl window_width(%rip), %eax
    subl .menu_w(%rip), %eax
    shrl $1, %eax
    movl %eax, .menu_x(%rip)

    movl window_height(%rip), %eax
    subl .menu_h(%rip), %eax
    shrl $1, %eax
    movl %eax, .menu_y(%rip)

    leaq .cards_x(%rip), %r8

    movl .menu_x(%rip), %eax
    addl .menu_x_padding(%rip), %eax
    movl %eax, (%r8)

    movq $1, %rcx
.calculate_x_loop:
    cmpq $5, %rcx
    je .x_calc_done

    movl -4(%r8,%rcx,4), %eax
    addl .card_w(%rip), %eax
    addl .card_padding(%rip), %eax
    movl %eax, (%r8,%rcx,4)

    incq %rcx
    jmp .calculate_x_loop
.x_calc_done:

    movl .menu_y(%rip), %eax
    addl $300, %eax 
    movl %eax, .card_y(%rip)
    
    leaq card1(%rip), %r9
    movq $0, %rbx
.load_card_loop:
    cmpq $5, %rbx
    je .start_drawing

    movq %r12, %rdi
    movq %rbx, %rdx
    imulq $32, %rdx
    addq %rdx, %rdi
    call SDL_LoadBMP
    movq %rax, -24(%rbp) 

    movq game_ren(%rip), %rdi
    movq -24(%rbp), %rsi
    call SDL_CreateTextureFromSurface
    
    movq %rax, (%r9, %rbx, 8) 
    
    movq -24(%rbp), %rdi
    call SDL_DestroySurface
    
    incq %rbx
    jmp .load_card_loop

.start_drawing:
    call render_scene 

    movq $0, %rcx
.draw_card_loop:
    cmpq $5, %rcx
    je .present_and_return

    leaq .cards_x(%rip), %r8
    movl (%r8, %rcx, 4), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -16(%rbp)
    
    movl .card_y(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -12(%rbp)
    movl .card_w(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -8(%rbp)
    movl .card_h(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -4(%rbp)

    movq game_ren(%rip), %rdi
    leaq card1(%rip), %r9
    movq (%r9, %rcx, 8), %rsi
    movq $0, %rdx
    leaq -16(%rbp), %rcx
    call SDL_RenderTexture 

    incq %rcx
    jmp .draw_card_loop

.present_and_return:
    call SDL_RenderPresent

    leaq card1(%rip), %rax
    
    popq %r9
    popq %rbx
    popq %r12
    
    addq $32, %rsp
    movq %rbp, %rsp
    popq %rbp
    ret
    