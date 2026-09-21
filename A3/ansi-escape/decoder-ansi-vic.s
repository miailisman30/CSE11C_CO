
.section .rodata
fmt_decoded: .asciz "%s"
fmt_csi: .asciz "\x1B[38;5;%d;48;5;%dm"

.text
.include "final.s"
.global main

foreground = 7
background = 6
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

    movq $0, %r12       # decoded buffer pointer
    movq $0, %r13       # block offset
    movq %rdi, %r14     # encoded message address


# allocate heap memory for decoded message
    subq $8, %rsp       # align
    movq $32768, %rdi   # amount to request
    call malloc         # %RAX is heap buffer now
    # addq $8, %rsp       # dealign


   
    l_block:
# arguments for sprintf to add ansi escape sequence
        movq background(%), %rcx    # parameter %d 2: background
        movq foreground(%rbp), %rdx # parameter %d 1: foreground
        movq $fmt_csi, %rsi         # fmt string
        movq %r8, %rdi              # current buffer pointer
        
        call sprintf





# return callee saved registers
    popq %r14
    popq %r13
    popq %r12
    
    movq %rbp, %rsp
    popq %rbp
    ret

main:
    pushq %rbp
    movq %rsp, %rbp

    movq $MESSAGE, %rdi
    movq $0, %rax
    call decode
# print result
    movq $fmt_decoded, %rdi
    movq %rax, %rsi
    movq $0, %rax
    call printf


    popq %rbp
    movq %rax, %rdi
    call exit
