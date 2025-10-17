# this directive ensures the stack is not executable for security reasons (i get an error on fedora 42 if i don't have this)
.section .note.GNU-stack,"",@progbits

.section .data
.equ TILE_GRASS, 0
.equ TILE_PATH, 1
.equ TILE_OTTO, 2
.equ TILE_ARASH, 3
.equ TILE_VICTOR, 4
.equ TILE_STEFAN, 5
.equ TILE_BASE, 6

.equ GRID_COLS, 16
.equ GRID_ROWS, 9
.equ MAP_SIZE, (GRID_COLS * GRID_ROWS)
tile_height: .long 0
tile_width: .long 0
MAP_GRID:
    .byte TILE_GRASS, TILE_GRASS, TILE_PATH,  TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS
    .byte TILE_GRASS, TILE_GRASS, TILE_PATH,  TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS
    .byte TILE_GRASS, TILE_GRASS, TILE_PATH,  TILE_PATH,  TILE_PATH,  TILE_PATH,  TILE_PATH,  TILE_PATH,  TILE_PATH,  TILE_PATH,  TILE_PATH,  TILE_PATH,  TILE_PATH,  TILE_PATH,  TILE_GRASS, TILE_GRASS
    .byte TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_PATH,  TILE_GRASS, TILE_GRASS
    .byte TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_PATH,  TILE_GRASS, TILE_GRASS
    .byte TILE_GRASS, TILE_GRASS, TILE_PATH,  TILE_PATH,  TILE_PATH,  TILE_PATH,  TILE_PATH,  TILE_PATH,  TILE_PATH,  TILE_PATH,  TILE_PATH,  TILE_PATH,  TILE_PATH,  TILE_PATH,  TILE_GRASS, TILE_GRASS
    .byte TILE_GRASS, TILE_GRASS, TILE_PATH,  TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS
    .byte TILE_GRASS, TILE_GRASS, TILE_PATH,  TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS
    .byte TILE_GRASS, TILE_GRASS, TILE_BASE,  TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS

grass_tile: .quad 0
path_tile: .quad 0
base_tile: .quad 0

base_w: .long 0
base_h: .long 0

base_w_percentage: .long 150
base_h_percentage: .long 150

.section .text
.global game_loop
.global render_scene

render_scene:
    pushq %rbp
    movq %rsp, %rbp
    
    # save callee-saved registries
    pushq %r12
    pushq %r13
    
    subq $32, %rsp
    # 16 for the sprite props (-16 to -1)
    # 8 for the base pos (-24 to -17)
    # 1 for flag parameter (-25)
    movb %dil, -25(%rbp)

    # draw frame
    # SDL_RenderClear(renderer);
    movq game_ren(%rip), %rdi
    call SDL_RenderClear

    movslq tile_width(%rip), %rax
    cvtsi2ss %rax, %xmm0
    movss %xmm0, -8(%rbp) # w
    
    movslq tile_height(%rip), %rax
    cvtsi2ss %rax, %xmm0
    movss %xmm0, -4(%rbp) # h

    movq $0, %r12 # row
    movl $0, -12(%rbp) # y
    .row_loop:
        movq $0, %r13 # col
        movl $0, -16(%rbp) # x
        .col_loop:
            # get tile value
            movq $GRID_COLS, %rax
            mulq %r12
            addq %r13, %rax
            leaq MAP_GRID(%rip), %rdi
            movb (%rdi, %rax, 1), %al

            cmpb $TILE_PATH, %al
            je draw_path

            cmpb $TILE_GRASS, %al
            je draw_grass

            cmpb $TILE_BASE, %al
            je draw_base

            draw_base:
                movq game_ren(%rip), %rdi
                movq grass_tile(%rip), %rsi
                movq $0, %rdx # we want all of the tile to be rendered
                leaq -16(%rbp), %rcx # where we want to render it
                call SDL_RenderTexture
                
                # save base position
                movl -16(%rbp), %eax
                movl %eax, -24(%rbp)

                movl -12(%rbp), %eax
                movl %eax, -20(%rbp)
                jmp render_texture

            draw_grass:
                movq grass_tile(%rip), %rsi
                jmp render_texture
            
            draw_path:
                movq path_tile(%rip), %rsi
                jmp render_texture
            
            render_texture:
                movq game_ren(%rip), %rdi
                movq $0, %rdx # we want all of the tile to be rendered
                leaq -16(%rbp), %rcx # where we want to render it
                call SDL_RenderTexture

            incq %r13 # update column
            movss -8(%rbp), %xmm0 # update x
            movss -16(%rbp), %xmm1
            addss %xmm1, %xmm0
            movss %xmm0, -16(%rbp)

            cmpb $GRID_COLS, %r13b
            jl .col_loop

        incq %r12 # update row
        movss -4(%rbp), %xmm0 # update y
        movss -12(%rbp), %xmm1
        addss %xmm1, %xmm0
        movss %xmm0, -12(%rbp)

        cmpb $GRID_ROWS, %r12b
        jl .row_loop

    cmpb $1, -25(%rbp)
    je .draw_plus_row

    cmpb $2, -25(%rbp)
    je .draw_plus_col

    cmpb $3, -25(%rbp)
    je .draw_plus_row

    jmp .render_base_tile

    .draw_plus_row:
        movq $0, %r13 # col
        movq $(GRID_ROWS * GRID_COLS), %rax
        movq $0, %rdx
        mull tile_height(%rip)
        cvtsi2ss %rax, %xmm0
        movss %xmm0, -12(%rbp) # y
        movl $0, -16(%rbp) # x
        movslq tile_width(%rip), %rax # w
        cvtsi2ss %rax, %xmm0
        movss %xmm0, -8(%rbp)
        movslq tile_height(%rip), %rax # h
        cvtsi2ss %rax, %xmm0
        movss %xmm0, -4(%rbp)

        .draw_plus_row_loop:
            movq game_ren(%rip), %rdi
            movq grass_tile(%rip), %rsi
            movq $0, %rdx # we want all of the tile to be rendered
            leaq -16(%rbp), %rcx # where we want to render it
            call SDL_RenderTexture

            incq %r13 # update column
            movslq tile_width(%rip), %rax # update x
            cvtsi2ss %rax, %xmm0
            movss -16(%rbp), %xmm1
            addss %xmm1, %xmm0
            movss %xmm0, -16(%rbp)

            cmpb $GRID_COLS, %r13b
            jl .draw_plus_row_loop
        
        cmpb $3, -25(%rbp)
        jne .render_base_tile
    
    .draw_plus_col:
        movq $0, %r12 # row
        movl $0, -12(%rbp) # y
        movl $GRID_COLS, %eax # x
        movq $0, %rdx
        mull tile_width(%rip)
        movl %eax, -16(%rbp)
        movslq tile_width(%rip), %rax # w
        cvtsi2ss %rax, %xmm0
        movss %xmm0, -8(%rbp)
        movslq tile_height(%rip), %rax # h
        cvtsi2ss %rax, %xmm0
        movss %xmm0, -4(%rbp)

        .draw_plus_col_loop:
            movq game_ren(%rip), %rdi
            movq grass_tile(%rip), %rsi
            movq $0, %rdx # we want all of the tile to be rendered
            leaq -16(%rbp), %rcx # where we want to render it
            call SDL_RenderTexture

            incq %r12 # update row
            movslq tile_height(%rip), %rax # update y
            cvtsi2ss %rax, %xmm0
            movss -12(%rbp), %xmm1
            addss %xmm1, %xmm0
            movss %xmm0, -12(%rbp)

            cmpb $GRID_ROWS, %r12b
            jl .draw_plus_col_loop

    .render_base_tile:
        # get base position
        movss -24(%rbp), %xmm0
        movss %xmm0, -16(%rbp)
        movl base_w(%rip), %eax
        shrl $2, %eax
        cvtsi2ss %eax, %xmm1
        movss -16(%rbp), %xmm2
        subss %xmm1, %xmm2
        movss %xmm2, -16(%rbp)

        movl tile_height(%rip), %eax
        cvtsi2ss %eax, %xmm0
        movss -20(%rbp), %xmm1
        addss %xmm1, %xmm0
        movl base_h(%rip), %eax
        cvtsi2ss %eax, %xmm2
        subss %xmm2, %xmm0
        movss %xmm0, -12(%rbp)

        movslq base_w(%rip), %rax
        cvtsi2ss %rax, %xmm0
        movss %xmm0, -8(%rbp) # w
        
        movslq base_h(%rip), %rax
        cvtsi2ss %rax, %xmm0
        movss %xmm0, -4(%rbp) # h

        movq game_ren(%rip), %rdi
        movq base_tile(%rip), %rsi
        movq $0, %rdx # we want all of the tile to be rendered
        leaq -16(%rbp), %rcx # where we want to render it
        call SDL_RenderTexture

    addq $32, %rsp
    
    # restore callee-saved registries
    popq %r13
    popq %r12
    
    movq $0, %rax # success
    movq %rbp, %rsp
    popq %rbp
    ret

game_loop:
    pushq %rbp
    movq %rsp, %rbp

    subq $128, %rsp
    # 128 for the SDL_Event union (-128 to -1)
    pushq %r15
    subq $8, %rsp

    # calculate tile width
    movq $0, %r15

    movq $0, %rdx
    movslq window_width(%rip), %rax
    movq $GRID_COLS, %r8
    divq %r8
    movl %eax, tile_width(%rip)
    cmpq $0, %rdx
    jne .inc_w
    
    .inc_w:
        addq $2, %r15

    # calculate tile height
    movq $0, %rdx
    movslq window_height(%rip), %rax
    movq $GRID_ROWS, %r8
    divq %r8
    movl %eax, tile_height(%rip)
    cmpq $0, %rdx
    jne .inc_h

    .inc_h:
        addq $1, %r15
    
    # load the grass tile
    leaq grass_tile_path(%rip), %rdi
    call SDL_LoadBMP
    movq %rax, grass_tile(%rip)
    movq %rax, %rbx # save surface to destroy later
    
    movq game_ren(%rip), %rdi
    movq grass_tile(%rip), %rsi
    call SDL_CreateTextureFromSurface
    movq %rax, grass_tile(%rip)

    movq grass_tile(%rip), %rdi
    movl $0, %esi
    call SDL_SetTextureScaleMode

    movq %rbx, %rdi
    call SDL_DestroySurface

    # load the path tile
    leaq path_tile_path(%rip), %rdi
    call SDL_LoadBMP
    movq %rax, path_tile(%rip)
    movq %rax, %rbx # save surface to destroy later

    movq game_ren(%rip), %rdi
    movq path_tile(%rip), %rsi
    call SDL_CreateTextureFromSurface
    movq %rax, path_tile(%rip)

    movq path_tile(%rip), %rdi
    movl $0, %esi
    call SDL_SetTextureScaleMode

    movq %rbx, %rdi
    call SDL_DestroySurface

    # load the base tile
    leaq base_tile_path(%rip), %rdi
    call SDL_LoadBMP
    movq %rax, base_tile(%rip)
    movq %rax, %rbx # save surface to destroy later

    movq %rbx, %rdi
    movl $1, %esi
    movl $0x00000000, %edx
    call SDL_SetSurfaceColorKey

    movq game_ren(%rip), %rdi
    movq base_tile(%rip), %rsi
    call SDL_CreateTextureFromSurface
    movq %rax, base_tile(%rip)

    movq base_tile(%rip), %rdi
    movl $0, %esi
    call SDL_SetTextureScaleMode

    movq %rbx, %rdi
    call SDL_DestroySurface

    # calculate base width
    movl tile_width(%rip), %eax
    mull base_w_percentage(%rip)

    movl $0, %edx
    movl $100, %ecx
    idivl %ecx
    movl %eax, base_w(%rip)

    # calculate base height
    movl tile_height(%rip), %eax
    mull base_h_percentage(%rip)

    movl $0, %edx
    movl $100, %ecx
    divl %ecx
    movl %eax, base_h(%rip)

    .main_loop:
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

        .test_key:
            # the key value is stored with a 28 byte offset from the SDL_Event address
            movl -100(%rbp), %eax # get key code

            cmpl $0x0000001b, %eax # if esc key was pressed
            jne .render_frame

            call render_menu

            cmpq $-1, %rax # if we need to quit the game
            je .main_loop_end

            jmp .render_frame

        .render_frame:
            movq %r15, %rdi
            call render_scene
            # SDL_RenderPresent(renderer);
            movq game_ren(%rip), %rdi
            call SDL_RenderPresent
            jmp .main_loop

        jmp .main_loop

    .main_loop_end:
        # the user closed the window
        addq $8, %rsp
        popq %r15
        addq $128, %rsp # deallocate stack space
        movq $0, %rax # success
        movq %rbp, %rsp
        popq %rbp
        ret
