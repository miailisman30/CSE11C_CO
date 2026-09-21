
.section .rodata
fmt_decoded: .asciz "%s"
fmt_csi: .asciz "\x1B[38;5;%d;48;5;%dm%s"

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

    subq $8, %rsp   # align
    pushq %rdi      # send message argument to stack
# allocate heap memory for decoded message
    movq $32768, %rdi
    call malloc
# %RAX is heap buffer

    l_block:
        movq %r8, %rdi
    

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
