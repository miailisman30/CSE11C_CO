
.data

fmt: .asciz "%d"

    #   ASCII table from the man page
    #       2 3 4 5 6 7        30 40 50 60 70 80 90 100 110 120
    #     -------------      ---------------------------------
    #    0:   0 @ P ` p     0:    (  2  <  F  P  Z  d   n   x
    #    1: ! 1 A Q a q     1:    )  3  =  G  Q  [  e   o   y
    #    2: " 2 B R b r     2:    *  4  >  H  R  \  f   p   z
    #    3: # 3 C S c s     3: !  +  5  ?  I  S  ]  g   q   {
    #    4: $ 4 D T d t     4: "  ,  6  @  J  T  ^  h   r   |
    #    5: % 5 E U e u     5: #  -  7  A  K  U  _  i   s   }
    #    6: & 6 F V f v     6: $  .  8  B  L  V  `  j   t   ~
    #    7: ' 7 G W g w     7: %  /  9  C  M  W  a  k   u  DEL
    #    8: ( 8 H X h x     8: &  0  :  D  N  X  b  l   v
    #    9: ) 9 I Y i y     9: '  1  ;  E  O  Y  c  m   w
    #    A: * : J Z j z
    #    B: + ; K [ k {
    #    C: , < L \ l |
    #    D: - = M ] m }
    #    E: . > N ^ n ~
    #    F: / ? O _ o DEL

# this is a lookup table
# we put 0 for non parenthesis
# 1 for opening parenthesis
# and 2 for closing parenthesis
bracket_type:
  .fill 40, 1, 0
  .byte 1           # 40 '('
  .byte 2           # 41 ')'
  .fill 18, 1, 0
  .byte 1           # 60 '<'
  .fill 1, 1, 0
  .byte 2           # 62 '>'
  .fill 28, 1, 0
  .byte 1           # 91 '['
  .fill 1, 1, 0
  .byte 2           # 93 ']'
  .fill 29, 1, 0
  .byte 1           # 123 '{'
  .fill 1, 1, 0
  .byte 2           # 125 '}'
  .fill 130, 1, 0
# important observation:
# to get the closing brace we
# SUBTRACT 2 from the opening brace code
# BUT, for the round parenthesis you need to subtract 1
# so must do a special case that "if code is 41 then check for 40"

.text
.include "basic.s"
.global main

# input
# %rdi = MESSAGE pointer start

# local
# %rdx = current character read from message

# out
# RAX: 0 if valid sequence, 1 if not valid
# RDI: MESSAGE pointer directly after sequence
_check_validity_sequence:
	# prologue
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

    movq $0, %rax           # init 0 return value (correct sequence return value)

# will use the stack to keep open parenthesis
    loop:
# check if current character is a parenthesis
        movzbq (%rdi), %rdx             # read the character byte into rdx (forced because of pushq only)
        incq %rdi                       # move to next char 

# use the lookup table to check what the character is
# 1 = opening 
# 2 = closing
# 0 = not parenthesis
        movzbq bracket_type(%rdx), %rsi   # load lookup into rsi

        cmpq $1, %rsi                   # jump to paren_open if open
        je paren_open
        cmpq $2, %rsi                   # jump to paren_close if closed 
        je paren_closed
        # do nothing if not a paren
        # but check if the sequence terminated
        # not_paren:
            cmpq $0, %rdx   # if is null char then break loop
            je e_loop
            jmp loop            # continue

        paren_open:
            pushq %rdx      # push paren
            jmp loop        # continue
        paren_closed:
# need to find value of parenthesis open counterpart by subtracting 2
# if round parenthesis hardcode -1. haha
            cmpq $41, %rdx  # 41 = ')'
            je round_p
            subq $2, %rdx
            jmp e_round_p
            round_p:
                subq $1, %rdx
            e_round_p:
# now we have expected closed paren value in rdx which we need to confirm is the last stack value
# if the value on the stack is not this then the sequence is wrong
            cmpq %rdx, (%rsp)   # confirm open paren of same type 
            jne bad 
            # good
                addq $8, %rsp   # delete the open paren because we found the matching pair
                jmp loop        # loop
            bad:
# we got a bad sequence! return 1
                movq $1, %rax
                jmp e_loop      # exit loop (optional jump)
    e_loop:

	# epilogue
	movq	%rbp, %rsp		# clear local variables from stack
	popq	%rbp			# restore base pointer location 
	ret

# *******************************************************************************************
# Subroutine: check_validity                                                                *
# Description: checks the validity of the parenthesization of multiple strings,             *
#              as defined in Assignment 5.                                                  *
# Parameters:                                                                               *
#   first: the first string that should be checked                                          *
#   return: the number of strings that were considered invalid                              *
# *******************************************************************************************

# this does multiple sequences separated by null terminator (zero byte)
# input:
# rdi: start of message
# local:
# rbx: accumulator of wrong sequences
check_validity:
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

# save callee saved
    pushq %rbx
    movq $0, %rbx   # init with 0

    seq_loop:
# rdi starts at beginning of message and next loops is at the next sequence
        call _check_validity_sequence
# this call advances the iterator and returns 1 if there was an error 
        addq %rax, %rbx     # increment by one if worng sequence
        cmpq $0, (%rdi)     # if character right after sequence is another null char then we reached eof 
        je e_seq_loop
        jmp seq_loop
    e_seq_loop:
    
    movq %rbx, %rax         # return

# return callee saved
    popq %rbx

	movq    %rbp, %rsp  	# clear local variables from stack
	popq	%rbp			# restore base pointer location 
    ret

main:
	pushq	%rbp 			# push the base pointer (and align the stack)
	movq	%rsp, %rbp		# copy stack pointer value to base pointer

	movq	$MESSAGE, %rdi		# first parameter: address of the message
	call	check_validity		# call check_validity

    movq    $fmt, %rdi
    movq    %rax, %rsi
    movq    $0, %rax
    call    printf

	popq	%rbp			# restore base pointer location 
	movq	$0, %rdi		# load program exit code
	call	exit			# exit the program

