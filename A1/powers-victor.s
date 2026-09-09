.data
scan_fmt: .asciz "%lu"
base: .asciz "Base: "
base_val: .quad 0
power: .asciz "Power: "
power_val: .quad 0
result: .asciz "%lu to the power %lu is %lu!"
result_val: .quad 0

.text
.global main
main:
    pushq %rbp
    movq %rsp, %rbp
    
# read base
    movq $base, %rdi
    movq $0, %rax
    call printf

    movq $scan_fmt, %rdi
    movq $base_val, %rsi
    movq $0, %rax
    call scanf

# read power
    movq $power, %rdi
    movq $0, %rax
    call printf

    movq $scan_fmt, %rdi
    movq $power_val, %rsi
    movq $0, %rax
    call scanf

# calculate power
    movq base_val, %rdi
    movq power_val, %rsi
    call pow
    movq %rax, result_val

# print result
    movq $result, %rdi
    movq base_val, %rsi
    movq power_val, %rdx
    movq result_val, %rcx
    movq $0, %rax
    call printf

    mov $0, %rax
    movq %rbp, %rsp
    popq %rbp
    ret

# --- power ---
# Description: Returns RDI to the power of RSI. 
# Arguments:
#   %rdi: base
#   %rsi: exponent
# --- End power ---
pow:
    pushq %rbp
    movq %rsp, %rbp

    # do the multiplication rsi times
    movq $1, %rax
    power_loop:
        cmpq $0, %rsi
        jle power_loop_end

        mulq %rdi
        decq %rsi

        jmp power_loop
    power_loop_end:
    
    movq %rbp, %rsp
    popq %rbp
    ret
    
    
