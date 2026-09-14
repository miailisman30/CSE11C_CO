
.data 
name1: .asciz "Lisman Mihai Theodor"
name2: .asciz "Macarie Victor Daniel"
netID1: .asciz "mlisman"
netID2: .asciz "victormacarie"
fmt: .asciz "%ld"
fmt1: .asciz "Enter base: \n"
fmt2: .asciz "Enter exponent: \n"
fmt3: .asciz "The result: %ld \n"
base: .quad 0
exp: .quad 0
.section .rodata
fmt: .asciz "Name: %s, NetID: %s \n Name: %s, NetID: %s \n"

.text

power: 
    movq $1, %rax
    loop: 
        cmpq $0, %rsi
        jle end
    
        imulq %rdi, %rax
        decq %rsi
        jmp loop

    end: 
        ret
    
.global main

main:
    pushq %rbp
    movq %rsp, %rbp
    
    movq $0, %rax
    movq $fmt1, %rdi
    call printf
    
    
    movq $base, %rsi
    movq $fmt, %rdi
    movq $0, %rax
    call scanf

    movq $0, %rax
    movq $fmt2, %rdi
    call printf

    movq $exp, %rsi
    movq $fmt, %rdi
    movq $0, %rax
    call scanf

    
    movq $0, %rax
    movq base, %rdi
    movq exp, %rsi
    call power

    
    movq %rax, %rsi
    movq $fmt3, %rdi
    movq $0, %rax
    call printf

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
