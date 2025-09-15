.data

fmt:	.asciz "%c"

.text

.include "abc_sorted.s"

.global main

# ************************************************************
# Subroutine: decode                                         *
# Description: decodes message as defined in Assignment 3    *
#   - 2 byte unknown                                         *
#   - 4 byte index                                           *
#   - 1 byte amount                                          *
#   - 1 byte character                                       *
# Parameters:                                                *
#   first: the address of the message to read                *
#   return: no return value                                  *
# ************************************************************


decode:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	pushq	%rdi
	movq	$0, %rdi

	# your code goes here
	movq $0, %r8 	# index
	movq $0, %r9	# amount
	movq $0, %r10	# character
	loop:
		popq %rdi

		movq (%rdi,%r8,8), %rax	# load element of message into rax

		pushq %rdi
		movq $0, %rdi

		movzbq %al, %r10 	  	# zero extend lowest byte (character) to register r10

		shr $8, %rax		  	# shift 8 bits to the right to get amount
		movzbq %al, %r9      	# copy full quad

		shr $8, %rax
		andl $0xffffffff, %eax
		movl %eax, %r8d



	print_loop:

		movq %r10, %rsi 		# move character to rsi
		leaq fmt(%rip), %rdi	# load address of format string to rdi
		movq $0, %rax			# clear rax for printf

		pushq %r8
		pushq %r9
		pushq %r10
		subq $8, %rsp

		call printf 			# call printf

		addq $8, %rsp
		popq %r10
		popq %r9
		popq %r8

		decq %r9				# decrement amount
		cmpq $0, %r9			# compare amount to loop counter
		jg print_loop
		
		cmpq $0, %r8			# compare index to 0
		jne loop				# if index != 0, continue loop
		jmp end_loop


	end_loop:
		# epilogue
		movq	%rbp, %rsp		# clear local variables from stack
		popq	%rbp			# restore base pointer location 
		ret


main:

	#prologoue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq	$MESSAGE, %rdi	# first parameter: address of the message
	call	decode			# call decode


	#epilogue
	movq	%rbp, %rsp
	popq	%rbp			# restore base pointer location 
	movq	$0, %rdi		# load program exit code
	call	exit			# exit the program
	