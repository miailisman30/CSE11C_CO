.data
fmt: .asciz "%c"

.text

.include "final.s"

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

    pushq %rbx
    pushq %r12
    pushq %r13
    subq $8, %rsp          # 16-byte allignment needed
    
    movq $0, %rdi
    movq $MESSAGE, %rsi

    main_loop:
        movq $MESSAGE, %rsi
        leaq (%rsi, %rdi, 8), %r8
        movl 2(%r8), %ebx  # 4 bytes to find next block (value)
        movzbl 1(%r8), %r12d 
        movb (%r8), %r13b
        
        inner_loop:
            cmpq $0, %r12
            jle inner_end
            
            movq $0, %rax
            movq $fmt, %rdi
            movl %r13d, %esi
            call printf

            decq %r12
            jmp inner_loop

        inner_end:
        
        
        cmpq $0, %rbx
        jle end

        movl %ebx, %edi
        jmp main_loop
        
    end:
    

        

	# epilogue
    addq $8, %rsp
    popq %r13
    popq %r12
    popq %rbx

	movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret

main:
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq	$MESSAGE, %rdi	# first parameter: address of the message
	call	decode			# call decode

	popq	%rbp			# restore base pointer location 
	movq	$0, %rdi		# load program exit code
	call	exit			# exit the program

