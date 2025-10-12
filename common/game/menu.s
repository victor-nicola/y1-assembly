# this directive ensures the stack is not executable for security reasons (i get an error on fedora 42 if i don't have this)
.section .note.GNU-stack,"",@progbits

.section .data

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

    movq $0, %rax
    movq $debug_string, %rdi
    movl window_width(%rip), %esi
    movl window_height(%rip), %edx
    call printf

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

        # reset opacity blend
        # SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
        movq -8(%rbp), %rdi
        movq $0x00000000, %rsi
        call SDL_SetRenderDrawBlendMode

        # process input
        leaq -152(%rbp), %rdi # place to put the SDL_Event
        call SDL_PollEvent
        cmpl $0, %eax # check if SDL_PollEvent returned 0 (no event)
        je .render_menu # if no event loop again

        # check if the event type is SDL_QUIT
        cmpl $0x100, -152(%rbp)
        je .menu_loop_end

        # check if the event type is SDL_EVENT_KEY_DOWN
        cmpl $0x300, -152(%rbp)
        jne .render_menu

        # the key value is stored with a 28 byte offset from the SDL_Event address
        movl -124(%rbp), %eax # get key code
        cmpl $0x1b, %eax # if escape was pressed quit
        je .menu_loop_end

        .render_menu:
            # SDL_RenderPresent(renderer);
            movq -8(%rbp), %rdi
            call SDL_RenderPresent
            jmp .menu_loop

        jmp .menu_loop
    
    .menu_loop_end:
        addq $160, %rsp # deallocate stack space
        movq $0, %rax # success
        movq %rbp, %rsp
        popq %rbp
        ret
