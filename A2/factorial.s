.data 
n: .quad 0
fmt1: .asciz "%ld"
fmt2: .asciz "The factorial of the number is: %ld \n"
name1: .asciz "Lisman Mihai Theodor"
name2: .asciz "mlisman"
netID1: .asciz "victormacarie"
fmt3: .asciz "Enter base: \n"
fmt4: .asciz "Enter exponent: \n"
base: .quad 0
exp: .quad 0
.section .rodata
fmt: .asciz "Name: %s, NetID: %s \n Name: %s, NetID: %s \n"]

.text

factorial:
    pushq %rbp          # Push the base pointer
    movq %rsp, %rbp     # copy stack pointer val to base pointer

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

    cmpq $1, %rdi       # Compare our exponent to 1, in this case rdi = exponent
    jle base_case       # If less or equal, jump to base case
    
    pushq %rdi          # Push the rdi register value
    decq %rdi           # Decrement it
    call factorial      # Call the function inside itself for recursivity
    popq %rdi           # Pop the rdi register

    imulq %rdi, %rax    # Multiply rdi with rax
    jmp end             # Jump to the end
    

    base_case:
        movq $1, %rax   # value 1 moved to rax => end of function

    end:
        popq %rbp       # Pop the base pointer
        ret             # Return

.global main
    
main:
    pushq %rbp          # Push the base pointer
    movq %rsp, %rbp     # copy stack pointer value to base pointer

    movq $0, %rax       # no vector registers in use for scanf
    movq $n, %rsi       # first parameter: our number n
    movq $fmt1, %rdi    # second parameter, our format
    call scanf          # call scanf to read input

    movq $0, %rax       # clear rax, first parameter 0
    movq n, %rdi        # parameter n
    call factorial      # call factorial subroutine

    movq %rax, %rsi     # first parameter
    movq $fmt2, %rdi    # second parameter
    movq $0, %rax       # no vector registers in use for printf
    call printf         # call printf

    movq $0, %rax       # clear rax register
    movq %rbp, %rsp     # copy stack pointer value to base pointer
    popq %rbp           # pop base pointer
    ret                 # Return


