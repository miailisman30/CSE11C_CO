.data
fmt: .asciz "%c"
fmt_csi: .asciz "\x1B[38;5;%d;48;5;%dm"
fmt_eff_csi: .asciz "\x1B[%dm"



.text

.include "final.s"

.global main

foreground = 6
background = 7
next_block = 2
print_times = 1
character = 0


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
    pushq %r14
    pushq %r15
    subq $8, %rsp          # 16-byte allignment needed

    movq %rdi, %r14        # current block address
    movq %rdi, %r15        # original address of the message

    lblock:
        # arguments for the color/effect escape
        movzbq background(%r14), %rcx
        movzbq foreground(%r14), %rdx

        cmpq %rcx, %rdx
        jne bgfg

            cmpq $0, %rcx
            je reset
            cmpq $26, %rcx
            je stop_blink
            cmpq $42, %rcx
            je bold
            cmpq $66, %rcx
            je faint
            cmpq $105, %rcx
            je conceal
            cmpq $153, %rcx
            je reveal
            cmpq $182, %rcx
            je blink

            reset:
                movq $0, %rdx
                jmp special_eff
            stop_blink:
                movq $25, %rdx
                jmp special_eff
            bold:
                movq $1, %rdx
                jmp special_eff
            faint:
                movq $2, %rdx
                jmp special_eff
            conceal:
                movq $8, %rdx
                jmp special_eff
            reveal:
                movq $28, %rdx
                jmp special_eff
            blink:
                movq $5, %rdx
                jmp special_eff

            special_eff:
                movq $fmt_eff_csi, %rdi
                movq %rdx, %rsi
                movq $0, %rax
                call printf
                jmp e_bgfg

            bgfg:
                movq $fmt_csi, %rdi
                movq %rdx, %rsi    # foreground
                movq %rcx, %rdx    # background
                movq $0, %rax
                call printf
            e_bgfg:

        movzbl print_times(%r14), %r12d  # find how many times we print
        movzbq character(%r14), %r13     # find letter

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

        movl next_block(%r14), %ebx
        cmpq $0, %rbx
        je end

        shlq $3, %rbx
        addq %r15, %rbx
        movq %rbx, %r14
        jmp lblock

    end:

	# epilogue
    addq $8, %rsp
    popq %r15
    popq %r14
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

