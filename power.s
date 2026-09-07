
.data 
name1: .asciz "Lisman Mihai Theodor"
name2: .asciz "Macarie Victor Daniel"
netID1: .asciz "mlisman"
netID2: .asciz "victormacarie"

.section .rodata
fmt: .asciz "Name: %s, NetID: %s \n Name: %s, NetID: %s \n"

.text

.global main

main:
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rax
    movq $fmt, %rdi
    movq $name1, %rsi
    movq $netID1, %rdx
    movq $name2, %rcx
    movq $netID2, %r8
    call printf

    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    ret


