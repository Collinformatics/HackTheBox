# Skills Assement: Intro to Assembly Language

## Task 1:

We've got a suspicious binary file to inspect.

First lets start by dissassembling loaded_shellcode:

    objdump -d loaded_shellcode

We see that we've got addresses, bytes, instructions and operands.

Lets make an assembly file with objdump:

    objdump -d loaded_shellcode | awk '{$1=$2=""; print substr($0, length(OFS)*2 + 1)}' > lsc.s

- The output should look similar to this:

        format elf64-x86-64
        
        
        section .text:
        
        
        b8 d7 4b de 7c 5c movabs $0xa284ee5c7cde4bd7,%rax
        84 a2
        push %rax
        b8 9a 84 10 05 11 movabs $0x935add110510849a,%rax
        5a 93
        push %rax
        ...

    - Awk helped remove alot of unnecessary info, but we'll need to further clean up the file by:

        - Remove the format info
        - Remove bytes and characters like %
        - Replace movabs with mov
        - Put the destination and sourse in the correct order

Once cleaned up, lets add lines to decode and print the data.

Now we should be ready to assemble, execute and write the output to a text file:

    ./assembler.sh lsc.s > hex

Now lets on catinate the decoded shellcode:

    tr -d '\n' < hex

Take the output and execute the shellcode with the pwntools script that we built in this module:

    ./shellcodeRun.py -s 4831c05048bbe671167e66af44215348bba723467c7ab51b4c5348bbbf264d344bb677435348bb9a10633620e771125348bbd244214d14d244214831c980c1044889e748311f4883c708e2f74831c0b0014831ff40b7014831f64889e64831d2b21e0f054831c04883c03c4831ff0f05

- This gives up the flag:

        Output:
        HTB{4553mbly_d3bugg1ng_m4573r}


## Task 2:

We're given an assembly file for generating a shellcode to run on a vulnerable server. In order to do so we need to optimize flag.s so that it is less than 50 bytes.

Lets start by making a flag to test the assembly file:

    echo "HTB{f4lS3_fLag}" > flag.txt

- Make sure to replace '/flg.txt' with 'flag.txt' so that the flag.s is opening the correct file.

Once the flag has been made and flag.s has been adjusted, lets test the code:

    ./assembler.sh flag.s

We see that there are several syscalls. We need to make sure they are working before moving on recall the Syscall Arguments:

- 1st arg: rdi, edi, di, dil
- 2nd arg: rsi, esi, si, sil
- 3rd arg: rdx, edx, dx, dl

To test the assembly script it will take some debugging. Be sure to consult the man pages to detemine the proper inputs:

- Open:

        man -s 2 open

    0) Syscall: 2
       
    1) Path: rsp
       
       Push 'flag.txt' to the stack, then use rsp as the input for this param.
       
    2) Flag: 2
       
       Setting this to 2 selcets the O_RDONLY flag, this is used for both reading and writing.

- Read:

        man -s 2 read

    0) Syscall: 0
       
    1) File Descriptor: eax

       Set this to the output of open() that is stored in rax.
       
    2) Buffer: rsp
       
       Pointer to the file. This is the same as the path used for open().
       
    3) Size: 25
       
       String length.

- Write:

        man -s 2 write

    0) Syscall: 1
       
    1) File Descriptor: 1
       
       Set fd to 1 for stdout.
  
    2) Buffer: rsp
       
       Pointer to the file.
       
    3) Size: 25
       
       String length.

While debugging be sure to use gdb to make sure use gdb to detrmine if you have correctly assigning values to the registers and that a previous syscall has not overwriting them.


Once the arguments are correctly set, lets see if the code prints out flag:

    ./assembler.sh flag.s


Once the code is printing the flag, lets check how large it is and if there are any NULL bytes we can remove:

    ./assembler.sh flag.s; objdump -d flag; ./shellcode.py flag

Your code will most likly be well over the 50 byte limit. The file size can be reduced by:

- Clear registers with "xor eax, eax" instead of "mov eax, 0"
  
  When possible xor with 32-bit register instead of 16-bit.

  - xor esi, esi => 2 bytes
  - xor si, si => 3 bytes

  Use gdb to verify that you are using the correct register size with an xor instruction, so that you clear the full pointer.

  - If:    $rax   : 0xfffffffffffffffe
  - Then:  "xor al, al"
  - Gives: $rax   : 0xffffffffffffff00
 
  - While: "xor rax, rax"
  - Gives: $rax   : 0x0000000000000000

- Decreasing register sizes:

  Ex: change rax to eax, ax, or al.

- Remove the syscall to exit the script, we can print the flag without.

- Tip: While making adjustment use watch to see how the changes affect the size of the ELF file, and to ensure that you can still print the flag.

        ./assembler.sh flag.s; objdump -d flag; ./shellcode.py flag

Once you are under 50 bytes, change the file name back to '/flg.txt' and use netcat to connect to the server and test your shellcode.

- mov rdi, 'flag.txt' => mov rdi, '/flg.txt'

