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
	# no prologue or epilogue since we don't touch the stack
	# not saving callee-saved since we don't touch them

    movq $0, %rcx
    movq $STATE_SIZE, %rdx

    init_loop:
        movb $2, state(,%rcx,1)

        incq %rcx
        cmpq %rdx, %rcx
        jl init_loop
	ret

predict_branch:
	# no prologue or epilogue since we don't touch the stack
	# not saving callee-saved since we don't touch them

	# get the index in the array for this instruction
	# combine last bits of the address with the history
	xorq history, %rdi # combine history and pointer
	andq $STATE_MASK, %rdi # fit into array

	movzbq state(, %rdi, 1), %rax

	# get first bit of the counter
	andq $2, %rax
	shr $1, %rax
	ret

actual_branch:
	# no prologue or epilogue since we don't touch the stack
	# not saving callee-saved since we don't touch them

	# get the index in the array for this instruction 
	# combine last bits of the address with the history
	xorq history, %rdi # combine history and pointer
	andq $STATE_MASK, %rdi # fit into array

	cmpq $1, %rsi
	je taken
	jmp not_taken

	taken:
		cmpb $3, state(, %rdi, 1) # if it's saturated don't increment
		jge actual_branch_end
		incb state(, %rdi, 1)
	not_taken:
		cmpb $0, state(, %rdi, 1) # if it's saturated don't decrement
		jle actual_branch_end
		decb state(, %rdi, 1)

	actual_branch_end:
		# update history
		shlq $1, history # make space for the new answer
		orq %rsi, history # add answer to history
		andq $HISTORY_MASK, history # make sure we keep the history the right size
		ret
