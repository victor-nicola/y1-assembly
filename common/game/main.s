.section .note.GNU-stack,"",@progbits

.section .data
init_error: .asciz "SDL_Init Error: %s\n"
create_window_error: .asciz "SDL_CreateWindow Error: %s\n"
create_renderer_error: .asciz "SDL_CreateRenderer Error: %s\n"
ttf_init_error: .asciz "TTF_Init Error: %s\n"
ttf_open_font_error: .asciz "TTF_OpenFont Error: %s\n"
ttf_create_text_engine: .asciz "TTF_CreateRendererTextEngine Error: %s\n"
ttf_create_text: .asciz "TTF_CreateText Error: %s\n"
window_title: .asciz "Assembly Game!"
font_path: .asciz "./assets/fonts/PixelatedEleganceRegular-ovyAA.ttf"
font_size: .long 20

debug_string: .asciz "test\n"
starter_string: .asciz ""
window_width:  .long 0
window_height: .long 0

.global window_width
.global window_height
.global debug_string

.section .bss
.comm game_font, 8
.comm game_text, 8
.comm game_ren, 8
.comm game_win, 8

.section .text
.global main

main:
    pushq %rbp
    movq %rsp, %rbp

    # allocate space for SDL_Event, text engine
    subq $144, %rsp
    # 128 for SDL_Event (-128 to -1)
    # 8 for text engine (-136 to -129)

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
    movq %rax, game_win(%rip)

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
    movq game_win(%rip), %rdi
    movl $0, %esi
    movl $0x6, %edx # flags (0x6 = ACCELERATED | PRESENTVSYNC)
    
    call SDL_CreateRenderer
    movq %rax, game_ren(%rip) # save renderer pointer

    # check for error (NULL is error)
    cmpq $0, %rax
    jne init_ttf # if success, jump to TTF init

    # SDL_DestroyWindow(win);
    movq game_win(%rip), %rdi
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

init_ttf:
    call TTF_Init

    cmpl $0, %eax
    jne make_text_engine

    call SDL_GetError
    movq %rax, %rsi
    leaq ttf_init_error(%rip), %rdi
    movl $0, %eax
    call printf
    
    # SDL_DestroyRenderer(ren);
    movq game_ren(%rip), %rdi
    call SDL_DestroyRenderer

    # SDL_DestroyWindow(win);
    movq game_win(%rip), %rdi
    call SDL_DestroyWindow

    call SDL_Quit

    # return 1 on error
    movl $1, %eax
    jmp cleanup_exit

make_text_engine:
    movq game_ren(%rip), %rdi
    call TTF_CreateRendererTextEngine
    movq %rax, -136(%rbp)

    cmpl $0, %eax
    jne load_font

    call SDL_GetError
    movq %rax, %rsi
    leaq ttf_create_text_engine(%rip), %rdi
    movl $0, %eax
    call printf

    # SDL_DestroyRenderer(ren);
    movq game_ren(%rip), %rdi
    call SDL_DestroyRenderer

    # SDL_DestroyWindow(win);
    movq game_win(%rip), %rdi
    call SDL_DestroyWindow

    call SDL_Quit

    # return 1 on error
    movl $1, %eax
    jmp cleanup_exit

load_font:
    leaq font_path(%rip), %rdi
    movl font_size(%rip), %eax
    # convert integer to float
    cvtsi2ss %eax, %xmm0
    call TTF_OpenFont
    movq %rax, game_font(%rip)

    cmpq $0, %rax
    jne make_text

    call SDL_GetError
    movq %rax, %rsi
    leaq ttf_open_font_error(%rip), %rdi
    movl $0, %eax
    call printf

    movq -136(%rbp), %rdi
    call TTF_DestroySurfaceTextEngine

    # SDL_DestroyRenderer(ren);
    movq game_ren(%rip), %rdi
    call SDL_DestroyRenderer

    # SDL_DestroyWindow(win);
    movq game_win(%rip), %rdi
    call SDL_DestroyWindow

    call TTF_Quit
    call SDL_Quit

    # return 1 on error
    movl $1, %eax
    jmp cleanup_exit

make_text:
    movq -136(%rbp), %rdi
    movq game_font(%rip), %rsi
    movq starter_string(%rip), %rdx
    movq $0, %rcx
    call TTF_CreateText
    movq %rax, game_text(%rip)

    cmpl $0, %eax
    jne call_game_loop_wait

    call SDL_GetError
    movq %rax, %rsi
    leaq ttf_create_text(%rip), %rdi
    movl $0, %eax
    call printf
    
    movq -136(%rbp), %rdi
    call TTF_DestroySurfaceTextEngine

    # SDL_DestroyRenderer(ren);
    movq game_ren(%rip), %rdi
    call SDL_DestroyRenderer

    # SDL_DestroyWindow(win);
    movq game_win(%rip), %rdi
    call SDL_DestroyWindow

    call SDL_Quit

    # return 1 on error
    movq $1, %rax
    jmp cleanup_exit

call_game_loop_wait:
    .wait_for_resize:
        leaq -128(%rbp), %rdi # place to put the SDL_Event
        call SDL_PollEvent
        cmpl $0, %eax # check if SDL_PollEvent returned 0 (no event)
        je .wait_for_resize # if no event loop again

        # check if the event type is SDL_EVENT_WINDOW_RESIZED
        cmpl $0x206, -128(%rbp)
        jne .wait_for_resize

    movq game_win(%rip), %rdi # window
    leaq window_width(%rip), %rsi
    leaq window_height(%rip), %rdx
    call SDL_GetWindowSizeInPixels

    call game_loop

cleanup:
    movq game_font(%rip), %rdi
    call TTF_CloseFont

    movq -136(%rbp), %rdi
    call TTF_DestroySurfaceTextEngine

    movq game_text(%rip), %rdi
    call TTF_DestroyText

    call TTF_Quit

    movq game_ren(%rip), %rdi
    call SDL_DestroyRenderer

    movq game_win(%rip), %rdi
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
