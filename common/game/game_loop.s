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
.equ TILE_BLOCKED, 7

.equ GRID_COLS, 16
.equ GRID_ROWS, 9
.equ MAP_SIZE, (GRID_COLS * GRID_ROWS)
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

.equ TOWER_Y_CENTER_BMP, 32
.equ TOWER_X_CENTER_BMP, 16

tiles: .quad 0
       .quad 0
       .quad 0
       .quad 0
       .quad 0
       .quad 0
       .quad 0

tile_width: .long 0
tile_height: .long 0

tower_h: .long 0

base_w: .long 0
base_h: .long 0

base_w_percentage: .long 150
base_h_percentage: .long 150

cursor_surface: .long 0
cursor: .long 0

.section .text
.global game_loop
.global render_scene

render_scene:
    pushq %rbp
    movq %rsp, %rbp
    
    # save callee-saved registries
    pushq %r12
    pushq %r13
    
    subq $48, %rsp
    # 16 for the sprite props (-16 to -1)
    # 8 for the base pos (-24 to -17)
    # 1 for flag parameter (-25)
    # 4 for tower height (-29 to -26)
    # 4 for aux height (-33 to -30)
    # 4 for aux y (-37 to -34)
    # 1 for tower code (-38)
    movb %dil, -25(%rbp)
    movl $0, -33(%rbp)
    movl $0, -37(%rbp)

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
    
    movslq tile_height(%rip), %rax
    cvtsi2ss %rax, %xmm1
    movq $2, %rax
    cvtsi2ss %rax, %xmm0
    mulss %xmm0, %xmm1
    movss %xmm1, -29(%rbp)

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
            movzbq (%rdi, %rax, 1), %rax
            movb %al, -38(%rbp)

            cmpb $TILE_BASE, %al
            je draw_base

            cmpb $TILE_OTTO, %al
            jl continue_testing

            cmpb $TILE_STEFAN, %al
            jle draw_tower

            continue_testing:
                cmpb $TILE_BLOCKED, %al
                je draw_blocked

                movq tiles(, %rax, 8), %rsi
                jmp render_texture
            
            draw_blocked:
                movq tiles + (8 * TILE_GRASS)(%rip), %rsi
                jmp render_texture

            draw_tower:
                movq game_ren(%rip), %rdi
                movq tiles + (8 * TILE_GRASS)(%rip), %rsi
                movq $0, %rdx # we want all of the tile to be rendered
                leaq -16(%rbp), %rcx # where we want to render it
                call SDL_RenderTexture

                movss -12(%rbp), %xmm0
                movss %xmm0, -37(%rbp)
                movss -4(%rbp), %xmm1
                subss %xmm1, %xmm0
                movss %xmm0, -12(%rbp)

                movss -4(%rbp), %xmm0
                movss %xmm0, -33(%rbp)

                movss -29(%rbp), %xmm0
                movss %xmm0, -4(%rbp)
                
                movzbq -38(%rbp), %rax
                movq tiles(, %rax, 8), %rsi
                jmp render_texture

            draw_base:
                # save base position
                movl -16(%rbp), %eax
                movl %eax, -24(%rbp)

                movl -12(%rbp), %eax
                movl %eax, -20(%rbp)

                movq tiles + (8 * TILE_GRASS)(%rip), %rsi
                jmp render_texture
            
            render_texture:
                movq game_ren(%rip), %rdi
                movq $0, %rdx # we want all of the tile to be rendered
                leaq -16(%rbp), %rcx # where we want to render it
                call SDL_RenderTexture
                
                cmpl $0, -33(%rbp)
                je next_col

                movss -33(%rbp), %xmm0
                movss %xmm0, -4(%rbp)

                movss -37(%rbp), %xmm0
                movss %xmm0, -12(%rbp)

                movl $0, -33(%rbp)
                movl $0, -37(%rbp)

            next_col:
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
        movl $GRID_ROWS, %eax
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
            movq tiles + (8 * TILE_GRASS)(%rip), %rsi
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
            movq tiles + (8 * TILE_GRASS)(%rip), %rsi
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
        movq tiles + (8 * TILE_BASE)(%rip), %rsi
        movq $0, %rdx # we want all of the tile to be rendered
        leaq -16(%rbp), %rcx # where we want to render it
        call SDL_RenderTexture

    addq $48, %rsp
    
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

    subq $136, %rsp
    # 128 for the SDL_Event union (-128 to -1)
    # 1 for is placing tower flag (-129)
    pushq %r14
    pushq %r15
    pushq %rbx

    movq $-1, -129(%rbp)

    # calculate tile width
    movq $0, %r15

    movq $0, %rdx
    movslq window_width(%rip), %rax
    movq $GRID_COLS, %r8
    divq %r8
    movl %eax, tile_width(%rip)
    cmpq $0, %rdx
    jne .inc_w

    jmp .calc_tile_height

    .inc_w:
        addq $2, %r15

    .calc_tile_height:
        # calculate tile height
        movq $0, %rdx
        movslq window_height(%rip), %rax
        movq $GRID_ROWS, %r8
        divq %r8
        movl %eax, tile_height(%rip)
        cmpq $0, %rdx
        jne .inc_h

        jmp .load_tiles_loop_init

        .inc_h:
            addq $1, %r15
    
    .load_tiles_loop_init:
        movq $0, %r14
    load_tiles_loop:
        # load the base tile
        movq tiles_paths(, %r14, 8), %rdi
        call SDL_LoadBMP
        movq %rax, tiles(, %r14, 8)
        movq %rax, %rbx # save surface to destroy later

        cmp $0, %rax
        je .game_loop_cleanup

        movq %rbx, %rdi
        movl $1, %esi
        movl $0x00000000, %edx
        call SDL_SetSurfaceColorKey

        movq game_ren(%rip), %rdi
        movq tiles(, %r14, 8), %rsi
        call SDL_CreateTextureFromSurface
        movq %rax, tiles(, %r14, 8)

        cmp $0, %rax
        je .game_loop_cleanup

        movq tiles(, %r14, 8), %rdi
        movl $0, %esi
        call SDL_SetTextureScaleMode

        movq %rbx, %rdi
        call SDL_DestroySurface

        incq %r14
        cmpq $7, %r14
        jl load_tiles_loop

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
        je .game_loop_cleanup

        # check if the event type is SDL_EVENT_KEY_DOWN
        cmpl $0x300, -128(%rbp)
        je .test_key
        
        # check if the event type is SDL_EVENT_MOUSE_BUTTON_DOWN
        cmpl $0x401, -128(%rbp)
        jne .render_frame

        # the button value is stored with a 24 byte offset from the SDL_Event address
        cmpb $1, -104(%rbp) # if the left mouse button was pressed
        jne .render_frame

        cmpb $-1, -129(%rbp)
        je .render_frame

        jmp .place_tower

        .test_key:
            # the key value is stored with a 28 byte offset from the SDL_Event address
            movl -100(%rbp), %eax # get key code

            cmpl $0x0000006f, %eax # if o key was pressed
            je .place_otto_init

            cmpl $0x00000061, %eax # if a key was pressed
            je .place_arash_init

            cmpl $0x00000076, %eax # if v key was pressed
            je .place_victor_init

            cmpl $0x00000073, %eax # if s key was pressed
            je .place_stefan_init

            cmpl $0x0000001b, %eax # if esc key was pressed
            jne .render_frame

            cmpb $-1, -129(%rbp)
            jne .reset_place_tower

            movq %r15, %rdi
            call render_menu

            cmpq $-1, %rax # if we need to quit the game
            je .game_loop_cleanup

            jmp .render_frame

        .place_otto_init:
            movq $TILE_OTTO, %rax
            jmp .place_tower_init
        
        .place_arash_init:
            movq $TILE_ARASH, %rax
            jmp .place_tower_init

        .place_victor_init:
            movq $TILE_VICTOR, %rax
            jmp .place_tower_init

        .place_stefan_init:
            movq $TILE_STEFAN, %rax
            jmp .place_tower_init

        .place_tower_init:
            subq $2, %rax # adjust index for cursor array
            movb %al, -129(%rbp)
            movq cursors_paths(, %rax, 8), %rdi
            call SDL_LoadBMP
            movq %rax, %rbx

            cmpq $0, %rax
            je .reset_place_tower

            movq %rbx, %rdi
            movl $1, %esi
            movl $0x00000000, %edx
            call SDL_SetSurfaceColorKey

            movq %rbx, %rdi
            movl $TOWER_X_CENTER_BMP, %esi
            movl $TOWER_Y_CENTER_BMP, %edx
            call SDL_CreateColorCursor
            movq %rax, cursor(%rip)

            cmpq $0, %rax
            je .reset_place_tower

            movq cursor(%rip), %rdi
            call SDL_SetCursor

            movq %rbx, %rdi
            call SDL_DestroySurface
            jmp .render_frame
        
        .place_tower:
            # the x value is stored with a 28 byte offset from the SDL_Event address
            cvttss2si -100(%rbp), %eax
            # the y value is stored with a 32 byte offset from the SDL_Event address
            cvttss2si -96(%rbp), %ecx
            movl tile_width(%rip), %r8d
            movl $0, %edx
            idivl %r8d
            movl %eax, %r9d
            
            cmpl $GRID_COLS, %r9d
            jge .render_frame

            movl tile_height(%rip), %r8d
            movl %ecx, %eax
            movl $0, %edx
            idivl %r8d
            movl %eax, %ecx

            cmpl $GRID_ROWS, %ecx
            jge .render_frame

            cmpl $0, %ecx
            jle .render_frame

            movl %ecx, %eax
            movl $GRID_COLS, %r8d
            imull %r8d, %eax            
            addl %r9d, %eax

            # both the clicked tile and the one above it must be grass
            movslq %eax, %rax
            leaq MAP_GRID(%rip), %rdi
            movb (%rdi, %rax, 1), %cl

            cmpb $TILE_GRASS, %cl
            jne .render_frame

            subq $GRID_COLS, %rax
            movb (%rdi, %rax, 1), %cl

            cmpb $TILE_GRASS, %cl
            jne .render_frame

            movb $TILE_BLOCKED, (%rdi, %rax, 1)

            addq $GRID_COLS, %rax
            movb -129(%rbp), %cl
            addb $2, %cl # adjust from cursor index to tile
            movb %cl, (%rdi, %rax, 1)

            jmp .reset_place_tower

        .reset_place_tower:
            call SDL_GetDefaultCursor
            movq %rax, cursor(%rip)
            movq %rax, %rdi
            call SDL_SetCursor
            movq $-1, -129(%rbp)
            jmp .render_frame
        
        .render_frame:
            movq %r15, %rdi
            call render_scene
            # SDL_RenderPresent(renderer);
            movq game_ren(%rip), %rdi
            call SDL_RenderPresent
            jmp .main_loop

        jmp .main_loop

    .game_loop_cleanup:
        # the user closed the window
        # cleanup
        movq $0, %r14
        cleanup_tiles_loop:
            movq tiles(, %r14, 8), %rdi
            cmpq $0, %rdi
            je .game_loop_end

            call SDL_DestroyTexture

            incq %r14
            cmpq $7, %r14
            jl cleanup_tiles_loop

        movq cursor(%rip), %rdi
	    call SDL_DestroyCursor

        jmp .game_loop_end

    .game_loop_end:
        popq %rbx
        popq %r15
        popq %r14
        addq $136, %rsp # deallocate stack space
        movq $0, %rax # success
        movq %rbp, %rsp
        popq %rbp
        ret
