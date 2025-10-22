# this directive ensures the stack is not executable for security reasons (i get an error on fedora 42 if i don't have this)
.section .note.GNU-stack,"",@progbits

.section .data
.equ TILE_GRASS, 0
.equ TILE_DOWN, 1
.equ TILE_OTTO, 2
.equ TILE_ARASH, 3
.equ TILE_VICTOR, 4
.equ TILE_STEFAN, 5
.equ TILE_BASE, 6
.equ TILE_BLOCKED, 7
.equ TILE_BLOCKED_ARASH, 8
.equ TILE_RIGHT, 11
.equ TILE_LEFT, 12
.equ TILE_STOP, 13

.equ GRID_COLS, 16
.equ GRID_ROWS, 9
.equ MAP_SIZE, (GRID_COLS * GRID_ROWS)
MAP_GRID:
    .byte TILE_GRASS, TILE_GRASS, TILE_DOWN,  TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS
    .byte TILE_GRASS, TILE_GRASS, TILE_DOWN,  TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS
    .byte TILE_GRASS, TILE_GRASS, TILE_RIGHT, TILE_RIGHT, TILE_RIGHT, TILE_RIGHT, TILE_RIGHT, TILE_RIGHT, TILE_RIGHT, TILE_RIGHT, TILE_RIGHT, TILE_RIGHT, TILE_RIGHT, TILE_DOWN,  TILE_GRASS, TILE_GRASS
    .byte TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_DOWN,  TILE_GRASS, TILE_GRASS
    .byte TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_DOWN,  TILE_GRASS, TILE_GRASS
    .byte TILE_GRASS, TILE_GRASS, TILE_DOWN,  TILE_LEFT,  TILE_LEFT,  TILE_LEFT,  TILE_LEFT,  TILE_LEFT,  TILE_LEFT,  TILE_LEFT,  TILE_LEFT,  TILE_LEFT,  TILE_LEFT,  TILE_LEFT,  TILE_GRASS, TILE_GRASS
    .byte TILE_GRASS, TILE_GRASS, TILE_DOWN,  TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS
    .byte TILE_GRASS, TILE_GRASS, TILE_STOP,  TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS
    .byte TILE_GRASS, TILE_GRASS, TILE_BASE,  TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS, TILE_GRASS

.equ TOWER_Y_CENTER_BMP, 32
.equ TOWER_X_CENTER_BMP, 16
.equ MAX_TOWERS, 50

tower_x: .space MAX_TOWERS
tower_y: .space MAX_TOWERS
towers_index: .byte 0

tiles: .quad 0
       .quad 0
       .quad 0
       .quad 0
       .quad 0
       .quad 0
       .quad 0

tile_width: .float 0
tile_height: .float 0

tower_h: .float 0

base_w: .float 0
base_h: .float 0

base_w_percentage: .float 1.5
base_h_percentage: .float 1.5

cursor_surface: .long 0
cursor: .long 0

mob_h: .float 0
mob_w: .float 0
mob_h_center: .float 0
mob_w_center: .float 0
mob_h_percentage: .float 0.75
mob_w_percentage: .float 0.75

coins: .long 0
coins_text_format: .asciz "Coins: %d"
coins_text: .space 16
coins_x: .float 0
coins_y: .float 0

.section .text
.global game_loop
.global render_scene
.global tile_width
.global tile_height
.global mob_h
.global mob_w
.global mob_h_center
.global mob_w_center
.global GRID_COLS
.global GRID_ROWS
.global MAP_GRID
.global TILE_STOP
.global TILE_LEFT
.global TILE_RIGHT
.global TILE_DOWN
.global tower_x
.global tower_y
.global towers_index

render_scene:
    pushq %rbp
    movq %rsp, %rbp
    
    # save callee-saved registries
    pushq %r12
    pushq %r13
    
    subq $48, %rsp
    # 16 for the sprite props (-16 to -1)
    # 8 for the base pos (-24 to -17)
    # 4 for tower height (-29 to -26)
    # 4 for aux height (-33 to -30)
    # 4 for aux y (-37 to -34)
    # 1 for tower code (-38)
    movl $0, -33(%rbp)
    movl $0, -37(%rbp)

    # draw frame
    # SDL_RenderClear(renderer);
    movq game_ren(%rip), %rdi
    call SDL_RenderClear

    movss tile_width(%rip), %xmm0
    movss %xmm0, -8(%rbp) # w
    
    movss tile_height(%rip), %xmm0
    movss %xmm0, -4(%rbp) # h
    
    movss tile_height(%rip), %xmm1
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

            cmpb $TILE_ARASH, %al
            je draw_arash

            cmpb $TILE_OTTO, %al
            jl continue_testing

            cmpb $TILE_STEFAN, %al
            jle draw_tower

            continue_testing:
                cmpb $TILE_BLOCKED, %al
                je draw_grass

                cmpb $TILE_BLOCKED_ARASH, %al
                je draw_path

                cmpb $TILE_LEFT, %al
                je draw_path

                cmpb $TILE_RIGHT, %al
                je draw_path

                cmpb $TILE_DOWN, %al
                je draw_path

                cmpb $TILE_STOP, %al
                je draw_path

                movq tiles(, %rax, 8), %rsi
                jmp render_texture

            draw_path:
                movq tiles + (8 * TILE_DOWN)(%rip), %rsi
                jmp render_texture

            draw_grass:
                movq tiles + (8 * TILE_GRASS)(%rip), %rsi
                jmp render_texture
            
            draw_arash:
                movq tiles + (8 * TILE_DOWN)(%rip), %rsi
                jmp render_tower
            
            draw_tower:
                movq tiles + (8 * TILE_GRASS)(%rip), %rsi
                jmp render_tower
            
            render_tower:
                movq game_ren(%rip), %rdi
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
                movss -16(%rbp), %xmm0
                movss %xmm0, -24(%rbp)

                movss -12(%rbp), %xmm0
                movss %xmm0, -20(%rbp)

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

    # get base position
    movss -24(%rbp), %xmm0
    movss %xmm0, -16(%rbp)
    
    movss base_w(%rip), %xmm0
    movl $2, %eax
    cvtsi2ss %eax, %xmm1
    divss %xmm1, %xmm0
    
    movss tile_width(%rip), %xmm2
    movl $2, %eax
    cvtsi2ss %eax, %xmm1
    divss %xmm1, %xmm2

    movss -16(%rbp), %xmm3
    subss %xmm0, %xmm3
    addss %xmm2, %xmm3
    movss %xmm3, -16(%rbp)

    movss tile_height(%rip), %xmm0
    movss -20(%rbp), %xmm1
    addss %xmm1, %xmm0
    movss base_h(%rip), %xmm2
    subss %xmm2, %xmm0
    movss %xmm0, -12(%rbp)

    movss base_w(%rip), %xmm0
    movss %xmm0, -8(%rbp) # w
    
    movss base_h(%rip), %xmm0
    movss %xmm0, -4(%rbp) # h

    movq game_ren(%rip), %rdi
    movq tiles + (8 * TILE_BASE)(%rip), %rsi
    movq $0, %rdx # we want all of the tile to be rendered
    leaq -16(%rbp), %rcx # where we want to render it
    call SDL_RenderTexture

    movl $(WAVE_SIZE - 1), %r12d
    .render_mobs:
        # check if mob is alive before rendering
        movss mob_x(, %r12, 4), %xmm0
        xorps %xmm1, %xmm1
        comiss %xmm1, %xmm0
        jb .skip_dead_mob # skip if mob_x < 0 (dead)
        
        # check mob health
        movzbq mob_health(, %r12, 1), %rax
        cmpb $0, %al
        jle .skip_dead_mob # skip if health <= 0 (dead)
        
        # draw overlay
        # SDL_SetRenderDrawColor(renderer, 0, 0, 0, 127);
        movq game_ren(%rip), %rdi
        movl $0, %esi
        movl $0, %edx
        movl $0, %ecx
        movl $127, %r8d
        call SDL_SetRenderDrawColor

        movss mob_x(, %r12, 4), %xmm0
        movss %xmm0, -16(%rbp) # x
        movss mob_y(, %r12, 4), %xmm0
        movss %xmm0, -12(%rbp) # y

        movss mob_w(%rip), %xmm0
        movss %xmm0, -8(%rbp) # w
        
        movss mob_h(%rip), %xmm0
        movss %xmm0, -4(%rbp) # h

        movq game_ren(%rip), %rdi
        leaq -16(%rbp), %rsi
        call SDL_RenderFillRect

        .skip_dead_mob:
            decl %r12d
            cmpl $0, %r12d
            jge .render_mobs

    leaq coins_text(%rip), %rdi
    leaq coins_text_format(%rip), %rsi
    movl coins, %edx
    xorl %eax, %eax
    call sprintf

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

    subq $144, %rsp
    # 128 for the SDL_Event union (-128 to -1)
    # 1 for is placing tower flag (-129)
    pushq %r14
    pushq %rbx

    movq $-1, -129(%rbp)

    # calculate tile height
    movl window_width(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movl $GRID_COLS, %ecx
    cvtsi2ss %ecx, %xmm1
    divss %xmm1, %xmm0
    movss %xmm0, tile_width
    
    # calculate tile height
    movl window_height(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movl $GRID_ROWS, %ecx
    cvtsi2ss %ecx, %xmm1
    divss %xmm1, %xmm0
    movss %xmm0, tile_height
    
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
    movss tile_width(%rip), %xmm0
    movss base_w_percentage(%rip), %xmm1
    mulss %xmm1, %xmm0
    movss %xmm0, base_w(%rip)

    # calculate base height
    movss tile_height(%rip), %xmm0
    movss base_h_percentage(%rip), %xmm1
    mulss %xmm1, %xmm0
    movss %xmm0, base_h(%rip)

    call init_wave

    # calculate mob height
    movss tile_height(%rip), %xmm0
    movl $2, %eax
    cvtsi2ss %eax, %xmm1
    divss %xmm1, %xmm0
    movss %xmm0, mob_h_center(%rip)
    movss tile_height(%rip), %xmm0
    movss mob_h_percentage(%rip), %xmm1
    mulss %xmm1, %xmm0
    movss %xmm0, mob_h(%rip)

    # calculate mob width
    movss tile_width(%rip), %xmm0
    movl $2, %eax
    cvtsi2ss %eax, %xmm1
    divss %xmm1, %xmm0
    movss %xmm0, mob_w_center(%rip)
    movss tile_width(%rip), %xmm0
    movss mob_w_percentage(%rip), %xmm1
    mulss %xmm1, %xmm0
    movss %xmm0, mob_w(%rip)

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

            cmpb $-1, -129(%rbp) # if already holding a tower block tower changing (remove if all towers cost the same)
            jne .test_reset_place_tower

            cmpl $0x0000006f, %eax # if o key was pressed
            je .place_otto_init

            cmpl $0x00000061, %eax # if a key was pressed
            je .place_arash_init

            cmpl $0x00000076, %eax # if v key was pressed
            je .place_victor_init

            cmpl $0x00000073, %eax # if s key was pressed
            je .place_stefan_init

            .test_reset_place_tower:
                cmpl $0x0000001b, %eax # if esc key was pressed
                jne .render_frame

                cmpb $-1, -129(%rbp)
                jne .reset_place_tower

                movq %r15, %rdi
                movb -130(%rbp), %sil
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
            movss -100(%rbp), %xmm0
            movss tile_width(%rip), %xmm1
            divss %xmm1, %xmm0
            cvttss2si %xmm0, %r9d
            
            cmpl $GRID_COLS, %r9d
            jge .render_frame

            # the y value is stored with a 32 byte offset from the SDL_Event address
            movss -96(%rbp), %xmm0
            movss tile_height(%rip), %xmm1
            divss %xmm1, %xmm0
            cvttss2si %xmm0, %ecx
            movl %ecx, %r10d

            cmpl $GRID_ROWS, %ecx
            jge .render_frame

            cmpl $0, %ecx
            jle .render_frame

            movl %ecx, %eax
            movl $GRID_COLS, %r8d
            imull %r8d, %eax
            addl %r9d, %eax

            movb -129(%rbp), %cl
            addb $2, %cl # adjust from cursor index to tile

            cmpb $TILE_ARASH, %cl
            je .process_arash

            # both the clicked tile and the one above it must be grass
            movslq %eax, %rax
            leaq MAP_GRID(%rip), %rdx
            movb (%rdx, %rax, 1), %cl

            cmpb $TILE_GRASS, %cl
            jne .render_frame

            subq $GRID_COLS, %rax
            movb (%rdx, %rax, 1), %cl

            cmpb $TILE_GRASS, %cl
            jne .render_frame

            movb $TILE_BLOCKED, (%rdx, %rax, 1)

            addq $GRID_COLS, %rax
            movb -129(%rbp), %cl
            addb $2, %cl # adjust from cursor index to tile
            movb %cl, (%rdx, %rax, 1)
            
            movzbq towers_index(%rip), %rax
            movb %r9b, tower_x(, %rax, 1)
            movb %r10b, tower_y(, %rax, 1)
            incb towers_index(%rip)
            
            jmp .reset_place_tower

            .process_arash:
                # clicked tile must be path
                movslq %eax, %rax
                leaq MAP_GRID(%rip), %rdx
                movb (%rdx, %rax, 1), %cl

                cmpb $TILE_DOWN, %cl
                je .good_arash_click
                
                cmpb $TILE_LEFT, %cl
                je .good_arash_click

                cmpb $TILE_RIGHT, %cl
                je .good_arash_click

                cmpb $TILE_STOP, %cl
                je .good_arash_click

                jmp .render_frame

                .good_arash_click:
                    subq $GRID_COLS, %rax
                    movb (%rdx, %rax, 1), %cl
                    cmpb $TILE_GRASS, %cl
                    je .grass_head

                    cmpb $TILE_DOWN, %cl
                    je .path_head
                    
                    cmpb $TILE_LEFT, %cl
                    je .path_head

                    cmpb $TILE_RIGHT, %cl
                    je .path_head

                    jmp .render_frame

                    .path_head:
                        movb $TILE_BLOCKED_ARASH, (%rdx, %rax, 1)
                        jmp .after_grass_head

                    .grass_head:
                        movb $TILE_BLOCKED, (%rdx, %rax, 1)
                    
                    .after_grass_head:
                        addq $GRID_COLS, %rax

                        movb $TILE_ARASH, (%rdx, %rax, 1)
                        
                        movzbq towers_index(%rip), %rax
                        movb %r9b, tower_x(, %rax, 1)
                        movb %r10b, tower_y(, %rax, 1)
                        incb towers_index(%rip)
                        jmp .reset_place_tower

        .reset_place_tower:
            call SDL_GetDefaultCursor
            movq %rax, cursor(%rip)
            movq %rax, %rdi
            call SDL_SetCursor
            movq $-1, -129(%rbp)
            jmp .render_frame
        
        .render_frame:
            call update_mobs
            call spawn_mob

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
        popq %r14
        addq $144, %rsp # deallocate stack space
        movq $0, %rax # success
        movq %rbp, %rsp
        popq %rbp
        ret
