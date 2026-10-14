# Diff

These files should help you get started with your diff implementation.
In specific, they take care of the fiddly bit with reading a file.

There are a few files in here for you:

- main.s:
  This file contains the main function. It reads the two files from the command line arguments, calls your check_flags subroutine to process the options and pass it all to your diff implementation. You cannot alter its contents.

- read_file.s:
  Holds a subroutine for reading the contents of a file.
  This subroutine is used by the main function in main.s. You also cannot alter its contents.

- diff.s:
  This is where you should put your diff implementation.
  In it you should define two subroutines:
  1. `check_flags` subroutine that takes two arguments: args amount and args array pointer from the `main` subroutine. It should return 0 for no flags, 1 for -i only, 2 for -b only, 3 for both -i and -b and 4 for error. If you don't follow this, we can't pass the booleans to your `diff` properly.
  2. `diff` subroutine that takes four arguments:
  a pointer to the contents of file1, a pointer to the contents of file2, boolean for -i and boolean for -b. It should output the result to stdout.

- Makefile:
  A file containing compilation information. If you have a working make,
  you can compile the code in this directory by simply running the command `make`.

Feel free to have a look at the different files, but keep in mind that all you need to do is:

1. Create two `.txt` files in the same directoy
2. Edit `diff.s`
3. Run `make`
4. Run `./diff <fileName1>.txt <fileName2>.txt [-i -b]`
