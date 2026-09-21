.data
scanq: .asciz "Number to factorialize: "
scan_fmt: .asciz "%lu"
fmt: .asciz "%lu! is equal to %lu"
number: .quad 3 # this is default val in case ran without shell

.text
.global main


main:
    # prelude
    pushq %rbp
    movq %rsp, %rbp

    # get input
    movq $scanq, %rdi
    movq $0, %rax
    call printf
    
    movq $scan_fmt, %rdi
    movq $number, %rsi
    movq $0, %rax
    call scanf


    # make the call
    movq $0, %rax
    movq number, %rdi
    call factorial

    # print result
    movq %rax, %rdx
    movq number, %rsi
    movq $fmt, %rdi
    movq $0, %rax
    call printf

    movq $0, %rax
    # epilogue
    movq %rbp, %rsp
    popq %rbp
    ret


/*
Description: Calculates the n-th factorial number.
Arguments: %rdi is n-th number

Note: using stack for fun instead of registers
*/

# this is just a setup function
factorial:
    # prelude
    pushq %rbp
    movq %rsp, %rbp

    # supply stack arguments and call
    sub $8, %rsp    # for stack alignment advance stack by 8
    pushq $2        # nc
    pushq $1        # n1
    pushq %rdi      # nf
    call _factorial

    # epilogue
    movq %rbp, %rsp
    popq %rbp
    ret



# denoting stack offsets here for clarity
nf = 16 # when to end
n1 = 24 # accumulator
nc = 32 # current number

# this is the actual recursing function
_factorial:
    # prelude
    pushq %rbp
    movq %rsp, %rbp

    # end if current number is end number
    movq nf(%rbp), %rax # need at least one register passed into cmp
    cmpq %rax, nc(%rbp)
    jg end  # if nc<nf contiune, else end

    # calculate next number
    movq n1(%rbp), %rax # need register %rax for mul
    movq nc(%rbp), %rdi
    mulq %rdi
    # %rax is n3 now

    # supply next arguments
    sub $8, %rsp    # for stack alignment advance stack by 8
    pushq nc(%rbp)  # nc
    incq (%rsp)     # increment nc
    pushq %rax      # n1
    pushq nf(%rbp)  # nf
    call _factorial
    
    jmp done # dont put in rax (optional jump)
    end:
        movq n1(%rbp), %rax # return value
    done:
    # epilogue
    movq %rbp, %rsp
    popq %rbp
    ret

