.text
file_args_error_msg: .asciz "Missing operands: FILES.\nMake sure you follow the following format:\n%s <fileName>.txt <fileName>.txt [-i -b]\n"
reading_error_msg: .asciz "The program encountered an error when trying to read from the files.\nMake sure you are providing the names of two .txt files stored in this directory as command line arguments, and following the format:\n%s <fileName>.txt <fileName>.txt [-i -b]\n"
flag_error_msg: .asciz "Unexpected option encountered.\nThis implementation of diff only supports -i and -b.\nMake sure you follow the following format:\n%s <fileName>.txt <fileName>.txt [-i -b]\n"

.global main

main:
	pushq %rbp
	movq %rsp, %rbp
	pushq %r12
	pushq %rbx
	subq $32, %rsp				# reserve 32B on stack (file reading writes -> read_bytes1, file1_content_address, read_bytes2, file2_content_address)

	movq %rdi, %r12				# R12 = argc
	movq %rsi, %rbx				# RBX = argv[]

	# Program needs at least three arguments (programName, file1, file2)
	cmpq $3, %rdi
	jl not_enough_args

	# Check for -i and -b flags (note: RDI and RSI *already* have argc and argv, respectively)
	call check_flags
	cmpq $4, %rax
	jge flags_failed_ext
	movq %rax, %r12				# R12 = check_flags return

	# Read file 1
	movq 8(%rbx), %rdi
	leaq -24(%rbp), %rsi	# read_bytes amount in -24(RBP)
	call read_file

	test %rax, %rax
	jz read_files_failed
	movq %rax, -32(%rbp)	# pointer to file1 in -32(RBP)

	# Read file 2
	movq 16(%rbx), %rdi
	leaq -40(%rbp), %rsi  # read_bytes amount in -40(RBP)
	call read_file

	test %rax, %rax
	jz read_files_failed
	movq %rax, -48(%rbp)	# pointer to file2 in -48(RBP)
	
	# Call you diff subroutine
	movq -32(%rbp), %rdi	# pointer to first file's contents
	movq -48(%rbp), %rsi	# pointer to second file's contents

	movq %r12, %rdx	
	andq $1, %rdx					# boolean for -i
	movq %r12, %rcx
	andq $2, %rcx
	shrq $1, %rcx					# boolean for -b

	call diff

	# Free memory from file 1
	movq -32(%rbp), %rdi
	call free

	# Free memory from file 2
	movq -48(%rbp), %rdi
	call free

epilogue:
	addq $32, %rsp
	popq %rbx
	popq %r12
	movq %rbp, %rsp
	popq %rbp

	xorq %rdi, %rdi
	call exit

not_enough_args:
no_file_names_found:
	movq $file_args_error_msg, %rdi
	jmp print_error_ext
read_files_failed:
	movq $reading_error_msg, %rdi
print_error_ext:
	movq (%rbx), %rsi
	xorq %rax, %rax
	call printf
	jmp exit_main

flags_failed_ext:
	movq $flag_error_msg, %rdi
	movq (%rbx), %rsi
	xorq %rax, %rax
	call printf

exit_main:
	addq $32, %rsp
	popq %rbx
	popq %r12
	movq %rbp, %rsp
	popq %rbp

	movq $2, %rdi
	call exit
