.globl my_printf
.globl miai_printf
.text
.type my_printf, @function
.type miai_printf, @function
# long my_printf(char *fmt) - %RDI=fmt, returns %RAX=bytes printed
my_printf:
miai_printf:
    pushq %rbx
    pushq %r12
    movq %rdi, %rbx
    xorq %r12, %r12

.Lloop:
    movb (%rbx), %al
    testb %al, %al
    jz .Ldone
    cmpb $0x25, %al
    je .Lpercent

.Lnormal:
    movq $1, %rax
    movq $1, %rdi
    movq %rbx, %rsi
    movq $1, %rdx
    syscall
    incq %rbx
    incq %r12
    jmp .Lloop

.Lpercent:
    movb 1(%rbx), %al
    testb %al, %al
    jz .Ltrailing
    cmpb $0x25, %al
    je .Lescape

.Lunknown:
    movq $1, %rax
    movq $1, %rdi
    movq %rbx, %rsi
    movq $2, %rdx
    syscall
    addq $2, %rbx
    addq $2, %r12
    jmp .Lloop

.Lescape:
    movq $1, %rax
    movq $1, %rdi
    movq %rbx, %rsi
    movq $1, %rdx
    syscall
    addq $2, %rbx
    incq %r12
    jmp .Lloop

.Ltrailing:
    movq $1, %rax
    movq $1, %rdi
    movq %rbx, %rsi
    movq $1, %rdx
    syscall
    incq %r12

.Ldone:
    movq %r12, %rax
    popq %r12
    popq %rbx
    ret
