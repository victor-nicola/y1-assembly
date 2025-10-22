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
font_path: .asciz "../assets/fonts/PixelatedEleganceRegular-ovyAA.ttf"
font_size_percentage: .float 0.02
font_size: .float 20
grass_tile_path: .asciz "../assets/map-tiles/grass.bmp"
path_tile_path: .asciz "../assets/map-tiles/path.bmp"
base_tile_path: .asciz "../assets/towers/eemcs.bmp"
otto_tower_path: .asciz "../assets/towers/otto.bmp"
arash_tower_path: .asciz "../assets/towers/arash.bmp"
stefan_tower_path: .asciz "../assets/towers/stefan.bmp"
victor_tower_path: .asciz "../assets/towers/victor.bmp"

tiles_paths: .quad grass_tile_path
             .quad path_tile_path
             .quad otto_tower_path
             .quad arash_tower_path
             .quad victor_tower_path
             .quad stefan_tower_path
             .quad base_tile_path

eugenia_path: .asciz "../assets/eugenia.bmp"
play_button_path: .asciz "../assets/menu-buttons/play.bmp"
quit_button_path: .asciz "../assets/menu-buttons/exit.bmp"
menu_path: .asciz "../assets/menu-buttons/menu.bmp"

otto_cursor_path: .asciz "../assets/cursors/otto.bmp"
arash_cursor_path: .asciz "../assets/cursors/arash.bmp"
victor_cursor_path: .asciz "../assets/cursors/victor.bmp"
stefan_cursor_path: .asciz "../assets/cursors/stefan.bmp"

cursors_paths: .quad otto_cursor_path
               .quad arash_cursor_path
               .quad victor_cursor_path
               .quad stefan_cursor_path

debug_string: .asciz "%d\n"
starter_string: .asciz ""
window_width:  .long 0
window_height: .long 0

.global window_width
.global window_height
.global debug_string
.global tiles_paths
.global cursors_paths
.global eugenia_path
.global play_button_path
.global quit_button_path
.global menu_path

.section .bss
.comm game_font, 8
.comm game_text, 8
.comm game_ren, 8
.comm game_win, 8
.comm game_surface, 8
.comm game_texture, 8

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
    jne get_window_size # if success, jump to get window size

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

get_window_size:
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

    # calculate font size based on window width
    movl window_width(%rip), %eax
    cvtsi2ssl %eax, %xmm0
    movss font_size_percentage(%rip), %xmm1
    mulss %xmm1, %xmm0
    movss %xmm0, font_size(%rip)

    cmp $0, %rax
    jne init_ttf # if success, jump to TTF init

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
    movss font_size(%rip), %xmm0
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
    leaq starter_string(%rip), %rdx
    movq $0, %rcx
    call TTF_CreateText
    movq %rax, game_text(%rip)

    cmpl $0, %eax
    jne call_game_loop

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

call_game_loop:
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
