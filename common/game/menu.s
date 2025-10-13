# this directive ensures the stack is not executable for security reasons (i get an error on fedora 42 if i don't have this)
.section .note.GNU-stack,"",@progbits

.section .data

.play_button_y: .long 0
.quit_button_y: .long 0

.button_x: .long 0
.button_w: .long 0
.button_h: .long 0
.button_gap: .long 0

.button_x_percentage: .long 50
.button_w_percentage: .long 10
.button_h_percentage: .long 10
.button_gap_percentage: .long 5

.section .text
.global render_menu

render_menu:
    pushq %rbp
    movq %rsp, %rbp

    subq $160, %rsp
    # 8 for the renderer pointer (-8 to -1)
    # 16 for menu overlay SDL_FRect (-24 to -9)
    # 128 for the SDL_Event union (-152 to -25)
    movq %rdi, -8(%rbp) # save the renderer pointer

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
    addl .button_gap(%rip), %ecx
    addl %ecx, %edx
    movl %edx, .quit_button_y(%rip)

    .menu_loop:
        # draw game scene
        movq -8(%rbp), %rdi
        call render_scene

        # ensure nice opacity blend (for opacity overlay)
        # SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
        movq -8(%rbp), %rdi
        movq $0x00000001, %rsi
        call SDL_SetRenderDrawBlendMode

        # draw overlay
        # SDL_SetRenderDrawColor(renderer, 0, 0, 0, 127);
        movq -8(%rbp), %rdi
        movl $0, %esi
        movl $0, %edx
        movl $0, %ecx
        movl $127, %r8d
        call SDL_SetRenderDrawColor

        movl $0, -24(%rbp) # x
        movl $0, -20(%rbp) # y

        movl window_width(%rip), %eax
        # convert integer to float
        cvtsi2ss %eax, %xmm0
        movss %xmm0, -16(%rbp) # w
        
        movl window_height(%rip), %eax
        # convert integer to float
        cvtsi2ss %eax, %xmm0
        movss %xmm0, -12(%rbp) # h

        movq -8(%rbp), %rdi
        leaq -24(%rbp), %rsi
        call SDL_RenderFillRect

        # draw play button
        # SDL_SetRenderDrawColor(renderer, 0, 255, 0, 255);
        movq -8(%rbp), %rdi
        movl $0, %esi
        movl $255, %edx
        movl $0, %ecx
        movl $255, %r8d
        call SDL_SetRenderDrawColor

        movl .button_x(%rip), %eax
        cvtsi2ss %eax, %xmm0
        movss %xmm0, -24(%rbp) # x
        movl .play_button_y(%rip), %eax
        cvtsi2ss %eax, %xmm0
        movss %xmm0, -20(%rbp) # y

        movl .button_w(%rip), %eax
        # convert integer to float
        cvtsi2ss %eax, %xmm0
        movss %xmm0, -16(%rbp) # w
        
        movl .button_h(%rip), %eax
        # convert integer to float
        cvtsi2ss %eax, %xmm0
        movss %xmm0, -12(%rbp) # h

        movq -8(%rbp), %rdi
        leaq -24(%rbp), %rsi
        call SDL_RenderFillRect

        # draw quit button
        # SDL_SetRenderDrawColor(renderer, 0, 255, 255, 255);
        movq -8(%rbp), %rdi
        movl $0, %esi
        movl $255, %edx
        movl $255, %ecx
        movl $255, %r8d
        call SDL_SetRenderDrawColor

        movl .button_x(%rip), %eax
        cvtsi2ss %eax, %xmm0
        movss %xmm0, -24(%rbp) # x
        movl .quit_button_y(%rip), %eax
        cvtsi2ss %eax, %xmm0
        movss %xmm0, -20(%rbp) # y

        movl .button_w(%rip), %eax
        # convert integer to float
        cvtsi2ss %eax, %xmm0
        movss %xmm0, -16(%rbp) # w
        
        movl .button_h(%rip), %eax
        # convert integer to float
        cvtsi2ss %eax, %xmm0
        movss %xmm0, -12(%rbp) # h

        movq -8(%rbp), %rdi
        leaq -24(%rbp), %rsi
        call SDL_RenderFillRect

        # reset opacity blend
        # SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
        movq -8(%rbp), %rdi
        movq $0x00000000, %rsi
        call SDL_SetRenderDrawBlendMode

        # process input
        leaq -152(%rbp), %rdi # place to put the SDL_Event
        call SDL_PollEvent
        cmpl $0, %eax # check if SDL_PollEvent returned 0 (no event)
        je .show_menu # if no event loop again

        # check if the event type is SDL_QUIT
        cmpl $0x100, -152(%rbp)
        je .quit_game

        # check if the event type is SDL_EVENT_MOUSE_BUTTON_DOWN
        cmpl $0x401, -152(%rbp)
        jne .show_menu

        # the button value is stored with a 24 byte offset from the SDL_Event address
        cmpb $1, -128(%rbp) # if the left mouse button was pressed
        jne .show_menu

        # test which menu button was clicked
        # the x value is stored with a 28 byte offset from the SDL_Event address
        cvttss2si -124(%rbp), %eax
        # the y value is stored with a 32 byte offset from the SDL_Event address
        cvttss2si -120(%rbp), %ecx

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
        
        # test for play
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
            movq -8(%rbp), %rdi
            call SDL_RenderPresent
            jmp .menu_loop

        jmp .menu_loop
    
    .menu_loop_end:
        addq $160, %rsp # deallocate stack space
        movq %rbp, %rsp
        popq %rbp
        ret
