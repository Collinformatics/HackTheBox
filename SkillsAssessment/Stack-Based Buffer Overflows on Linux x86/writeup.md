## Background: 

We've recycled a password to SSH into annother Linux machine during a pen test.

We login with a standard access account, htb-student. The program leave_msg allows us to leave a message for an admin.

We see that these messages are stored in "/htb-student/msg.txt," which is binary owned by the user root, and the SUID bit is set.

Let's see if we can exploit the program with Stack-Based Buffer Overflow to read the file "/root/flag.txt".

