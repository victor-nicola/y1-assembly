# this directive ensures the stack is not executable for security reasons (i get an error on fedora 42 if i don't have this)
.section .note.GNU-stack,"",@progbits

.section .data
initError: .asciz "SDL_Init Error: %s\n"
createWindowError: .asciz "SDL_CreateWindow Error: %s\n"
createRendererError: .asciz "SDL_CreateRenderer Error: %s\n"
windowTitle: .asciz "Assembly Game!"

.section .text
.global main

main:
    pushq %rbp
    movq %rsp, %rbp

    # allocate space for win and ren
    subq $16, %rsp

    # 1st arg: SDL_INIT_VIDEO (0x20)
    movl $0x20, %edi
    call SDL_Init

    # check return value for error (0 is failure)
    cmpl $0, %eax
    jne create_window # if success, jump to creating window

    call SDL_GetError # get the error string address in %rax
    movq %rax, %rsi
    leaq initError(%rip), %rdi
    movl $0, %eax
    call printf
    
    # return 1 on error
    movl $1, %eax
    jmp cleanup_exit

create_window:
    # SDL_Window* win = SDL_CreateWindow("Assembly Game!", 640, 480, SDL_WINDOW_FULLSCREEN);
    
    movl $0, %eax
    leaq windowTitle(%rip), %rdi
    movl $640, %esi
    movl $480, %edx
    movl $0x1, %ecx
    
    # need to save the window pointer
    call SDL_CreateWindow
    movq %rax, -8(%rbp)

    # check for error (NULL is error)
    cmpq $0, %rax
    jne create_renderer
    
    call SDL_GetError # get the error string address in %rax
    movq %rax, %rsi
    leaq createWindowError(%rip), %rdi
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
    leaq createRendererError(%rip), %rdi
    movl $0, %eax
    call printf
    
    call SDL_Quit
    
    # return 1 on error
    movl $1, %eax
    jmp cleanup_exit

call_game_loop:
    movq -16(%rbp), %rdi
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
    # deallocate space for win and ren
    addq $16, %rsp
    
    movq %rbp, %rsp
    popq %rbp
    ret
