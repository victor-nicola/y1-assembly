# this directive ensures the stack is not executable for security reasons (i get an error on fedora 42 if i don't have this)
.section .note.GNU-stack,"",@progbits

.section .data
.equ DEAD, -1
.equ EXAM, 0
.equ ASSIGNMENT, 1
.equ DEADLINE, 2
.equ MIDTERM, 3
.equ FINAL, 4
.equ WAVE_SIZE, 20

HEALTH: .byte 2, 5, 3, 20, 50
waves: .byte EXAM, EXAM, EXAM, EXAM, EXAM, EXAM, EXAM, EXAM, EXAM, EXAM, EXAM, EXAM, EXAM, EXAM, EXAM, EXAM, EXAM, EXAM, EXAM, EXAM
mob_x: .space (WAVE_SIZE * 4)
mob_y: .space (WAVE_SIZE * 4)
mob_health: .space WAVE_SIZE
mob_direction: .space WAVE_SIZE
MOB_SPEED: .float 0.1
DIRECTION_CHANGE_THRESHOLD: .float 0.5
last_spawn_time: .long 0
SPAWN_INTERVAL: .long 3000
mob_index: .byte (WAVE_SIZE - 1)

.section .text

.global mob_x
.global mob_y
.global waves
.global spawn_mob
.global init_wave
.global update_mobs
.global WAVE_SIZE
.global mob_health

.extern SDL_GetTicks

init_wave:
    pushq %rbp
    movq %rsp, %rbp
    pushq %r15
    subq $8, %rsp

    movq $0, %r15
    .reset_pos_loop:
        movzbq waves(, %r15, 1), %rax
        movb $0, mob_health(, %r15, 1)

        # Initialize direction to DOWN (start moving down)
        movb $TILE_DOWN, mob_direction(, %r15, 1)

        movl $-1, %eax
        cvtsi2ss %eax, %xmm0
        movss %xmm0, mob_x(, %r15, 4)
        movss %xmm0, mob_y(, %r15, 4)

        incq %r15
        cmpq $WAVE_SIZE, %r15
        jl .reset_pos_loop

    addq $5, %rsp
    popq %r15
    movq %rbp, %rsp
    popq %rbp
    ret

spawn_mob:
    pushq %rbp
    movq %rsp, %rbp

    cmpb $-1, mob_index(%rip)
    je .spawn_mob_end

    cmpb $(WAVE_SIZE - 1), mob_index(%rip)
    je .spawn_mob_logic

    # time-based spawning using SDL ticks
    call SDL_GetTicks@PLT
    
    # check if enough time has passed since last spawn
    movl last_spawn_time(%rip), %ecx
    subl %ecx, %eax # current_time - last_spawn_time
    cmpl SPAWN_INTERVAL(%rip), %eax
    jb .spawn_mob_end # if less than interval skip spawn

    # update last spawn time
    call SDL_GetTicks@PLT
    movl %eax, last_spawn_time(%rip)

    .spawn_mob_logic:
        movss tile_height(%rip), %xmm0
        movl $2, %eax
        cvtsi2ss %eax, %xmm1
        divss %xmm1, %xmm0
        movss mob_h(%rip), %xmm2
        divss %xmm1, %xmm2
        subss %xmm2, %xmm0
        movzbq mob_index(%rip), %rax
        movss %xmm0, mob_y(, %rax, 4)

        # center mob horizontally in column 2: 2 * tile_width + tile_width/2 - mob_w/2
        movl $2, %eax
        cvtsi2ss %eax, %xmm0
        movss tile_width(%rip), %xmm1
        mulss %xmm1, %xmm0          # 2 * tile_width (left edge of column 2)
        movss tile_width(%rip), %xmm1
        movl $2, %eax
        cvtsi2ss %eax, %xmm2
        divss %xmm2, %xmm1          # tile_width / 2
        addss %xmm1, %xmm0          # 2 * tile_width + tile_width/2 (center of column 2)
        movss mob_w(%rip), %xmm1
        divss %xmm2, %xmm1          # mob_w / 2
        subss %xmm1, %xmm0          # subtract half mob width for centering
        movzbq mob_index(%rip), %rax
        movss %xmm0, mob_x(, %rax, 4)
        movzbq waves(, %rax, 1), %rdx
        movb HEALTH(, %rdx, 1), %cl
        movb %cl, mob_health(, %rax, 1)
        decq mob_index(%rip)

    .spawn_mob_end:
        movq %rbp, %rsp
        popq %rbp
        ret

update_mobs:
    pushq %rbp
    movq %rsp, %rbp
    
    pushq %r12
    subq $8, %rsp

    movl $(WAVE_SIZE - 1), %r12d
    .update_mob_pos:
        # check bounds
        cmpl $0, %r12d
        jl .next_mob
        cmpl $WAVE_SIZE, %r12d
        jge .next_mob

        # check if mob is active (positive coordinates and health)
        movss mob_x(, %r12, 4), %xmm0
        movl $0, %eax
        cvtsi2ss %eax, %xmm1
        comiss %xmm1, %xmm0
        jb .next_mob # skip if mob_x < 0 (destroyed/inactive)

        # also check health
        movb mob_health(, %r12, 1), %al
        cmpb $0, %al
        jle .next_mob # skip if health <= 0 (dead)

        # get mob center position
        movss mob_x(, %r12, 4), %xmm2
        movss mob_w(%rip), %xmm4
        movl $2, %eax
        cvtsi2ss %eax, %xmm6
        divss %xmm6, %xmm4
        addss %xmm4, %xmm2 # mob center x
        
        movss mob_y(, %r12, 4), %xmm3
        movss mob_h(%rip), %xmm4
        divss %xmm6, %xmm4
        addss %xmm4, %xmm3 # mob center y
        
        # calculate which tile the mob center is in
        movss %xmm2, %xmm0
        movss tile_width(%rip), %xmm1
        divss %xmm1, %xmm0
        cvttss2si %xmm0, %r9d
        
        movss %xmm3, %xmm0
        movss tile_height(%rip), %xmm1
        divss %xmm1, %xmm0
        cvttss2si %xmm0, %ecx
        
        # calculate tile center
        cvtsi2ss %r9d, %xmm0
        movss tile_width(%rip), %xmm1
        mulss %xmm1, %xmm0
        movss tile_width(%rip), %xmm1
        divss %xmm6, %xmm1
        addss %xmm1, %xmm0 # tile center x
        
        cvtsi2ss %ecx, %xmm5
        movss tile_height(%rip), %xmm1
        mulss %xmm1, %xmm5
        movss tile_height(%rip), %xmm1
        divss %xmm6, %xmm1
        addss %xmm1, %xmm5 # tile center y
        
        # check if mob is close to tile center
        movb mob_direction(, %r12, 1), %r8b
        movss DIRECTION_CHANGE_THRESHOLD(%rip), %xmm7
        
        cmpb $TILE_DOWN, %r8b
        je .check_y_center
        
        cmpb $TILE_LEFT, %r8b
        je .check_x_center
        
        cmpb $TILE_RIGHT, %r8b
        je .check_x_center
        
        jmp .move_current_direction
        
        .check_y_center:
            movss %xmm3, %xmm1
            subss %xmm5, %xmm1
            mulss %xmm1, %xmm1
            sqrtss %xmm1, %xmm1
            
            comiss %xmm7, %xmm1
            ja .move_current_direction
            
            jmp .check_tile_and_change
        
        .check_x_center:
            movss %xmm2, %xmm1
            subss %xmm0, %xmm1
            mulss %xmm1, %xmm1
            sqrtss %xmm1, %xmm1
            
            comiss %xmm7, %xmm1
            ja .move_current_direction

            jmp .check_tile_and_change
        
        .check_tile_and_change:
            # get current tile type
            movq $GRID_COLS, %rax
            mull %ecx
            addq %r9, %rax
            leaq MAP_GRID(%rip), %rdi
            movzbq (%rdi, %rax, 1), %rax
            
            # check tile type and change direction if needed
            cmpq $TILE_STOP, %rax
            je .destroy_mob
            
            cmpq $TILE_LEFT, %rax
            je .set_left_and_move
            
            cmpq $TILE_RIGHT, %rax
            je .set_right_and_move
            
            cmpq $TILE_DOWN, %rax
            je .set_down_and_move
            # if same direction continue moving
        
        .move_current_direction:
            movzbq mob_direction(, %r12, 1), %r8
            
            cmpq $TILE_DOWN, %r8
            je .move_down
            
            cmpq $TILE_LEFT, %r8
            je .move_left
            
            cmpq $TILE_RIGHT, %r8
            je .move_right
            
            jmp .move_down
            
        .set_left_and_move:
            movb $TILE_LEFT, mob_direction(, %r12, 1)
            jmp .move_left
            
        .set_right_and_move:
            movb $TILE_RIGHT, mob_direction(, %r12, 1)
            jmp .move_right
            
        .set_down_and_move:
            movb $TILE_DOWN, mob_direction(, %r12, 1)
            jmp .move_down

        .move_down:
            movss MOB_SPEED(%rip), %xmm1
            movss mob_y(, %r12, 4), %xmm0
            addss %xmm1, %xmm0
            movss %xmm0, mob_y(, %r12, 4)
            jmp .next_mob

        .move_left:
            movss MOB_SPEED(%rip), %xmm1
            movss mob_x(, %r12, 4), %xmm0
            subss %xmm1, %xmm0
            movss %xmm0, mob_x(, %r12, 4)
            jmp .next_mob

        .move_right:
            movss MOB_SPEED(%rip), %xmm1
            movss mob_x(, %r12, 4), %xmm0
            addss %xmm1, %xmm0
            movss %xmm0, mob_x(, %r12, 4)
            jmp .next_mob

        .destroy_mob:
            # mark mob as completely inactive
            movl $-1, %eax
            cvtsi2ss %eax, %xmm0
            movss %xmm0, mob_x(, %r12, 4)
            movss %xmm0, mob_y(, %r12, 4)
            # set health to dead state
            movb $-1, mob_health(, %r12, 1)
            jmp .next_mob

        .next_mob:
            decl %r12d
            cmpb $0, %r12b
            jge .update_mob_pos

    .update_mob_end:
        addq $8, %rsp
        popq %r12
        movq %rbp, %rsp
        popq %rbp
        ret
