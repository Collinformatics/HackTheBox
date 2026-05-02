# Skills Assement: Intro to Assembly Language

## Task 1:

We've got a suspicious binary file to inspect.

First lets start by dissassembling loaded_shellcode:

    objdump -d loaded_shellcode

We see that we've got addresses, bytes, instructions and operands.

Lets make an assembly file with objdump:

    objdump -d loaded_shellcode | awk '{$1=$2=""; print substr($0, length(OFS)*2 + 1)}' > lsc.s

- Awk helped remove aalot of unnecessary info, but we'll need to further clean up the file by:

    - Remove the format info
    - Removing bytes, characters like %
    - Replacing movabs with mov, and put the operands in the correct order
