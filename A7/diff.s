.text

.global diff
.global check_flags

#######################################################################
# Subroutine CHECK_FLAGS                                              *
# Check for -i and -b flags in command line arguments                 *
# Parameters: argc, argv                                              *
# Returns:                                                            *
#   0 for no flags                                                    *
#   1 for -i only                                                     *
#   2 for -b only                                                     *
#   3 for both flags                                                  *
#   4 for error (anything else)                                       *
#######################################################################
check_flags:
  pushq %rbp
  movq %rsp, %rbp

  # Your code goes here, good luck!
  # Make sure to return the values as specified above.

  movq %rbp, %rsp
  popq %rbp
  ret


#######################################################################
# Subroutine DIFF                                                     *
# Compare file1 and file2 line by line and print changes to stdout    *
# Parameters:                                                         *
#   - Pointer to contents of file 1                                   *
#   - Pointer to contents of file 2                                   *
#   - Boolean for -i flag                                             *
#   - Boolean for -b flag                                             *
# Returns: 0 if files were equal, 1 otherwise                         *
#######################################################################
diff:
  pushq %rbp
  movq %rsp, %rbp

  # Your code goes here, good luck!

  movq %rbp, %rsp
  popq %rbp
  ret
