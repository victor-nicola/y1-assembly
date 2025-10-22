.section .note.GNU-stack,"",@progbits

.section .data
.extern window_width
.extern window_height
.extern game_ren
.extern SDL_RenderTexture
.extern SDL_DestroyTexture
.extern SDL_PollEvent
.extern SDL_RenderPresent
.extern render_scene
.extern SDL_GetTicks
.extern SDL_Delay
.extern get_poker_hand

.extern .cards_x
.extern .card_y
.extern .card_w
.extern .card_h

close_button_path: .asciz "../assets/upgrade-menu-buttons/close_icon.bmp"
upgrade_button_path: .asciz "../assets/upgrade-menu-buttons/upgrade-button.bmp"
upgrade1_path:     .asciz "../assets/upgrade-menu-buttons/upgrade1.bmp" 
upgrade2_path:     .asciz "../assets/upgrade-menu-buttons/upgrade2.bmp" 
upgrade3_path:     .asciz "../assets/upgrade-menu-buttons/upgrade3.bmp" 

## Panel and Button properties
.menu_w: .long 960
.menu_h: .long 540
.menu_xpadding: .long 900
.menu_ypadding: .long 480
.menu_x: .long 0
.menu_y: .long 0

.close_button_w: .long 32
.close_button_h: .long 32
.close_button_x: .long 0
.close_button_y: .long 0

.upgrade_button_w: .long 256
.upgrade_button_h: .long 64
.upgrade_button_x: .long 0
.upgrade_button_y: .long 0

upgrade_button: .quad 0
close_button: .quad 0
upgrade_menu_texture: .quad 0 

# --- POKER STATE VARIABLES ---
poker_textures_addr: .quad 0  # Base address of the 5 texture pointers (card1 address)
poker_end_time: .long 0       # SDL_GetTicks() + 3000
poker_state: .long 0          # 0=Menu, 1=Poker Display Active, 2=Score Processing
poker_hand_score: .long 0     # The score (0-9)
# ----------------------------

.section .text
.global render_menu
.extern game_font
.extern draw_text_texture
.extern SDL_LoadBMP
.extern SDL_CreateTextureFromSurface
.extern SDL_DestroySurface

.extern get_poker_hand

render_upgrade_menu:
    pushq %rbp
    movq %rsp, %rbp
    subq $160, %rsp
    pushq %rbx
    pushq %r12
    movq %rdi, -152(%rbp)

    # --- (Calculation and Initial Texture Loading - UNCHANGED) ---
    movl window_width(%rip), %eax
    subl .menu_w(%rip), %eax
    shrl $1, %eax
    movl %eax, .menu_x(%rip)

    movl window_height(%rip), %eax
    subl .menu_h(%rip), %eax
    shrl $1, %eax
    movl %eax, .menu_y(%rip)

    movl .menu_x(%rip), %eax
    addl .menu_w(%rip), %eax
    addl .menu_w(%rip), %eax
    subl .close_button_w(%rip), %eax
    subl .menu_xpadding(%rip), %eax
    movl %eax, .close_button_x(%rip)

    movl .menu_y(%rip), %eax
    # addl .menu_ypadding(%rip), %eax
    movl %eax, .close_button_y(%rip)

    movl .menu_x(%rip), %eax
    addl .menu_w(%rip), %eax
    subl .upgrade_button_w(%rip), %eax
    movl %eax, .upgrade_button_x(%rip)

    movl .menu_y(%rip), %eax
    subl .menu_ypadding(%rip), %eax
    movl %eax, .upgrade_button_y(%rip)

    leaq close_button_path(%rip), %rdi
    call SDL_LoadBMP
    movq %rax, %rbx
    movq game_ren(%rip), %rdi
    movq %rbx, %rsi
    call SDL_CreateTextureFromSurface
    movq %rax, close_button(%rip)
    movq %rbx, %rdi
    call SDL_DestroySurface

    leaq upgrade_button_path(%rip), %rdi
    call SDL_LoadBMP
    movq %rax, %rbx
    movq game_ren(%rip), %rdi
    movq %rbx, %rsi
    call SDL_CreateTextureFromSurface
    movq %rax, upgrade_button(%rip)
    movq %rbx, %rdi
    call SDL_DestroySurface

    movq -152(%rbp), %rdi
    cmpq $1, %rdi
    je .load_upgrade1
    cmpq $2, %rdi
    je .load_upgrade2
    
    leaq upgrade3_path(%rip), %rdi
    jmp .load_texture

.load_upgrade1:
    leaq upgrade1_path(%rip), %rdi
    jmp .load_texture
.load_upgrade2:
    leaq upgrade2_path(%rip), %rdi
    
.load_texture:
    call SDL_LoadBMP
    movq %rax, %rbx
    movq game_ren(%rip), %rdi
    movq %rbx, %rsi
    call SDL_CreateTextureFromSurface
    movq %rax, upgrade_menu_texture(%rip)
    movq %rbx, %rdi
    call SDL_DestroySurface

.menu_loop:
    # 1. CHECK STATE
    cmpl $1, poker_state(%rip)
    je .poker_display_loop      # State 1: Displaying the poker hand

    cmpl $2, poker_state(%rip)
    je .process_poker_result    # State 2: Ready to process score
    
    # --- State 0: Draw Menu and Handle Input (UNCHANGED DRAW/INPUT) ---
    movq -152(%rbp), %rdi
    call render_scene

    movl .menu_x(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -16(%rbp)
    movl .menu_y(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -12(%rbp)
    movl .menu_w(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -8(%rbp)
    movl .menu_h(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -4(%rbp)
    movq game_ren(%rip), %rdi
    movq upgrade_menu_texture(%rip), %rsi
    movq $0, %rdx
    leaq -16(%rbp), %rcx
    call SDL_RenderTexture 

    movl .close_button_x(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -32(%rbp)
    movl .close_button_y(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -28(%rbp)
    movl .close_button_w(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -24(%rbp)
    movl .close_button_h(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -20(%rbp)
    movq game_ren(%rip), %rdi
    movq close_button(%rip), %rsi
    movq $0, %rdx
    leaq -32(%rbp), %rcx
    call SDL_RenderTexture

    movl .upgrade_button_x(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -16(%rbp)
    movl .upgrade_button_y(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -12(%rbp)
    movl .upgrade_button_w(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -8(%rbp)
    movl .upgrade_button_h(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -4(%rbp)
    movq game_ren(%rip), %rdi
    movq upgrade_button(%rip), %rsi
    movq $0, %rdx
    leaq -16(%rbp), %rcx
    call SDL_RenderTexture

    leaq -144(%rbp), %rdi
    call SDL_PollEvent
    cmpl $0, %eax
    je .show_menu

    cmpl $0x401, -144(%rbp)
    jne .show_menu

    cmpb $1, -120(%rbp)
    jne .show_menu

    movl -116(%rbp), %eax
    movl -112(%rbp), %ecx

    movl .close_button_x(%rip), %r8d
    addl .close_button_w(%rip), %r8d
    movl .close_button_y(%rip), %edx
    addl .close_button_h(%rip), %edx
    cmpl .close_button_x(%rip), %eax
    jl .show_menu
    cmpl %r8d, %eax
    jg .show_menu
    cmpl .close_button_y(%rip), %ecx
    jl .show_menu
    cmpl %edx, %ecx
    jg .show_menu
    jle .close_menu

    movl .upgrade_button_x(%rip), %r8d
    addl .upgrade_button_w(%rip), %r8d
    movl .upgrade_button_y(%rip), %edx
    addl .upgrade_button_h(%rip), %edx
    cmpl .upgrade_button_x(%rip), %eax
    jl .show_menu
    cmpl %r8d, %eax
    jg .show_menu
    cmpl .upgrade_button_y(%rip), %ecx
    jl .show_menu
    cmpl %edx, %ecx
    jg .show_menu
    
    jmp .upgrade_button_clicked

.show_menu:
    movq game_ren(%rip), %rdi
    call SDL_RenderPresent
    jmp .menu_loop

.upgrade_button_clicked:
    call get_poker_hand
    
    # RAX = Hand Score (0-9)
    # R15 = Texture Array Address
    
    movq %r15, poker_textures_addr(%rip)
    movl %eax, poker_hand_score(%rip) # Store score

    call SDL_GetTicks
    addl $3000, %eax
    movl %eax, poker_end_time(%rip)
    
    movl $1, poker_state(%rip)
    
    jmp .menu_loop

# ----------------------------------------------------
# --- State 1: POKER DISPLAY LOOP ---
# ----------------------------------------------------
.poker_display_loop:
    call SDL_GetTicks
    cmpl poker_end_time(%rip), %eax
    jge .destroy_poker_hand

    movq -152(%rbp), %rdi 
    call render_scene
    
    movq $0, %r12
    
.draw_cards_in_menu:
    cmpq $5, %r12
    je .present_poker_and_delay

    leaq .cards_x(%rip), %r8
    movl (%r8,%r12,4), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -16(%rbp)
    
    movl .card_y(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -12(%rbp)
    movl .card_w(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -8(%rbp)
    movl .card_h(%rip), %eax
    cvtsi2ss %eax, %xmm0
    movss %xmm0, -4(%rbp)

    movq game_ren(%rip), %rdi
    
    movq poker_textures_addr(%rip), %r8
    movq (%r8, %r12, 8), %rsi # Load the actual texture pointer from the quad array
    
    movq $0, %rdx
    leaq -16(%rbp), %rcx
    call SDL_RenderTexture 

    incq %r12
    jmp .draw_cards_in_menu

.present_poker_and_delay:
    call SDL_RenderPresent
    
    movl $10, %edi
    call SDL_Delay
    
    leaq -144(%rbp), %rdi
    call SDL_PollEvent
    
    jmp .menu_loop

.destroy_poker_hand:
    # Clean up the 5 textures
    movq poker_textures_addr(%rip), %r12
    movq $0, %rcx
.cleanup_textures_loop:
    cmpq $5, %rcx
    je .reset_poker_state
    
    movq (%r12, %rcx, 8), %rdi
    call SDL_DestroyTexture
    
    incq %rcx
    jmp .cleanup_textures_loop

.reset_poker_state:
    movq $0, poker_textures_addr(%rip)
    movl $0, poker_end_time(%rip)
    
    movl $2, poker_state(%rip)
    
    jmp .menu_loop

# ----------------------------------------------------
# --- State 2: POKER SCORE PROCESSING ---
# ----------------------------------------------------
.process_poker_result:


    movl $0, poker_state(%rip) 
    jmp .menu_loop

.close_menu:
    movq $0, %rax
    jmp .menu_loop_end

.menu_loop_end:
    movq close_button(%rip), %rdi
    call SDL_DestroyTexture
    
    movq upgrade_button(%rip), %rdi # Added cleanup for upgrade button
    call SDL_DestroyTexture

    movq upgrade_menu_texture(%rip), %rdi
    call SDL_DestroyTexture 

    cmpq $3 , -152(%rbp) 
    movl poker_hand_score, %eax
    je give_money
    jmp dont_give_money

    give_money:
        movq $10, %rbx
        mulq %rbx

    dont_give_money:

    popq %r12
    popq %rbx
    addq $160, %rsp
    popq %rbp
    ret
