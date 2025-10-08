# this directive ensures the stack is not executable for security reasons (i get an error on fedora 42 if i don't have this)
.section .note.GNU-stack,"",@progbits

.section .data
.equ SPRITE_SIZE, 0x42c80000 # 100.0
sprite_x: .float 100.0
sprite_y: .float 100.0
speed: .float 10.0

.section .text
.global game_loop

game_loop:
    pushq %rbp
    movq %rsp, %rbp
    subq $160, %rsp 
    # 8 for the renderer pointer (-8 to -16)
    # 16 for the sprite props (-16 to -32)
    # 128 for the SDL_Event union (-32 to -160)
    movq %rdi, -8(%rbp) # save the renderer pointer

    .main_loop:
        # firstly we draw the frame and after that we process the input

        # draw frame
        # draw background
        # SDL_SetRenderDrawColor(renderer, 0, 100, 255, 255);
        movq -8(%rbp), %rdi
        movl $0, %esi
        movl $100, %edx
        movl $255, %ecx
        movl $255, %r8d
        call SDL_SetRenderDrawColor

        # SDL_RenderClear(renderer);
        movq -8(%rbp), %rdi
        call SDL_RenderClear

        # draw sprite
        # SDL_SetRenderDrawColor(renderer, 255, 100, 0, 255);
        movq -8(%rbp), %rdi
        movl $255, %esi
        movl $0, %edx
        movl $0, %ecx
        movl $255, %r8d
        call SDL_SetRenderDrawColor

        movl sprite_x(%rip), %eax
        movl %eax, -32(%rbp)
        movl sprite_y(%rip), %eax
        movl %eax, -28(%rbp)
        movl $SPRITE_SIZE, -24(%rbp)
        movl $SPRITE_SIZE, -20(%rbp)

        movq -8(%rbp), %rdi
        leaq -32(%rbp), %rsi
        call SDL_RenderFillRect

        # SDL_RenderPresent(renderer);
        movq -8(%rbp), %rdi
        call SDL_RenderPresent

        # process input
        leaq -160(%rbp), %rdi # place to put the SDL_Event
        call SDL_PollEvent
        cmpl $0, %eax # check if SDL_PollEvent returned 0 (no event)
        je .main_loop # if no event loop again

        # check if the event type is SDL_QUIT
        cmpl $0x100, -160(%rbp)
        je .main_loop_end

        # check if the event type is SDL_EVENT_KEY_DOWN
        cmpl $0x300, -160(%rbp)
        je .test_key
        
        # check if the event type is SDL_EVENT_MOUSE_BUTTON_DOWN
        cmpl $0x401, -160(%rbp)
        jne .main_loop

        # the button value is stored with a 24 byte offset from the SDL_Event address
        cmpb $1, -136(%rbp) # if the left mouse button was pressed
        jne .main_loop
        
        # the x value is stored with a 28 byte offset from the SDL_Event address
        movss -132(%rbp), %xmm0
        movss %xmm0, sprite_x(%rip) # update x
        # the y value is stored with a 32 byte offset from the SDL_Event address
        movss -128(%rbp), %xmm0
        movss %xmm0, sprite_y(%rip) # update y

        .test_key:
            # the key value is stored with a 28 byte offset from the SDL_Event address
            movl -132(%rbp), %eax # get key code
            cmpl $0x1b, %eax # if escape was pressed quit
            je .main_loop_end

            cmpl $0x40000052, %eax # if up arrow was pressed
            je .move_sprite_up

            cmpl $0x40000051, %eax # if down arrow was pressed
            je .move_sprite_down

            cmpl $0x40000050, %eax # if left arrow was pressed
            je .move_sprite_left

            cmpl $0x4000004f, %eax # if right arrow was pressed
            je .move_sprite_right

            jmp .main_loop

        .move_sprite_up:
            movss sprite_y(%rip), %xmm0
            subss speed(%rip), %xmm0
            movss %xmm0, sprite_y(%rip)
            jmp .main_loop

        .move_sprite_down:
            movss speed(%rip), %xmm0
            addss sprite_y(%rip), %xmm0
            movss %xmm0, sprite_y(%rip)
            jmp .main_loop
        
        .move_sprite_left:
            movss sprite_x(%rip), %xmm0
            subss speed(%rip), %xmm0
            movss %xmm0, sprite_x(%rip)
            jmp .main_loop
        
        .move_sprite_right:
            movss speed(%rip), %xmm0
            addss sprite_x(%rip), %xmm0
            movss %xmm0, sprite_x(%rip)
            jmp .main_loop

        jmp .main_loop

    .main_loop_end:
        # the user closed the window
        addq $160, %rsp # deallocate stack space
        movq %rbp, %rsp
        popq %rbp
        ret
