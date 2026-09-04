

.global main

main: 
    pushq %rbp
    movq %rsp, %rbp
        
    movq $60, %rax
    movq $42, %rdi
    call printf
    syscall

    movq %rbp, %rsp
    pop %rbp
