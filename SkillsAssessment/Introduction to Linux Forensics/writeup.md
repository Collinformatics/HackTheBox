# Background:

This CTF Skills Assessment involves a compromised PostgreSQL Database. 

We have been provided the following data to inspect the incident:

-  Evidence artifacts located at:
  	- /home/linuxforensics/Desktop/cases/HacktiveLegion_15102023

- Authentication logs capturing login attempts and sudo activities:
  - /home/linuxforensics/Desktop/cases/HacktiveLegion_15102023/ubuntu/var/log/auth.log

- Command history for the compromised user account:
    - /home/linuxforensics/Desktop/cases/HacktiveLegion_15102023/ubuntu/home/kevin/.bash_history

- Memory dump of the running system at the time of isolation:
  - /home/linuxforensics/Desktop/cases/HacktiveLegion_15102023/memdump.mem

- Syslog containing Sysmon for Linux events (use SysmonLogView to parse):
  - /home/linuxforensics/Desktop/cases/HacktiveLegion_15102023/ubuntu/var/log/syslog

- PostgreSQL logs for database interactions:

  - /home/linuxforensics/Desktop/cases/HacktiveLegion_15102023/ubuntu/var/log/postgresql/postgresql-12-main.log


# Detemining Attacker IP:

To identify the attackers ip lets check auth.log for failed login attempts

    cat /home/linuxforensics/Desktop/cases/HacktiveLegion_15102023/ubuntu/var/log/auth.log | grep -i failed

- We see that kevin has been to brute force his way in from: 192.168.127.130


# Identify Timestamp Of The Suspicious Sudo Python Command:

We will again use inspect auth.log:

    cat /home/linuxforensics/Desktop/cases/HacktiveLegion_15102023/ubuntu/var/log/auth.log | grep python

This prints our deisred timestamp:

- Oct 15 10:38:03 ubuntu sudo:    kevin : TTY=pts/0 ; PWD=/home/kevin ; USER=root ; COMMAND=/usr/bin/python3 -c import


# Finding The Command And Control Address In The Payload:

    cat /home/linuxforensics/Desktop/cases/HacktiveLegion_15102023/ubuntu/home/kevin/.bash_history

This shows an echo command that pipes a base64 encoded string to python3

- If we decode the string and we see that C&C the address is: 3.212.197.166

# Find ParentProcessId Of The sh Command Associated With The Python Process:

Let's use volatility3 to inspect the processes:

    python3 ~/tools/volatility3/vol.py -f /home/linuxforensics/Desktop/cases/HacktiveLegion_15102023/memdump.mem linux.psaux.PsAux | grep sudo | grep python

This gives us two entries and they both contain the same base64 encoded payload.

- The PPID we want is: 2840 


# Find PID's Connecting To THe C&C Server:

We can investigate processes related to network connections:

    linuxforensics@ubuntu:~$ python3 ~/tools/volatility3/vol.py -q -f /home/linuxforensics/Desktop/cases/HacktiveLegion_15102023/memdump.mem linux.sockstat.Sockstat | grep 3.212.197.166

The command returns this table:

    NetNS   Pid     FD      Sock Offset     Family  Type    Proto   Source Addr     Source Port        Destination Addr        Destination Port        State   Filter
    4026531840      3939    3       0x93fe0ecc8000  AF_INET STREAM  TCP     192.168.127.236 56006   3.212.197.166   8080    ESTABLISHED     -
    4026531840      4519    3       0x93fe0ecc8000  AF_INET STREAM  TCP     192.168.127.236 56006   3.212.197.166   8080    ESTABLISHED     -
    4026531840      4522    3       0x93fe0ecc8000  AF_INET STREAM  TCP     192.168.127.236 56006   3.212.197.166   8080    ESTABLISHED     -
    4026531840      4612    3       0x93fe0ecc8900  AF_INET STREAM  TCP     192.168.127.236 55426   3.212.197.166   8080    SYN_SENT        -


# Find The Image Value ProcessId 2840:



































