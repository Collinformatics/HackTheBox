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

Note: Its recommended to cd into the case dir with:

    cd /home/linuxforensics/Desktop/cases/HacktiveLegion_15102023


# Detemining Attacker IP:

To identify the attackers ip lets check auth.log for failed login attempts

    cat ubuntu/var/log/auth.log | grep -i failed

- We see that kevin has been to brute force his way in from: 192.168.127.130


# Identify Timestamp Of The Suspicious Sudo Python Command:

We will again use inspect auth.log, but this time we will look for entries associated with python:

    cat ubuntu/var/log/auth.log | grep python

Fortunately there is only one entry, making it easy to find our deisred timestamp:

    Oct 15 10:38:03 ubuntu sudo:    kevin : TTY=pts/0 ; PWD=/home/kevin ; USER=root ; COMMAND=/usr/bin/python3 -c import


# Finding The Command And Control Address In The Payload:

    cat /ubuntu/home/kevin/.bash_history

This shows an echo command that pipes a base64 encoded string to python3

- If we decode the string and we see that C&C the address is: 3.212.197.166

# Find ParentProcessId Of The sh Command Associated With The Python Process:

Let's use volatility3 to inspect the processes:

    python3 ~/tools/volatility3/vol.py -q -f memdump.mem linux.psaux.PsAux | grep sudo | grep python

This gives us two entries and they both contain the same base64 encoded payload.

- The PPID we want is: 2840 


# Find PID's Connecting To The C&C Server:

We can investigate the processes related to network connections with Sockstat.

To investicgate the processes related to connections witht the C&C server use:

    python3 ~/tools/volatility3/vol.py -q -f memdump.mem linux.sockstat.Sockstat | grep 3.212.197.166

The command returns this table:

    NetNS   Pid     FD      Sock Offset     Family  Type    Proto   Source Addr     Source Port        Destination Addr        Destination Port        State   Filter
    4026531840      3939    3       0x93fe0ecc8000  AF_INET STREAM  TCP     192.168.127.236 56006   3.212.197.166   8080    ESTABLISHED     -
    4026531840      4519    3       0x93fe0ecc8000  AF_INET STREAM  TCP     192.168.127.236 56006   3.212.197.166   8080    ESTABLISHED     -
    4026531840      4522    3       0x93fe0ecc8000  AF_INET STREAM  TCP     192.168.127.236 56006   3.212.197.166   8080    ESTABLISHED     -
    4026531840      4612    3       0x93fe0ecc8900  AF_INET STREAM  TCP     192.168.127.236 55426   3.212.197.166   8080    SYN_SENT        -

- The PIDs are: 3939,4519,4522,4612

# Find The Image Value ProcessId 2840 In The SysmonForLinux Log:

The image, or path to the executable that started the process, can be found with:

    cat ubuntu/var/log/syslog | sudo /opt/sysmon/sysmonLogView

There are many lines in the output, but if we search for "ProcessId: 2840", the "Image" line will be nearby.

- The line we want is:

  - Image: /usr/bin/python3.8


# What Processes In The SysmonForLinux Log Are Connected To The Command & Control Server:

Use the command from the previous task to search the log for the server IP 3.212.197.166

- We have two options to scan the log and find the PIDs:

  1) The easy way, this requires an extra step where we write the provided script "scanSysmonEvents.sh" to the server, but it is much easier to read. The script can be ran with:

          cat ubuntu/var/log/syslog | sudo /opt/sysmon/sysmonLogView | bash scanSysmonEvents.sh "3.212.197.166"

  2) The hard way, this output is more difficult to read:

          cat ubuntu/var/log/syslog | grep --color=always '"ProcessId">' | grep --color=always "3.212.197.166"

- Now we just need to go through the output and find the unique PIDs. 

  - The PIDs are: 2840,3324,3939


# What User Executed Process 3324:

Next we need to search syslog output for "ProcessId: 3324".

If we look a couple of lines down we will find the answer:

- User: root


## Based On the Python3 Activity What Was Most Likly Appended To /home/kevin/.bashrc:



- The added line is: LD_PRELOAD=/usr/lib/sshd.so sshd &






















