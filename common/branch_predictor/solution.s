.data
.equ STATE_SIZE, 1 << 20
.equ STATE_MASK, STATE_SIZE - 1
.equ HISTORY_SIZE, 16
.equ HISTORY_MASK, (1 << HISTORY_SIZE) - 1
state: .space STATE_SIZE
history: .quad 0
format_init: .asciz "Init clock cycles: %ld\n"
format_predict: .asciz "Prediction clock cycles: %ld\n"
format_actual: .asciz "Actual branch update clock cycles: %ld\n"

.text
.global predict_branch
.global actual_branch
.global init

init:
	# no prologue or epilogue since we don't touch the stack
	# not saving callee-saved since we don't touch them

	rdtsc		#get time in eax:edx
	shlq $32, %rdx	#shift rdx to the left 32 bits to make space for the lower 32 in rax
	or %rax, %rdx	#combine upper and lower 32 bits of rdx:rax to get the clock cycle start
	movq %rdx, %r15	#save number in r15

    movq $0, %rcx
    movq $STATE_SIZE, %rdx

    init_loop:
        movb $2, state(,%rcx,1)

        incq %rcx
        cmpq %rdx, %rcx
        jl init_loop


	rdtsc
	shlq $32, %rdx
	or %rax, %rdx
	subq %r15, %rdx	#subtract start time from end time
	movq %rdx, %rsi
	leaq format_init(%rip), %rdi
	xor %rax, %rax
	call printf		#print total clock cycles (4-6 million for init function)
	xor %rdi, %rdi


	ret

predict_branch:
	# no prologue or epilogue since we don't touch the stack
	# not saving callee-saved since we don't touch them

	rdtsc		#get time in eax:edx
	shlq $32, %rdx	#shift rdx to the left 32 bits to make space for the lower 32 in rax
	or %rax, %rdx	#combine upper and lower 32 bits of rdx:rax to get the clock cycle start
	movq %rdx, %r15	#save number in r15
	xor %rax, %rax	#make rax 0 to make sure it doesn't hold anything

	# get the index in the array for this instruction
	# combine last bits of the address with the history
	xorq history, %rdi # combine history and pointer
	andq $STATE_MASK, %rdi # fit into array

	movzbq state(, %rdi, 1), %rax

	# get first bit of the counter
	andq $2, %rax
	shr $1, %rax

	pushq %rdi
	pushq %rax

	rdtsc
	shlq $32, %rdx
	or %rax, %rdx
	subq %r15, %rdx	#subtract start time from end time
	movq %rdx, %rsi
	leaq format_predict(%rip), %rdi
	xor %rax, %rax
	call printf		#print total clock cycles (average 85 per prediction, so ~8500 for all of them)

	popq %rax
	popq %rdi

	ret

actual_branch:
	# no prologue or epilogue since we don't touch the stack
	# not saving callee-saved since we don't touch them
	rdtsc		#get time in eax:edx
	shlq $32, %rdx	#shift rdx to the left 32 bits to make space for the lower 32 in rax
	or %rax, %rdx	#combine upper and lower 32 bits of rdx:rax to get the clock cycle start
	movq %rdx, %r15	#save number in r15
	xor %rax, %rax	#make rax 0 to make sure it doesn't hold anything

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
		jmp actual_branch_end
	not_taken:
		cmpb $0, state(, %rdi, 1) # if it's saturated don't decrement
		jle actual_branch_end
		decb state(, %rdi, 1)

	actual_branch_end:
		# update history
		shlq $1, history # make space for the new answer
		orq %rsi, history # add answer to history
		andq $HISTORY_MASK, history # make sure we keep the history the right size

		pushq %rdi
		pushq %rax

		rdtsc
		shlq $32, %rdx
		or %rax, %rdx
		subq %r15, %rdx	#subtract start time from end time
		movq %rdx, %rsi
		leaq format_actual(%rip), %rdi
		xor %rax, %rax
		call printf		#print total clock cycles (average 95 per prediction, so ~9500 for all of them)

		popq %rax
		popq %rdi

		ret
