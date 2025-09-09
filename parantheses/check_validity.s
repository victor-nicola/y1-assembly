.text

.include "neighboringValid.s"

valid_output: .asciz "valid\n"
invalid_output: .asciz "invalid\n"

.global main

# *******************************************************************************************
# Subroutine: check_validity                                                                *
# Description: checks the validity of a string of parentheses as defined in Assignment 6.   *
# Parameters:                                                                               *
#   first: the string that should be check_validity                                         *
#   return: the result of the check, either "valid" or "invalid"                            *
# *******************************************************************************************
check_validity:
	# prologue
	pushq %rbp 			# push the base pointer (and align the stack)
	movq %rsp, %rbp		# copy stack pointer value to base pointer

	pushq %rbx
	movq %rdi, %rbx
	movq %rsp, %r11

	movq $0, %r8 # index in string
	jmp loop_start

	is_invalid:
		movq $invalid_output, %rax
		jmp end_function

	is_valid:
		movq $valid_output, %rax
		jmp end_function

	end_function:
		# epilogue
		movq %r11, %rsp # reset stack to base level
		popq %rbx # restore saved rbx
		popq %rbp
		ret

loop_start:
	# get current character
	movzbq (%rbx, %r8, 1), %r9

	cmp $0, %r9 # current character
	je loop_end

	cmp $40, %r9 # current character == '('
	je push_stack

	cmp $91, %r9 # current character == '['
	je push_stack

	cmp $123, %r9 # current character == '{'
	je push_stack

	cmp $60, %r9 # current character == '<'
	je push_stack

	# the character is either ), ], } or >
	cmp $41, %r9 # current character == ')'
	je pop_round

	cmp $93, %r9 # current character == ']'
	je pop_square

	cmp $125, %r9 # current character == '}'
	je pop_curly

	cmp $62, %r9 # current character == '>'
	je pop_angle

	jmp is_invalid # if it's an invalid character

	pop_round:
		popq %r10 # get stack top
		cmp $40, %r10 # stack top == '('
		jne is_invalid

		jmp continue_loop
	
	pop_square:
		popq %r10 # get stack top
		cmp $91, %r10 # stack top == '['
		jne is_invalid

		jmp continue_loop
	
	pop_curly:
		popq %r10 # get stack top
		cmp $123, %r10 # stack top == '{'
		jne is_invalid

		jmp continue_loop
	
	pop_angle:
		popq %r10 # get stack top
		cmp $60, %r10 # stack top == '<'
		jne is_invalid

		jmp continue_loop

	push_stack:
		pushq %r9 # current character
		jmp continue_loop
	
	continue_loop:
		# move to the next character
		incq %r8
		jmp loop_start
	
loop_end:
	cmp %r11, %rsp
	jne is_invalid
	jmp is_valid

main:
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq	$MESSAGE, %rdi		# first parameter: address of the message
	call	check_validity		# call check_validity

	movq %rax, %rdi
	movq $0, %rax
	call printf

	popq	%rbp			# restore base pointer location 
	movq	$0, %rdi		# load program exit code
	call	exit			# exit the program
