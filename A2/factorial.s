.data 
n: .quad 0
fmt1: .asciz "%ld"
fmt2: .asciz "The factorial of the number is: %ld \n"

.text

factorial:
    pushq %rbp
    movq %rsp, %rbp

    # redundant movq $1, %rax

 # this solution is with a for loop
 
/* loop:
        cmpq $1, %rdi
        jle end

        imulq %rdi, %rax
        decq %rdi

        jmp  loop
    
*/

# Now with a recursive implementation

    cmpq $1, %rdi
    jle base_case
    
    pushq %rdi
    decq %rdi
    call factorial 
    popq %rdi

    imulq %rdi, %rax
    jmp end
    

    base_case:
        movq $1, %rax

    end:
        popq %rbp
        ret

.global main
    
main:
    pushq %rbp
    movq %rsp, %rbp

    movq $0, %rax
    movq $n, %rsi
    movq $fmt1, %rdi
    call scanf

    movq $0, %rax
    movq n, %rdi
    call factorial

    movq %rax, %rsi
    movq $fmt2, %rdi
    movq $0, %rax
    call printf

    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    ret


