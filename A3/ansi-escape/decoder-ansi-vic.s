
.section .rodata
fmt_decoded: .asciz "%s"
fmt_csi: .asciz "\x1B[38;5;%d;48;5;%dm"

.text
.include "final.s"
.global main

foreground = 6
background = 7
next_block = 2
print_times = 1
character = 0

message = -8
decode:
    pushq %rbp
    movq %rsp, %rbp

# save callee saved registers
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    movq %rdi, %r14     # CURRENT address for block
    movq %rdi, %r15     # original address of encoded message

# allocate heap memory for decoded message
    movq $3276800, %rdi   # amount to request
    call malloc         # %RAX is heap buffer now

    movq %rax, %r12     # decoded buffer pointer
    movq %rax, %r13     # CURRENT decoded buffer pointer
    

    lblock:
# arguments for sprintf to add ansi escape sequence
        movzbq background(%r14), %rcx     # parameter %d 2: background
        movzbq foreground(%r14), %rdx     # parameter %d 1: foreground
        movq $fmt_csi, %rsi             # fmt string
        movq %r13, %rdi                 # current buffer pointer
        
        call sprintf                # rax is amount written

        addq %rax, %r13              # increment buffer


# "decoding" the characters in the block
        movzbq print_times(%r14), %rcx
        dec_block:
# stop printing character if no more
            cmpq $0, %rcx
            jle e_dec_block

# print character
            movzbq character(%r14), %rdx
            movb %dl, (%r13)                # write to buffer
            incq %r13                       # increment buffer pointer


            decq %rcx                       # decrement loop
            jmp dec_block
        e_dec_block:


        #movq next_block(%r14), %rcx # place next block offset in rcx
        movl next_block(%r14), %ecx
# exit loop if arrived on block 0 again
        cmpq $0, %rcx
        je e_lblock

# move to next block
        shlq $3, %rcx               # multiply next block offset by 8
        addq %r15, %rcx             # add the starting address of the encoded message
        movq %rcx, %r14             # change current block address

        jmp lblock      # loop
    e_lblock:

    
# null terminate and return
    movq $0, (%r13)
    movq %r12, %rax


# return callee saved registers
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    
    movq %rbp, %rsp
    popq %rbp
    ret

main:
    pushq %rbp
    movq %rsp, %rbp

    subq $8, %rsp
    pushq %rbx


    movq $MESSAGE, %rdi
    movq $0, %rax
    call decode
    movq %rax, %rbx # place into rbx
# print result
    movq $fmt_decoded, %rdi
    movq %rbx, %rsi
    movq $0, %rax
    call printf

# free
    movq %rbx, %rdi
    call free


    addq $8, %rsp
    popq %rbp

    movq $0, %rax
    movq %rax, %rdi
    call exit
