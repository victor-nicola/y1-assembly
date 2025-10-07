# this directive ensures the stack is not executable for security reasons (i get an error on fedora 42 if i don't have this)
.section .note.GNU-stack,"",@progbits

.section .text
.global game_loop

game_loop:
    pushq %rbp
    movq %rsp, %rbp
    subq $64, %rsp # allocate 64 bytes on the stack for the renderer pointer and SDL_Event union
    movq %rdi, -8(%rbp) # save the renderer pointer

    .main_loop:
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

        # SDL_RenderPresent(renderer);
        movq -8(%rbp), %rdi
        call SDL_RenderPresent

        leaq -64(%rbp), %rdi # place to put the SDL_Event
        call SDL_PollEvent
        cmpl $0, %eax # check if SDL_PollEvent returned 0 (no event)
        je .main_loop # if no event loop again

        # check if the event type is SDL_QUIT
        movl -64(%rbp), %eax
        cmpl $0x100, %eax
        je .main_loop_end

        # check if the event type is SDL_EVENT_KEY_DOWN
        cmpl $0x300, %eax
        jne .main_loop
        
        # the key value is stored with a 28 byte offset from the SDL_Event address
        movl -36(%rbp), %eax # get key code
        cmpl $0x1b, %eax # if escape was pressed quit
        jne .main_loop

    .main_loop_end:
        # the user closed the window
        addq $64, %rsp # deallocate stack space
        movq %rbp, %rsp
        popq %rbp
        ret
