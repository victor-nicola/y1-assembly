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

	movq $1, %rax

	movq	%rbp, %rsp
	popq	%rbp
	ret

actual_branch:
	pushq	%rbp
	movq	%rsp, %rbp


	movq	%rbp, %rsp
	popq	%rbp
	ret
