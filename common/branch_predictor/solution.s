.data
state: .quad 2

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

	movq state, %rdx

	andq $2, %rdx 

	cmpq $2, %rdx
	je take_branch
	jmp leave_branch

	take_branch:
		movq $1, %rax
		jmp prediction_end
	leave_branch:
		movq $0, %rax

	prediction_end:
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

	cmpq $1, %rsi
	je taken
	jmp not_taken

	taken:
		# fancy math to avoid a comparison
		# get first bit of state
		movq state, %rax
		andq $2, %rax
		shr $1, %rax

		# get second bit of state
		movq state, %rcx
		andq $1, %rcx

		# this leaves the value to add in rax (0 or 1)
		andq %rcx, %rax
		not %rax
		andq $1, %rax

		movq state, %rdx
		add %rax, %rdx
		jmp actual_branch_end
	not_taken:
		# fancy math to avoid a comparison
		# get first bit of state
		movq state, %rax
		andq $2, %rax
		shr $1, %rax

		# get second bit of state
		movq state, %rcx
		andq $1, %rcx

		# this leaves the value to subtract from rax (0 or 1)
		or %rcx, %rax
		andq $1, %rax

		movq state, %rdx
		sub %rax, %rdx
		jmp actual_branch_end

	actual_branch_end:
		movq %rdx, state # save new state

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
