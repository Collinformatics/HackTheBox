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

Once cleaned up, lets add lines to decode and print the data.

Now we should be ready to assemble, execute and write the output to a text file:

    ./assembler.sh lsc.s > hex

Now lets on catinate the decoded shellcode:

    tr -d '\n' < hex

Take the output and execute the shellcode with the pwntools script that we built in this module:

    ./Documents/Scripts/shellcodeRun.py -s 4831c05048bbe671167e66af44215348bba723467c7ab51b4c5348bbbf264d344bb677435348bb9a10633620e771125348bbd244214d14d244214831c980c1044889e748311f4883c708e2f74831c0b0014831ff40b7014831f64889e64831d2b21e0f054831c04883c03c4831ff0f05

- This gives up the flag:

        Output:
        HTB{4553mbly_d3bugg1ng_m4573r}


## Task 2:

We're given an assembly file for generating a shellcode to run on a vulnerable server. In order to do so we need to optimize flag.s so that it is less than 50 bytes.

Lets start by generating an ELF file from the assembly file:

    ./assembler.sh flag.s

Now we can inspect it:

    ./Documents/Scripts/shellcode.py flag
    Hex:
    6a0048bf2f666c672e74787457b8020000004889e7be000000000f05488d374889c7b800000000ba180000000f05b801000000bf01000000ba180000000f05b83c000000bf000000000f05
    
    75 bytes - Found NULL byte

The output reveals that we have a significant number of NULL bytes, so lets start here.

- Lets examine the ELF file:

        objdump -d flag

    We can see that the first push instruction, and most mov instructions are responsible for the NULL bytes.

    Lets fix this with and xor for the push, and adjust the sub-registers.

    To monitor the results of each change we'll run this command while editing flag.s:

        watch -n 1 "./assembler.sh flag.s; objdump -d flag"

After removing the null bytes make sure to use gdb to inspect the edited assembly script. You'll likely need to go back and make sure to completly clear each 64-bit register before overwriting with 32, 16, or 8-bit registers.

  If:   $rax   : 0xfffffffffffffffe
  Then: "xor al, al" will result in:
        $rax   : 0xffffffffffffff00






