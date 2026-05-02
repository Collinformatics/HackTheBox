# Skills Assement: Intro to Assembly Language

## Task 1:

We've got a suspicious binary file to inspect.

First lets start by dissassembling loaded_shellcode:

    objdump -d loaded_shellcode > lsc.s; cat lsc.s

We see that we've got addresses, bytes, instructions and operands.

We'll need to clean up the file by:

- Removing addresses,  characters like %
- Replacing movabs with mov
