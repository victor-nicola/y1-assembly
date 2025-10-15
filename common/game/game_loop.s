# this directive ensures the stack is not executable for security reasons (i get an error on fedora 42 if i don't have this)
.section .note.GNU-stack,"",@progbits

.section .data
.equ SPRITE_SIZE, 100
sprite_x: .float 100.0
sprite_y: .float 100.0
speed: .float 10.0

.section .text
.global game_loop
.global render_scene

render_scene:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    # 16 for the sprite props (-16 to -1)

    # draw frame
    # draw background
    # SDL_SetRenderDrawColor(renderer, 0, 100, 255, 255);
    movq game_ren(%rip), %rdi
    movl $0, %esi
    movl $100, %edx
    movl $255, %ecx
    movl $255, %r8d
    call SDL_SetRenderDrawColor

    # SDL_RenderClear(renderer);
    movq game_ren(%rip), %rdi
    call SDL_RenderClear

    # draw sprite
    # SDL_SetRenderDrawColor(renderer, 255, 100, 0, 255);
    movq game_ren(%rip), %rdi
    movl $255, %esi
    movl $0, %edx
    movl $0, %ecx
    movl $255, %r8d
    call SDL_SetRenderDrawColor

    movss sprite_x(%rip), %xmm0
    movss %xmm0, -16(%rbp) # x
    movss sprite_y(%rip), %xmm0
    movss %xmm0, -12(%rbp) # y

    movl $SPRITE_SIZE, %eax
    # convert integer to float
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -8(%rbp) # w
    
    movl $SPRITE_SIZE, %eax
    # convert integer to float
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -4(%rbp) # h

    movq game_ren(%rip), %rdi
    leaq -16(%rbp), %rsi
    call SDL_RenderFillRect

    addq $16, %rsp
    movq $0, %rax # success
    movq %rbp, %rsp
    popq %rbp
    ret

game_loop:
    pushq %rbp
    movq %rsp, %rbp

    subq $144, %rsp
    # 128 for the SDL_Event union (-128 to -1)

    .main_loop:
        # firstly we draw the frame and after that we process the input
        movq game_ren(%rip), %rdi
        call render_scene

        # process input
        leaq -128(%rbp), %rdi # place to put the SDL_Event
        call SDL_PollEvent
        cmpl $0, %eax # check if SDL_PollEvent returned 0 (no event)
        je .render_frame # if no event loop again

        # check if the event type is SDL_QUIT
        cmpl $0x100, -128(%rbp)
        je .main_loop_end

        # check if the event type is SDL_EVENT_KEY_DOWN
        cmpl $0x300, -128(%rbp)
        je .test_key
        
        # check if the event type is SDL_EVENT_MOUSE_BUTTON_DOWN
        cmpl $0x401, -128(%rbp)
        jne .render_frame

        # the button value is stored with a 24 byte offset from the SDL_Event address
        cmpb $1, -104(%rbp) # if the left mouse button was pressed
        jne .render_frame
        
        # the x value is stored with a 28 byte offset from the SDL_Event address
        movss -100(%rbp), %xmm0
        movss %xmm0, sprite_x(%rip) # update x
        # the y value is stored with a 32 byte offset from the SDL_Event address
        movss -96(%rbp), %xmm0
        movss %xmm0, sprite_y(%rip) # update y
        jmp .render_frame

        .test_key:
            # the key value is stored with a 28 byte offset from the SDL_Event address
            movl -100(%rbp), %eax # get key code
            cmpl $0x40000052, %eax # if up arrow was pressed
            je .move_sprite_up

            cmpl $0x40000051, %eax # if down arrow was pressed
            je .move_sprite_down

            cmpl $0x40000050, %eax # if left arrow was pressed
            je .move_sprite_left

            cmpl $0x4000004f, %eax # if right arrow was pressed
            je .move_sprite_right

            cmpl $0x00000070, %eax # if p arrow was pressed
            jne .render_frame

            call render_menu

            cmpq $-1, %rax # if we need to quit the game
            je .main_loop_end

            jmp .render_frame

        .move_sprite_up:
            movss sprite_y(%rip), %xmm0
            subss speed(%rip), %xmm0
            movss %xmm0, sprite_y(%rip)
            jmp .render_frame

        .move_sprite_down:
            movss speed(%rip), %xmm0
            addss sprite_y(%rip), %xmm0
            movss %xmm0, sprite_y(%rip)
            jmp .render_frame
        
        .move_sprite_left:
            movss sprite_x(%rip), %xmm0
            subss speed(%rip), %xmm0
            movss %xmm0, sprite_x(%rip)
            jmp .render_frame
        
        .move_sprite_right:
            movss speed(%rip), %xmm0
            addss sprite_x(%rip), %xmm0
            movss %xmm0, sprite_x(%rip)
            jmp .render_frame
        
        .render_frame:
            # SDL_RenderPresent(renderer);
            movq game_ren(%rip), %rdi
            call SDL_RenderPresent
            jmp .main_loop

        jmp .main_loop

    .main_loop_end:
        # the user closed the window
        addq $144, %rsp # deallocate stack space
        movq $0, %rax # success
        movq %rbp, %rsp
        popq %rbp
        ret
