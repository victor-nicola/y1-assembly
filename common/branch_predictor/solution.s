.data
.equ STATE_SIZE, 1 << 20
.equ STATE_MASK, STATE_SIZE - 1
.equ HISTORY_SIZE, 16
.equ HISTORY_MASK, (1 << HISTORY_SIZE) - 1
state: .space STATE_SIZE
history: .quad 0

.text
.global predict_branch
.global actual_branch
.global init

init:
	# prologue
	pushq %rbp
	movq %rsp, %rbp

	# save callee-saved registries
	pushq %rbx
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	subq $8, %rsp # align stack

<<<<<<< HEAD
	
=======
    movq $0, %rcx
    movq $STATE_SIZE, %rdx

    init_loop:
        movb $2, state(,%rcx,1)

        incq %rcx
        cmpq %rdx, %rcx
        jl init_loop

	# restore callee-saved registries
	addq $8, %rsp
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %rbx

	# epilogue
	movq %rbp, %rsp
	popq %rbp
	ret

get_index:
	# prologue
	pushq %rbp
	movq %rsp, %rbp

	# save callee-saved registries
	pushq %rbx
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	subq $8, %rsp # align stack

	# get the index in the array for this instruction 
	# combine last bits of the address with the history
	xorq history, %rdi # combine history and pointer
	andq $STATE_MASK, %rdi # fit into array
	movq %rdi, %rax
>>>>>>> refs/remotes/origin/main

	# restore callee-saved registries
	addq $8, %rsp
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %rbx

	# epilogue
	movq %rbp, %rsp
	popq %rbp
	ret

predict_branch:
	# prologue
	pushq %rbp
	movq %rsp, %rbp

	# save callee-saved registries
	pushq %rbx
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	subq $8, %rsp # align stack

	# get the index in the array for this instruction
	call get_index

	movzbq state(, %rax, 1), %rdx

	# get first bit of the counter
	andq $2, %rdx
	shr $1, %rdx
	movq %rdx, %rax

	# restore callee-saved registries
	addq $8, %rsp
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %rbx

	# epilogue
	movq %rbp, %rsp
	popq %rbp
	ret

actual_branch:
	# prologue
	pushq %rbp
	movq %rsp, %rbp

	# save callee-saved registries
	pushq %rbx
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	subq $8, %rsp # align stack

	# get the index in the array for this instruction 
	call get_index
	movq %rax, %rbx

	movzbq state(, %rbx, 1), %rdx

	cmpq $1, %rsi
	je taken
	jmp not_taken

	taken:
		# fancy math to avoid comparisons and jumps
		# get first bit of state
		movq %rdx, %rax
		andq $2, %rax
		shr $1, %rax

		# get second bit of state
		movq %rdx, %rcx
		andq $1, %rcx

		# this leaves the value to add in rax (0 or 1)
		andq %rcx, %rax
		not %rax
		andq $1, %rax

		add %rax, %rdx
		jmp actual_branch_end
	not_taken:
		# fancy math to avoid comparisons and jumps
		# get first bit of state
		movq %rdx, %rax
		andq $2, %rax
		shr $1, %rax

		# get second bit of state
		movq %rdx, %rcx
		andq $1, %rcx

		# this leaves the value to subtract from rax (0 or 1)
		or %rcx, %rax
		andq $1, %rax

		sub %rax, %rdx
		jmp actual_branch_end

	actual_branch_end:
		movb %dl, state(, %rbx, 1) # save new state

		# update history
		shlq $1, history # make space for the new answer
		orq %rsi, history # add answer to history
		andq $HISTORY_MASK, history # make sure we keep the history the right size

		# restore callee-saved registries
		addq $8, %rsp
		popq %r15
		popq %r14
		popq %r13
		popq %r12
		popq %rbx

		# epilogue
		movq %rbp, %rsp
		popq %rbp
		ret
