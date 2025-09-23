.data

state: .quad 11

.text
.global predict_branch
.global actual_branch
.global init

init:
	pushq	%rbp
	movq	%rsp, %rbp

	movq	%rbp, %rsp
	popq	%rbp
	ret

predict_branch:
	pushq	%rbp
	movq	%rsp, %rbp

	movq $state, %rdx

	cmpq $11, %rdx
	jg take_branch
	jmp leave_branch

	take_branch:
		movq $1, %rax
		jmp prediciton_end
	leave_branch:
		movq $0, %rax


	prediciton_end:
		movq	%rbp, %rsp
		popq	%rbp
		ret

actual_branch:
	pushq	%rbp
	movq	%rsp, %rbp

	cmpq $1, (%rsi)
	je taken
	jmp not_taken

	taken:
		cmpq $11, %rdx
		je actual_branch_end
		incq %rdx
		jmp actual_branch_end
	not_taken:
		cmpq $00, %rdx
		je actual_branch_end
		decq %rdx
		jmp actual_branch_end


	actual_branch_end:
		movq	%rbp, %rsp
		popq	%rbp
		ret
