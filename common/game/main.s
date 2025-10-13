# this directive ensures the stack is not executable for security reasons (i get an error on fedora 42 if i don't have this)
.section .note.GNU-stack,"",@progbits

.section .data
init_error: .asciz "SDL_Init Error: %s\n"
create_window_error: .asciz "SDL_CreateWindow Error: %s\n"
create_renderer_error: .asciz "SDL_CreateRenderer Error: %s\n"
window_title: .asciz "Assembly Game!"

debug_string: .asciz "test\n"
window_width:  .long 0
window_height: .long 0

.section .text
.global main
.global window_width
.global window_height
.global debug_string

main:
    pushq %rbp
    movq %rsp, %rbp

    # allocate space for win, ren, SDL_Event
    subq $144, %rsp
    # 8 for window (-8 to -1)
    # 8 for renderer (-16 to -9)
    # 128 for SDL_Event (-144 to -17)

    # 1st arg: SDL_INIT_VIDEO (0x20)
    movl $0x20, %edi
    call SDL_Init

    # check return value for error (0 is failure)
    cmpl $0, %eax
    jne create_window # if success, jump to creating window

    call SDL_GetError # get the error string address in %rax
    movq %rax, %rsi
    leaq init_error(%rip), %rdi
    movl $0, %eax
    call printf
    
    # return 1 on error
    movl $1, %eax
    jmp cleanup_exit

create_window:
    # SDL_Window* win = SDL_CreateWindow("some title", 0, 0, SDL_WINDOW_FULLSCREEN);
    
    movl $0, %eax
    leaq window_title(%rip), %rdi
    movl $0, %esi
    movl $0, %edx
    movl $0x1, %ecx
    
    # need to save the window pointer
    call SDL_CreateWindow
    movq %rax, -8(%rbp)

    # check for error (NULL is error)
    cmpq $0, %rax
    jne create_renderer
    
    call SDL_GetError # get the error string address in %rax
    movq %rax, %rsi
    leaq create_window_error(%rip), %rdi
    movl $0, %eax
    call printf
    
    call SDL_Quit

    # return 1 on error
    movl $1, %eax
    jmp cleanup_exit

create_renderer:
    # SDL_Renderer* ren = SDL_CreateRenderer(win, NULL);
    movq -8(%rbp), %rdi
    movl $0, %esi
    movl $0x6, %edx # flags (0x6 = ACCELERATED | PRESENTVSYNC)
    
    call SDL_CreateRenderer
    movq %rax, -16(%rbp) # save renderer pointer

    # check for error (NULL is error)
    cmpq $0, %rax
    jne call_game_loop # if success, jump to game loop

    # SDL_DestroyWindow(win);
    movq -8(%rbp), %rdi
    call SDL_DestroyWindow
    
    call SDL_GetError
    movq %rax, %rsi
    leaq create_renderer_error(%rip), %rdi
    movl $0, %eax
    call printf
    
    call SDL_Quit
    
    # return 1 on error
    movl $1, %eax
    jmp cleanup_exit

call_game_loop:

    .wait_for_resize:
        leaq -144(%rbp), %rdi # place to put the SDL_Event
        call SDL_PollEvent
        cmpl $0, %eax # check if SDL_PollEvent returned 0 (no event)
        je .wait_for_resize # if no event loop again

        # check if the event type is SDL_EVENT_WINDOW_RESIZED
        cmpl $0x206, -144(%rbp)
        jne .wait_for_resize

    movq -8(%rbp), %rdi # window
    leaq window_width(%rip), %rsi
    leaq window_height(%rip), %rdx
    call SDL_GetWindowSizeInPixels

    movq -16(%rbp), %rdi # renderer
    call game_loop

cleanup:
    movq -16(%rbp), %rdi
    call SDL_DestroyRenderer

    movq -8(%rbp), %rdi
    call SDL_DestroyWindow

    call SDL_Quit
    
    # return 0 (success)
    movl $0, %eax

cleanup_exit:
    # deallocate space
    addq $144, %rsp
    
    movq %rbp, %rsp
    popq %rbp
    ret
