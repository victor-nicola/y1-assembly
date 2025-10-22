.section .note.GNU-stack,"",@progbits

.global .cards_x
.global .card_y
.global .card_w
.global .card_h

.section .data
.extern window_width
.extern window_height
.extern game_ren
.extern SDL_LoadBMP
.extern SDL_CreateTextureFromSurface
.extern SDL_DestroySurface
.extern SDL_RenderTexture
.extern SDL_RenderPresent # Added extern for the single present
.extern SDL_DestroyTexture # Added extern for the return type

.menu_w: .long 920
.menu_h: .long 540
.menu_x: .long 0
.menu_y: .long 0

.card_padding: .long 10
.menu_x_padding: .long 240


.card_w: .long 88
.card_h: .long 124
.cards_x: .long 0,0,0,0,0
.card_y: .long 0

card1: .quad 0
card2: .quad 0
card3: .quad 0
card4: .quad 0
card5: .quad 0

.section .text
.global render_hand
.extern render_scene  # Used to draw the background game scene
.extern draw_text_texture

render_hand:
    pushq %rbp
    movq %rsp, %rbp
    subq $32, %rsp # Align stack (32 bytes for 2 pushq, 16 for local rect)

    pushq %r12
    pushq %rbx
    
    movq %rdi, %r12 # R12 holds the pointer to the array of 5 card filename strings
    
    # --- Calculate Positions (Logic looks correct for positioning) ---
    # Centering the Menu
    movl window_width(%rip), %eax
    subl .menu_w(%rip), %eax
    shrl $1, %eax
    movl %eax, .menu_x(%rip)

    movl window_height(%rip), %eax
    subl .menu_h(%rip), %eax
    shrl $1, %eax
    movl %eax, .menu_y(%rip)

    # Calculate X positions
    movl .menu_x(%rip), %eax
    addl .menu_x_padding(%rip), %eax
    movl %eax, .cards_x(%rip) # Card 1

    movq .cards_x(%rip), %r8

    movl (%r8,0,4), %eax # Use Card 1 X as base
    addl .card_w(%rip), %eax
    addl .card_padding(%rip), %eax
    movl %eax, (%r8,1,4) # Card 2 
    
    movl (%r8,1,4), %eax 
    addl .card_w(%rip), %eax
    addl .card_padding(%rip), %eax
    movl %eax, (%r8,2,4) # Card 3

    movl (%r8,2,4), %eax 
    addl .card_w(%rip), %eax
    addl .card_padding(%rip), %eax
    movl %eax, (%r8,3,4) # Card 4

    movl (%r8,3,4), %eax 
    addl .card_w(%rip), %eax
    addl .card_padding(%rip), %eax
    movl %eax, (%r8,4,4) # Card 5

    movl %r8d, .cards_x(%rip)

    # Calculate Y position
    movl .menu_y(%rip), %eax
    addl $100, %eax # Adding a vertical offset 
    movl %eax, .card_y(%rip)
    
    # --- Load Textures (Loops through 5 times, fixed to use R12 for string base) ---
    movq $0, %rcx # Loop index
.load_card_loop:
    cmpq $5, %rcx
    je .start_drawing

    # Load BMP (SDL_LoadBMP(filename_ptr))
    movq %r12, %rdi
    movq %rcx, %rdx
    imulq $8, %rdx
    addq %rdx, %rdi # rdi = r12 + rcx * 8 (Address of the string)
    call SDL_LoadBMP
    movq %rax, %rbx # save surface

    # Create Texture (SDL_CreateTextureFromSurface(renderer, surface))
    movq game_ren(%rip), %rdi
    movq %rbx, %rsi
    call SDL_CreateTextureFromSurface
    
    # Store texture pointer in static variable
    movq %rax, (%r8, %rcx, 8) # Store at card1 + rcx * 8 (i.e., card1, card2, ...)
    movq %r8, card1(%rip)
    
    # Destroy Surface (SDL_DestroySurface(surface))
    movq %rbx, %rdi
    call SDL_DestroySurface
    
    incq %rcx
    jmp .load_card_loop

.start_drawing:
    # 1. Draw game scene 
    call render_scene 

    # 2. Draw cards (Draws all 5)
    movq $0, %rcx # Loop index
.draw_card_loop:
    cmpq $5, %rcx
    je .present_and_return

    # Load correct X position
    movq .cards_x(%rip), %r8
    movl (%r8, %rcx, 4), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -16(%rbp) # x
    
    # Load Y, W, H (Y is static, W/H are static)
    movl .card_y(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -12(%rbp) # y
    movl .card_w(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -8(%rbp) # w
    movl .card_h(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -4(%rbp) # h

    # Draw the texture (SDL_RenderTexture(renderer, texture, NULL, &dstrect))
    movq game_ren(%rip), %rdi
    movq card1(%rip), %r8
    movq (%r8, %rcx, 8), %rsi # Load texture pointer from card1 + rcx*8
    movq $0, %rdx
    leaq -16(%rbp), %rcx
    call SDL_RenderTexture 

    incq %rcx
    jmp .draw_card_loop

.present_and_return:
    call SDL_RenderPresent # Update the screen

    leaq card1(%rip), %rax # Return the base address of the 5 card texture pointers (card1-card5)
    
    popq %rbx
    popq %r12
    
    addq $32, %rsp 
    movq %rbp, %rsp
    popq %rbp
    ret
