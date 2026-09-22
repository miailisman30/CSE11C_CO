
.data
fmt_decoded: .asciz "%s"
fmt_csi: .asciz "\x1B[38;5;%d;48;5;%dm"
fmt_eff_csi: .asciz "\x1B[%dm"
fmt_test: .asciz "\x1B[3%d;4%dm"

.text
.include "abc_sorted.s"

.global main

foreground = 6
background = 7
next_block = 2
print_times = 1
character = 0

# effect marker values if (fg == bg) 
stop_blink_code = 26
bold_code = 42
faint_code = 66
conceal_code = 105
reveal_code = 153
blink_code = 182

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
    movq $3276, %rdi   # amount to request
    call malloc         # %RAX is heap buffer now

    movq %rax, %r12     # decoded buffer pointer
    movq %rax, %r13     # CURRENT decoded buffer pointer
    

    lblock:
# arguments for sprintf to add ansi escape sequence
        movzbq background(%r14), %rcx     # parameter %d 2: background
        movzbq foreground(%r14), %rdx     # parameter %d 1: foreground

# if equal then write special effect csi
        cmpq %rcx, %rdx
        jne bgfg


        # special effects
            cmpq $0, %rcx
            je reset
            cmpq $stop_blink_code, %rcx
            je stop_blink
            cmpq $bold_code, %rcx
            je bold
            cmpq $faint_code, %rcx
            je faint
            cmpq $conceal_code, %rcx
            je conceal
            cmpq $reveal_code, %rcx
            je reveal
            cmpq $blink_code, %rcx
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

            movq $fmt_eff_csi, %rsi             # fmt string
            movq %r13, %rdi                 # current buffer pointer
        
            call sprintf                # rax is amount written

            addq %rax, %r13              # increment buffer

            jmp e_bgfg # dont change bgfg

        bgfg:
        # bg/fg change
            movq $fmt_csi, %rsi             # fmt string
            movq %r13, %rdi                 # current buffer pointer
        
            call sprintf                # rax is amount written

            addq %rax, %r13              # increment buffer
        e_bgfg:

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

# testing bullshit
    #   movb $27, (%r13)
    #   incq %r13
    #   movb $'[', (%r13)
    #   incq %r13
    #   movq $'0', (%r13)
    #   incq %r13
    #   movb $'m', (%r13)
    #   incq %r13

    
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
