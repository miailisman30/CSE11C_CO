.section .bss
.global DECODED
DECODED:
    .space 2048


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

    movq $DECODED, %r8  # set DECODED index to 0
    movq %rdi, %rsi     # current address is rsi
    m_block:            # do this for each block

        movl 2(%rsi), %edx # next (as offset from original address)
        movb 1(%rsi), %ch  # times to print
        movb 0(%rsi), %cl  # char to print

        print_l: # print ch times
            cmpb $0, %ch
            jle e_print_l

            # append to buffer
            movb %cl, (%r8) # use parenthesis so you dont move into register but at the address the register holds!!!!
            incq %r8

            decb %ch        # decrement loop
            
            jmp print_l
        e_print_l:
        
        # exit loop if arrived on block 0 again
        cmpl $0, %edx  
        je e_m_block

        # go to next block
        shlq $3, %rdx   # multiply next by 8
        addq %rdi, %rdx # add the original address
        movq %rdx, %rsi # assign to current block indexer
        
        jmp m_block
    e_m_block:
    movb $0, (%r8) # ensure termination char

    # print the decoded string
    movq $DECODED, %rdi
    movq $0, %rax
    call printf

	# epilogue
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


