.data

fmt: .asciz "\x1B[38;5;%ldm\x1B[48;5;%ldm%c"
reset_term: .asciz "\x1B[0m"
output_effect: .asciz "\x1B[%ldm"

.text

.include "helloWorld.s"
// .include "abc_sorted.s"
// .include "final.s"

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

	# your code goes here
	movq $0, %r8 	# index
	movq $0, %r9	# amount
	movq $0, %r10	# character
	loop:

		movq (%rbx,%r8,8), %rax	# load element of message into rax

		movzbq %al, %r10 	  	# zero extend lowest byte (character) to register r10

		shr $8, %rax		  	# shift 8 bits to the right to get amount
		movzbq %al, %r9      	# copy full quad

		shr $8, %rax
		// andl $0xffffffff, %eax
		movl %eax, %r8d

		shr $32, %rax			#shift 32 bits to the right to get rid of index
		movzbq %al, %r11		#move lower 8 bits into r11 (foreground)

		shr $8, %rax			#shift 8 bits to the right to get rid of foreground
		movzbq %al, %r12		#move lower 8 bits into r12 (background)

		cmpq %r11, %r12
		jne print_loop


	print_loop:

		movq %r10, %rcx 		# move character to rsi
		movq %r11, %rsi
		movq %r12, %rdx
		leaq fmt(%rip), %rdi	# load address of format string to rdi
		movq $0, %rax			# clear rax for printf

		pushq %r8
		pushq %r9
		pushq %r10
		pushq %r11

		call printf 			# call printf

		popq %r11
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

	movq	$MESSAGE, %rbx	# first parameter: address of the message
	call	decode			# call decode
	
	xor %rax, %rax
	movq $reset_term, %rdi
	call printf

	#epilogue
	movq	%rbp, %rsp
	popq	%rbp			# restore base pointer location 
	movq	$0, %rdi		# load program exit code
	call	exit			# exit the program
