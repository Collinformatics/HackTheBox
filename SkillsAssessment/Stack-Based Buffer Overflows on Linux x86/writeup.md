## Background: 

We've recycled a password to SSH into annother Linux machine during a pen test.

We login with a standard access account, htb-student. The program leave_msg allows us to leave a message for an admin.

We see that these messages are stored in "/htb-student/msg.txt," which is binary owned by the user root, and the SUID bit is set.

Let's see if we can exploit the program with Stack-Based Buffer Overflow to read the file "/root/flag.txt".

## Shellcode:

First lets start by generating shell code that can cat a file.

- We can use pwntools for this: https://docs.pwntools.com/en/stable/shellcraft/aarch64.html#pwnlib.shellcraft.aarch64.linux.cat

We'll need to make a flag to test the code:

    echo "HTB{f4lS3_fLag}" > flag.txt

Now use shellcodePwn.py to generatecode to read the file "flag.txt"

