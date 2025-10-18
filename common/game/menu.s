.section .note.GNU-stack,"",@progbits

.section .data

.play_button_y: .long 0
.quit_button_y: .long 0

.button_x: .long 0
.button_w: .long 0
.button_h: .long 0
.button_gap: .long 0

play_button: .quad 0
quit_button: .quad 0

.button_x_percentage: .long 50
.button_w_percentage: .long 20
.button_h_percentage: .long 10
.button_gap_percentage: .long 5

.section .text
.global render_menu
.extern game_font
.extern draw_text_texture

render_menu:
    pushq %rbp
    movq %rsp, %rbp

    subq $152, %rsp
    # 16 for menu overlay SDL_FRect (-16 to -1)
    # 128 for the SDL_Event union (-144 to -17)
    # 8 for rdi (-152 to -145)
    pushq %rbx
    movq %rdi, -152(%rbp)

    # calculate button props
    # .button_w
    movl window_width(%rip), %eax
    imull .button_w_percentage(%rip)

    movl $0, %edx
    movl $100, %ecx
    idivl %ecx
    movl %eax, .button_w(%rip)

    # .button_h
    movl window_height(%rip), %eax
    imull .button_h_percentage(%rip)

    movl $0, %edx
    movl $100, %ecx
    idivl %ecx
    movl %eax, .button_h(%rip)

    # .button_gap
    movl window_height(%rip), %eax
    imull .button_gap_percentage(%rip)

    movl $0, %edx
    movl $100, %ecx
    idivl %ecx
    movl %eax, .button_gap(%rip) 

    # .button_x computation
    movl .button_w(%rip), %eax
    movl window_width(%rip), %ecx
    subl %eax, %ecx
    shrl $1, %ecx # divide by 2
    movl %ecx, .button_x(%rip)

    # .play_button_y computation
    movl .button_h(%rip), %eax
    shll $1, %eax # multiply button height by 2
    addl .button_gap(%rip), %eax
    movl window_height(%rip), %ecx
    subl %eax, %ecx
    shrl $1, %ecx # divide by 2
    movl %ecx, .play_button_y(%rip)

    # .quit_button_y computation
    movl .play_button_y(%rip), %ecx
    movl .button_h(%rip), %edx
    addl %edx, %ecx
    addl .button_gap(%rip), %ecx
    movl %ecx, .quit_button_y(%rip)

    # load the play button
    leaq play_button_path(%rip), %rdi
    call SDL_LoadBMP
    movq %rax, play_button(%rip)
    movq %rax, %rbx # save surface to destroy later
    
    movq game_ren(%rip), %rdi
    movq play_button(%rip), %rsi
    call SDL_CreateTextureFromSurface
    movq %rax, play_button(%rip)

    movq play_button(%rip), %rdi
    movl $0, %esi
    call SDL_SetTextureScaleMode

    movq %rbx, %rdi
    call SDL_DestroySurface

    # load the quit button
    leaq quit_button_path(%rip), %rdi
    call SDL_LoadBMP
    movq %rax, quit_button(%rip)
    movq %rax, %rbx # save surface to destroy later
    
    movq game_ren(%rip), %rdi
    movq quit_button(%rip), %rsi
    call SDL_CreateTextureFromSurface
    movq %rax, quit_button(%rip)

    movq quit_button(%rip), %rdi
    movl $0, %esi
    call SDL_SetTextureScaleMode

    movq %rbx, %rdi
    call SDL_DestroySurface

    .menu_loop:
        # draw game scene
        movq -152(%rbp), %rdi
        call render_scene

        # ensure nice opacity blend (for opacity overlay)
        # SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
        movq game_ren(%rip), %rdi
        movq $0x00000001, %rsi
        call SDL_SetRenderDrawBlendMode

        # draw overlay
        # SDL_SetRenderDrawColor(renderer, 0, 0, 0, 127);
        movq game_ren(%rip), %rdi
        movl $0, %esi
        movl $0, %edx
        movl $0, %ecx
        movl $127, %r8d
        call SDL_SetRenderDrawColor

        movl $0, -16(%rbp) # x
        movl $0, -12(%rbp) # y

        movl window_width(%rip), %eax
        # convert integer to float
        cvtsi2ss %eax, %xmm0
        movss %xmm0, -8(%rbp) # w
        
        movl window_height(%rip), %eax
        # convert integer to float
        cvtsi2ss %eax, %xmm0
        movss %xmm0, -4(%rbp) # h

        movq game_ren(%rip), %rdi
        leaq -16(%rbp), %rsi
        call SDL_RenderFillRect

        # draw play button
        movl .button_x(%rip), %eax
        cvtsi2ss %eax, %xmm0
        movss %xmm0, -16(%rbp) # x
        movl .play_button_y(%rip), %eax
        cvtsi2ss %eax, %xmm0
        movss %xmm0, -12(%rbp) # y

        movl .button_w(%rip), %eax
        # convert integer to float
        cvtsi2ss %eax, %xmm0
        movss %xmm0, -8(%rbp) # w
        
        movl .button_h(%rip), %eax
        # convert integer to float
        cvtsi2ss %eax, %xmm0
        movss %xmm0, -4(%rbp) # h

        movq game_ren(%rip), %rdi
        movq play_button(%rip), %rsi
        movq $0, %rdx # we want all of the tile to be rendered
        leaq -16(%rbp), %rcx # where we want to render it
        call SDL_RenderTexture

        # draw quit button
        movl .button_x(%rip), %eax
        cvtsi2ss %eax, %xmm0
        movss %xmm0, -16(%rbp) # x
        movl .quit_button_y(%rip), %eax
        cvtsi2ss %eax, %xmm0
        movss %xmm0, -12(%rbp) # y

        movl .button_w(%rip), %eax
        # convert integer to float
        cvtsi2ss %eax, %xmm0
        movss %xmm0, -8(%rbp) # w
        
        movl .button_h(%rip), %eax
        # convert integer to float
        cvtsi2ss %eax, %xmm0
        movss %xmm0, -4(%rbp) # h

        movq game_ren(%rip), %rdi
        movq quit_button(%rip), %rsi
        movq $0, %rdx # we want all of the tile to be rendered
        leaq -16(%rbp), %rcx # where we want to render it
        call SDL_RenderTexture

        # reset opacity blend
        # SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
        movq game_ren(%rip), %rdi
        movq $0x00000000, %rsi
        call SDL_SetRenderDrawBlendMode

        # process input
        leaq -144(%rbp), %rdi # place to put the SDL_Event
        call SDL_PollEvent
        cmpl $0, %eax # check if SDL_PollEvent returned 0 (no event)
        je .show_menu # if no event loop again

        # check if the event type is SDL_QUIT
        cmpl $0x100, -144(%rbp)
        je .quit_game

        # check if the event type is SDL_EVENT_MOUSE_BUTTON_DOWN
        cmpl $0x401, -144(%rbp)
        jne .show_menu

        # the button value is stored with a 24 byte offset from the SDL_Event address
        cmpb $1, -120(%rbp) # if the left mouse button was pressed
        jne .show_menu

        # test which menu button was clicked
        # the x value is stored with a 28 byte offset from the SDL_Event address
        cvttss2si -116(%rbp), %eax
        # the y value is stored with a 32 byte offset from the SDL_Event address
        cvttss2si -112(%rbp), %ecx

        # x in eax
        # y in ecx
        # lower y button bound in label
        # upper y button bound in %edx
        # lower x button bound in label
        # upper x button bount in %r8
        movl .button_x(%rip), %r8d
        addl .button_w(%rip), %r8d

        # get play bound
        movl .play_button_y(%rip), %edx
        addl .button_h(%rip), %edx

        # test for play
        cmpl .play_button_y(%rip), %ecx
        jl .show_menu

        cmpl .button_x(%rip), %eax
        jl .show_menu

        cmpl %r8d, %eax
        jg .show_menu

        cmpl %edx, %ecx
        jl .go_back

        # get quit bound
        movl .quit_button_y(%rip), %edx
        addl .button_h(%rip), %edx
        
        # test for quit
        cmpl .quit_button_y(%rip), %ecx
        jl .show_menu

        cmpl %edx, %ecx
        jl .quit_game

        jmp .show_menu

        .go_back:
            movq $0, %rax
            jmp .menu_loop_end

        .quit_game:
            movq $-1, %rax
            jmp .menu_loop_end

        .show_menu:
            # SDL_RenderPresent(renderer);
            movq game_ren(%rip), %rdi
            call SDL_RenderPresent
            jmp .menu_loop

        jmp .menu_loop
    
    .menu_loop_end:
        popq %rbx
        addq $152, %rsp # deallocate stack space
        movq %rbp, %rsp
        popq %rbp
        ret
