.globl my_printf
.globl miai_printf
.section .rodata
.Lnull_str:
    .asciz "(null)"
.Lminus_char:
    .byte '-'
.Ldot_char:
    .byte '.'
.text
.type my_printf, @function
.type miai_printf, @function
# SysV: RDI = format; RSI, RDX, RCX, R8, R9 = first five values.
# Further values occupy 8-byte stack slots. FP8 is passed as integer bits.
# Returns the formatted byte count (assuming successful writes).
my_printf:
miai_printf:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    # 0..39: saved arguments; 40..42: fraction digits;
    # 48: signed magnitude / float integer part; 56: float fraction.
    # RSP is 16-byte aligned before every call.
    subq $72, %rsp
    movq %rsi, 0(%rsp)
    movq %rdx, 8(%rsp)
    movq %rcx, 16(%rsp)
    movq %r8, 24(%rsp)
    movq %r9, 32(%rsp)
    movq %rsp, %r13          # saved register arguments
    movq %rdi, %rbx          # format cursor
    xorq %r12, %r12          # byte count
    xorq %r15, %r15          # argument index
    leaq 16(%rbp), %r14      # next stack argument
.Lloop:
    movb (%rbx), %al
    testb %al, %al
    jz .Ldone
    cmpb $'%', %al
    je .Lpercent
    movq %rbx, %rdi
    call write_one
    addq %rax, %r12
    incq %rbx
    jmp .Lloop
.Lpercent:
    movb 1(%rbx), %al
    testb %al, %al
    jz .Ltrailing
    cmpb $'%', %al
    je .Lescape
    cmpb $'s', %al
    je .Largument
    cmpb $'u', %al
    je .Largument
    cmpb $'d', %al
    je .Largument
    cmpb $'f', %al
    je .Largument
    # Unknown specifiers are printed literally and consume no argument.
    movq %rbx, %rdi
    movq $2, %rsi
    call write_mem
    addq %rax, %r12
    addq $2, %rbx
    jmp .Lloop
.Lescape:
    movq %rbx, %rdi
    call write_one
    addq %rax, %r12
    addq $2, %rbx
    jmp .Lloop
.Ltrailing:
    movq %rbx, %rdi
    call write_one
    addq %rax, %r12
    jmp .Ldone
.Largument:
    # Fetch once for all recognized specifiers; AL still holds the letter.
    cmpq $5, %r15
    jb .Lregister_arg
    movq (%r14), %rdi
    addq $8, %r14
    jmp .Ldispatch
.Lregister_arg:
    movq (%r13,%r15,8), %rdi
.Ldispatch:
    incq %r15
    cmpb $'s', %al
    je .Lperc_s
    cmpb $'u', %al
    je .Lperc_u
    cmpb $'d', %al
    je .Lperc_d
    jmp .Lperc_f
.Lperc_s:
    movq %rdi, %r10
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
    movq %r10, %rdi
    movq %rcx, %rsi
    call write_mem
    addq %rax, %r12

.Ls_empty:
    addq $2, %rbx
    jmp .Lloop
.Lperc_u:
    call print_u64
    addq %rax, %r12
    addq $2, %rbx
    jmp .Lloop
.Lperc_d:
    # The argument is always signed 64-bit, never a promoted 32-bit int.
    testq %rdi, %rdi
    jns .Lperc_u
    negq %rdi               # INT64_MIN becomes unsigned magnitude 2^63
    movq %rdi, 48(%rsp)
    leaq .Lminus_char(%rip), %rdi
    call write_one
    addq %rax, %r12
    movq 48(%rsp), %rdi
    jmp .Lperc_u
.Lperc_f:
    # CO-FP8E4M3FNAN: ALL exponents (0..15) are finite and normalized.
    # value = (-1)^sign * (8 + mantissa) * 2^(exponent - 10)
    # magnitude * 1000 = (8 + mantissa) * 125 * 2^(exponent - 7)
    movzbl %dil, %r10d
    movl %r10d, %r9d
    shrl $7, %r9d
    movl %r10d, %ecx
    shrl $3, %ecx
    andl $15, %ecx
    movl %r10d, %edx
    andl $7, %edx
    movl %ecx, %r11d
    movq %rdx, %rax
    addq $8, %rax
    imulq $125, %rax
    cmpl $7, %r11d
    jae .Lf_scale_up
    # Divide by 2^(7-exponent), adding half the divisor to round up ties.
    movl $7, %ecx
    subl %r11d, %ecx
    movq $1, %r11
    shlq %cl, %r11
    movq %r11, %rcx
    shrq $1, %rcx
    addq %rcx, %rax
    xorl %edx, %edx
    divq %r11
    jmp .Lf_split_decimal

.Lf_scale_up:
    movl %r11d, %ecx
    subl $7, %ecx
    shlq %cl, %rax

.Lf_split_decimal:
    movq $1000, %rcx
    xorl %edx, %edx
    divq %rcx
    movq %rax, 48(%rsp)
    movq %rdx, 56(%rsp)
    testl %r9d, %r9d
    jz .Lf_no_sign
    leaq .Lminus_char(%rip), %rdi
    call write_one
    addq %rax, %r12

.Lf_no_sign:
    movq 48(%rsp), %rdi
    call print_u64
    addq %rax, %r12
    leaq .Ldot_char(%rip), %rdi
    call write_one
    addq %rax, %r12
    movq 56(%rsp), %rax
    movq $100, %rcx
    xorl %edx, %edx
    divq %rcx
    movq %rax, %r10
    movq %rdx, %rax
    movq $10, %rcx
    xorl %edx, %edx
    divq %rcx
    addq $'0', %r10
    addq $'0', %rax
    addq $'0', %rdx
    movb %r10b, 40(%rsp)
    movb %al, 41(%rsp)
    movb %dl, 42(%rsp)
    leaq 40(%rsp), %rdi
    movq $3, %rsi
    call write_mem
    addq %rax, %r12
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
# ---- SysV-compliant helpers (args in RDI/RSI/RDX, only caller-saved touched) ----
.type write_mem, @function
write_mem:                    # RDI=ptr RSI=len -> RAX=len
    pushq %rsi
    movq %rsi, %rdx
    movq %rdi, %rsi
    movq $1, %rax
    movq $1, %rdi
    syscall
    popq %rax
    ret
.type write_one, @function
write_one:                    # RDI=ptr -> RAX=1
    movq $1, %rsi
    jmp write_mem             # tail call; reuse the caller's return address
.type print_u64, @function
print_u64:                    # RDI=value -> RAX=len (writes decimal)
    subq $40, %rsp
    movq %rdi, %rax
    leaq 32(%rsp), %r8
    movq %r8, %r9
    movq $10, %rcx
.Ldecimal_digit:
    # Build backwards; run at least once so zero produces a digit too.
    xorl %edx, %edx
    divq %rcx
    addb $'0', %dl
    decq %r9
    movb %dl, (%r9)
    testq %rax, %rax
    jnz .Ldecimal_digit
    movq %r9, %rdi
    movq %r8, %rsi
    subq %r9, %rsi
    call write_mem
    addq $40, %rsp
    ret

# Standalone example for ld --entry main. No C runtime is involved.
.section .rodata
.Lexample_format:
    .asciz "%s: %u %d | %f %f %f %f | %% %q\n"
.Lexample_name:
    .asciz "Piet"
.text
.globl main
.type main, @function
main:
    pushq %rbp
    movq %rsp, %rbp
    # Process entry starts aligned; the prologue pushed 8 bytes.
    andq $-16, %rsp

    # Seven values: five in registers, then two on the stack in reverse order.
    pushq $0x24              # 0.188 (rounded from 0.1875)
    pushq $0xff              # -480.000
    leaq .Lexample_format(%rip), %rdi
    leaq .Lexample_name(%rip), %rsi
    movq $42, %rdx
    movq $-42, %rcx
    movq $0x00, %r8          # 0.008 (exponent 0 is normalized)
    movq $0x78, %r9          # 256.000 (exponent 15 is finite)
    xorl %eax, %eax          # no vector-register arguments
    call my_printf
    addq $16, %rsp

    movq $60, %rax           # exit(0); process entry cannot return with ret
    xorl %edi, %edi
    syscall

# Linker metadata: this program does not require an executable stack.
.section .note.GNU-stack,"",@progbits
