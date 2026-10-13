.globl my_printf
.globl miai_printf
.section .rodata
.Lnull_str:
    .asciz "(null)"
.Linf_str:
    .asciz "inf"
.Lnan_str:
    .asciz "nan"
.Lminus_char:
    .byte 45
.Ldot_char:
    .byte 46
.text
.type my_printf, @function
.type miai_printf, @function
my_printf:
miai_printf:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $72, %rsp
    movq %rsi, 32(%rsp)
    movq %rdx, 40(%rsp)
    movq %rcx, 48(%rsp)
    movq %r8, 56(%rsp)
    movq %r9, 64(%rsp)
    leaq 32(%rsp), %r13      # save base == buffer end
    movq %rdi, %rbx          # fmt
    xorq %r12, %r12          # count
    xorq %r15, %r15          # gp index
    leaq 16(%rbp), %r14      # stack args
.Lloop:
    movb (%rbx), %al
    testb %al, %al
    jz .Ldone
    cmpb $0x25, %al
    je .Lpercent
    movq %rbx, %rsi
    call write_one
    incq %rbx
    jmp .Lloop
.Lpercent:
    movb 1(%rbx), %al
    testb %al, %al
    jz .Ltrailing
    cmpb $0x25, %al
    je .Lescape
    cmpb $0x73, %al
    je .Lperc_s
    cmpb $0x75, %al
    je .Lperc_u
    cmpb $0x64, %al
    je .Lperc_d
    cmpb $0x66, %al
    je .Lperc_f
    movq %rbx, %rsi
    movq $2, %rdx
    call write_mem
    addq $2, %rbx
    jmp .Lloop
.Lescape:
    movq %rbx, %rsi
    call write_one
    addq $2, %rbx
    jmp .Lloop
.Ltrailing:
    movq %rbx, %rsi
    call write_one
    jmp .Ldone
.Lperc_s:
    call fetch_arg
    movq %rax, %r10
    testq %r10, %r10
    jnz .Ls_notnull
    leaq .Lnull_str(%rip), %r10

.Ls_notnull:
    movq %r10, %r11
    xorq %rcx, %rcx

.Ls_len:
    movb (%r11), %al
    testb %al, %al
    jz .Ls_gotlen
    incq %r11
    incq %rcx
    jmp .Ls_len

.Ls_gotlen:
    testq %rcx, %rcx
    jz .Ls_empty
    movq %r10, %rsi
    movq %rcx, %rdx
    call write_mem

.Ls_empty:
    addq $2, %rbx
    jmp .Lloop
.Lperc_u:
    call fetch_arg
    call print_u64
    addq $2, %rbx
    jmp .Lloop
.Lperc_d:
    call fetch_arg
    movq %rax, %r10
    shrq $32, %r10
    testq %r10, %r10
    jnz .Ld_keep
    testl %eax, %eax
    jns .Ld_keep
    movslq %eax, %rax

.Ld_keep:
    testq %rax, %rax
    jns .Ld_pos
    movq %rax, %r10
    leaq .Lminus_char(%rip), %rsi
    call write_one
    movq %r10, %rax
    negq %rax

.Ld_pos:
    call print_u64
    addq $2, %rbx
    jmp .Lloop
.Lperc_f:
    call fetch_arg
    movzbl %al, %r10d
    movl %r10d, %r9d
    shrl $7, %r9d
    movl %r10d, %ecx
    shrl $3, %ecx
    andl $15, %ecx
    movl %r10d, %edx
    andl $7, %edx
    cmpl $15, %ecx
    je .Lf_exp15
    testl %ecx, %ecx
    jnz .Lf_norm
    testl %edx, %edx
    jz .Lf_zero
    movq %rdx, %rax
    movq $125, %rcx
    imulq %rcx, %rax
    addq $32, %rax
    movq $64, %rcx
    xorl %edx, %edx
    divq %rcx
    movq %rax, %r10
    jmp .Lf_have_thou

.Lf_zero:
    xorq %r10, %r10
    jmp .Lf_have_thou

.Lf_norm:
    movl %ecx, %r11d
    movq %rdx, %rax
    addq $8, %rax
    movq $125, %rcx
    imulq %rcx, %rax
    cmpl $7, %r11d
    jae .Lf_ge7
    movl $7, %ecx
    subl %r11d, %ecx
    movq $1, %r11
    shlq %cl, %r11
    movq %r11, %rcx
    shrq $1, %rcx
    addq %rcx, %rax
    xorl %edx, %edx
    movq %r11, %rcx
    divq %rcx
    movq %rax, %r10
    jmp .Lf_have_thou

.Lf_ge7:
    movl %r11d, %ecx
    subl $7, %ecx
    shlq %cl, %rax
    movq %rax, %r10
    jmp .Lf_have_thou

.Lf_exp15:
    testl %edx, %edx
    jz .Lf_is_inf
    testl %r9d, %r9d
    jz .Lf_nan_pos
    leaq .Lminus_char(%rip), %rsi
    call write_one

.Lf_nan_pos:
    leaq .Lnan_str(%rip), %rsi
    movq $3, %rdx
    call write_mem
    addq $2, %rbx
    jmp .Lloop

.Lf_is_inf:
    testl %r9d, %r9d
    jz .Lf_inf_pos
    leaq .Lminus_char(%rip), %rsi
    call write_one

.Lf_inf_pos:
    leaq .Linf_str(%rip), %rsi
    movq $3, %rdx
    call write_mem
    addq $2, %rbx
    jmp .Lloop

.Lf_have_thou:
    movq %r10, %rax
    movq $1000, %rcx
    xorl %edx, %edx
    divq %rcx
    movq %rax, %r10
    movq %rdx, %r8
    testl %r9d, %r9d
    jz .Lf_no_sign
    leaq .Lminus_char(%rip), %rsi
    call write_one

.Lf_no_sign:
    movq %r10, %rax
    call print_u64
    leaq .Ldot_char(%rip), %rsi
    call write_one
    movq %r8, %rax
    movq $100, %rcx
    xorl %edx, %edx
    divq %rcx
    movq %rax, %r10
    movq %rdx, %rax
    movq $10, %rcx
    xorl %edx, %edx
    divq %rcx
    addq $48, %r10
    addq $48, %rax
    addq $48, %rdx
    movb %r10b, -32(%r13)
    movb %al, -31(%r13)
    movb %dl, -30(%r13)
    leaq -32(%r13), %rsi
    movq $3, %rdx
    call write_mem
    addq $2, %rbx
    jmp .Lloop
.Ldone:
    movq %r12, %rax
    addq $72, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
    ret
# ---- subroutines (only touch caller-saved + R12/R14/R15 state) ----
fetch_arg:
    cmpq $5, %r15
    jae 1f
    movq (%r13,%r15,8), %rax
    incq %r15
    ret
1:
    movq (%r14), %rax
    addq $8, %r14
    incq %r15
    ret
write_mem:                  # RSI=ptr RDX=len -> single write, R12+=len
    pushq %rdx
    movq $1, %rax
    movq $1, %rdi
    syscall
    popq %rdx
    addq %rdx, %r12
    ret
write_one:                  # RSI=ptr -> 1 byte, R12++
    movq $1, %rax
    movq $1, %rdi
    movq $1, %rdx
    syscall
    incq %r12
    ret
print_u64:                  # RAX=value -> decimal, uses buffer [R13-32,R13)
    pushq %r8
    pushq %r9
    pushq %r10
    pushq %r11
    movq %r13, %r10
    movq %r10, %r11
    testq %rax, %rax
    jnz 1f
    decq %r11
    movb $48, (%r11)
    jmp 2f
1:
    movq $10, %rcx
3:
    testq %rax, %rax
    jz 2f
    xorl %edx, %edx
    divq %rcx
    addb $48, %dl
    decq %r11
    movb %dl, (%r11)
    jmp 3b
2:
    movq %r11, %rsi
    movq %r10, %rdx
    subq %r11, %rdx
    pushq %rdx
    movq $1, %rax
    movq $1, %rdi
    syscall
    popq %rdx
    addq %rdx, %r12
    popq %r11
    popq %r10
    popq %r9
    popq %r8
    ret
