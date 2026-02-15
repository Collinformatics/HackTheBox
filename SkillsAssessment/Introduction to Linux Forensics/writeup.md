# Background:

This walkthrough is for the HackTheBox's Introduction to Linux Forensics Skills Assessment.

- This CTF involves a compromised PostgreSQL Database.

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

- We see that kevin has been trying to brute force his way in from:

      192.168.127.130


# Identify Timestamp of the Suspicious Sudo Python Command:

We will again use inspect auth.log, but this time we will look for entries associated with python:

    cat ubuntu/var/log/auth.log | grep python

Fortunately there is only one entry, making it easy to find our deisred timestamp:

    Oct 15 10:38:03 ubuntu sudo:    kevin : TTY=pts/0 ; PWD=/home/kevin ; USER=root ; COMMAND=/usr/bin/python3 -c import


# Finding the Command and Control Address in the Payload:

    cat ubuntu/home/kevin/.bash_history

This shows an echo command that pipes a base64 encoded string to python3

- If we decode the string and we see that C&C the address is: 3.212.197.166

# Find ParentProcessId of the sh Command Associated With the Python Process:

Let's use volatility3 to inspect the processes:

    python3 ~/tools/volatility3/vol.py -q -f memdump.mem linux.psaux.PsAux | grep sudo | grep python

This gives us two entries and they both contain the same base64 encoded payload.

- The PPID we want is:

      2840 


# Find PID's Connecting to the C&C Server:

We can investigate the processes related to network connections with Sockstat.

To investicgate the processes related to connections witht the C&C server use:

    python3 ~/tools/volatility3/vol.py -q -f memdump.mem linux.sockstat.Sockstat | grep 3.212.197.166

The command returns this table:

    NetNS   Pid     FD      Sock Offset     Family  Type    Proto   Source Addr     Source Port        Destination Addr        Destination Port        State   Filter
    4026531840      3939    3       0x93fe0ecc8000  AF_INET STREAM  TCP     192.168.127.236 56006   3.212.197.166   8080    ESTABLISHED     -
    4026531840      4519    3       0x93fe0ecc8000  AF_INET STREAM  TCP     192.168.127.236 56006   3.212.197.166   8080    ESTABLISHED     -
    4026531840      4522    3       0x93fe0ecc8000  AF_INET STREAM  TCP     192.168.127.236 56006   3.212.197.166   8080    ESTABLISHED     -
    4026531840      4612    3       0x93fe0ecc8900  AF_INET STREAM  TCP     192.168.127.236 55426   3.212.197.166   8080    SYN_SENT        -

- The PIDs are:

      3939,4519,4522,4612

# Find the Image Value ProcessId 2840 in the SysmonForLinux Log:

The image, or path to the executable that started the process, can be found with:

    cat ubuntu/var/log/syslog | sudo /opt/sysmon/sysmonLogView

There are many lines in the output, but if we search for "ProcessId: 2840", the "Image" line will be nearby.

- The line we want is:

  - Image:

        /usr/bin/python3.8


# What Processes in the SysmonForLinux Log are Connected to the Command & Control Server:

Use the command from the previous task to search the log for the server IP 3.212.197.166

- We have two options to scan the log and find the PIDs:

  1) The easy way, this requires an extra step where we write the provided script "scanSyslog.sh" to the server, but it is much easier to read. The script can be ran with:

          cat ubuntu/var/log/syslog | sudo /opt/sysmon/sysmonLogView | bash scanSyslog.sh "3.212.197.166"

  2) The hard way, this output is more difficult to read:

          cat ubuntu/var/log/syslog | grep --color=always '"ProcessId">' | grep --color=always "3.212.197.166"

- Now we just need to go through the output and find the unique PIDs. 

  - The PIDs are:

        2840,3324,3939


# What User Executed Process 3324:

Next we need to search syslog output for "ProcessId: 3324".

If we look a couple of lines down we will find the answer:

- User:

      root


## Based on the Python3 Activity What Was Most Likly Appended to /home/kevin/.bashrc:

If we scan the syslog and filter for ".bashrc", we'll find the command from PID 3362:

    cat ubuntu/var/log/syslog | sudo /opt/sysmon/sysmonLogView | bash scanSyslog.sh ".bashrc"

-  CommandLine: /bin/sh -c echo "LD_PRELOAD=/usr/lib/sshd.so sshd &" >> /home/kevin/.bashrc

- We can clearly see that root added this line to kevin's .bashrc:

      LD_PRELOAD=/usr/lib/sshd.so sshd &


# Find the CreationUtcTime of sshd.so

We need to inspect the sshd.so file but it does not seem to exist in the avalible files. Kevin may have deleted it, but to us this does not matter.

We can find all events related to sshd.so in the syslog:

    cat ubuntu/var/log/syslog | sudo /opt/sysmon/sysmonLogView | bash scanSyslog.sh "sshd.so"

- Go to the event "SYSMONEVENT_FILE_CREATE" and we will find the time that the file was created:

      2023-10-15 17:40:29.197


# Find MD5 Hash for pid.3939.sshd.0x7fb4eed88000.dmp:

First we need to dump the memory mapped ELF files with:

    python3 ~/tools/volatility3/vol.py -q -f memdump.mem linux.elfs --pid 3939 --dump

Now all we need it to find the md5 hash:

    md5sum pid.3939.sshd.0x7fb4eed88000.dmp

- This gives us:

      657e355374203d2f5e406f951fc7d5ce


#  What IP address sshd.so is connecting to:

We can use linux.sockstat to list all network connections associated with PID 3939:

    python3 ~/tools/volatility3/vol.py -q -f memdump.mem linux.sockstat --pid 3939

This gives us:

    NetNS	Pid	FD	Sock Offset	Family	Type	Proto	Source Addr	Source Port	Destination Addr	Destination Port	State	Filter
    4026531840	3939	3	0x93fe0ecc8000	AF_INET	STREAM	TCP	192.168.127.236	56006	3.212.197.166	8080	ESTABLISHED	-

- Our connecting ip is the Destination Port:

      3.212.197.166


# What is the first memory region range with RWX permissions for sshd process:

We need to list the process memory mapping for PID 3939:

    python3 ~/tools/volatility3/vol.py -q -f memdump.mem linux.proc.Maps --pid 3939 --dump
    Volatility 3 Framework 2.5.2
    
    PID	Process	Start	End	Flags	PgOff	Major	Minor	Inode	File Path	File output
    
    3939	sshd	0x565006c5d000	0x565006c69000	r--	0x0	8	5	1443852	/usr/sbin/sshd	pid.3939.vma.0x565006c5d000-0x565006c69000.dmp
    ...
    3939	sshd	0x7fb4ee007000	0x7fb4ee2ef000	rwx	0x0	0	0	0	Anonymous Mapping	pid.3939.vma.0x7fb4ee007000-0x7fb4ee2ef000.dmp

As we see from the output, the first region with rwx permissions is:

    0x7fb4ee007000-0x7fb4ee2ef000


# Scan Discovered RWX Memory region with yara and Find the Triggered Rule:

We can scan the .dmp with:

    for i in `ls ~/tools/yara/*`;do yara "$i" pid.3939.vma.0x7fb4ee007000-0x7fb4ee2ef000.dmp; done 2>/dev/null

- This will iterate through the yara rules files in ~/tools/yara/, and detemines if the memory dump segment is in violation of any of these rules.

The output is:

    mettle pid.3939.vma.0x7fb4ee007000-0x7fb4ee2ef000.dmp

And the triggered rule is:

    mettle

- Note:
  - Mettle is the lightweight Meterpreter agent used on Linux and macOS.
  - Meterpreter is a Metasploit payload that will run on the target system and act as an agent within a Command & Control architecture.


# What is a session uuid(-U) for a meterpreter agent?

- Hint: The answer is a base64 encoded string

Lets hexdump the .dmp and search for base64 strings:

    hexdump -C pid.3939.vma.0x7fb4ee007000-0x7fb4ee2ef000.dmp | grep ==

Near the end we have:

    --
    *
    002d81c0  6d 65 74 74 6c 65 00 2d  55 00 22 62 57 57 6f 58  |mettle.-U."bWWoX|
    002d81d0  73 57 44 67 50 47 31 41  37 4d 42 30 43 2b 51 6b  |sWDgPG1A7MB0C+Qk|
    002d81e0  67 3d 3d 00 20 2d 47 00  22 5a 70 4d 2b 4a 4f 52  |g==. -G."ZpM+JOR|
    002d81f0  36 53 73 53 57 74 51 34  6a 59 58 38 6f 7a 77 3d  |6SsSWtQ4jYX8ozw=|
    002d8200  3d 00 20 2d 75 00 22 74  63 70 3a 2f 2f 30 2e 30  |=. -u."tcp://0.0|
    002d8210  2e 30 2e 30 3a 38 30 38  30 00 20 2d 64 00 22 30  |.0.0:8080. -d."0|
    --

Notice the "mettle" in the ASCII column, followed by "-U" which is the same flag used to specfy the UUID of the payload. And right after that we have: "bWWoXsWDgPG1A7MB0C+Qkg==

- This almost matches a base64 string, but " is not a valid base64 char. If we remove it we have the string we are looking for:

      bWWoXsWDgPG1A7MB0C+Qkg==


# What is the PID Associated with psql Process Pxecution?

Let go back to the syslog and search for sql related processes:

    cat ubuntu/var/log/syslog | sudo /opt/sysmon/sysmonLogView | bash scanSyslog.sh "sql"

At 2023-10-15 17:50:09.419, we see that root created a process from the directory /home/kevin, which is inherrently sus. The PID is:

    4523


# Which user information was exfiltrated?

To determine if any users data was accessed, lets check the PostgreSQL log for anything related to PID 4523:

    cat ubuntu/var/log/postgresql/postgresql-12-main.log | grep [4523]

We see the last entry in this list is:

    2023-10-15 10:50:34.378 PDT [4532] postgres@prod LOG:  statement: select * from users where name LIKE 'Wade Murphy%';

Indicating that kevin has accesed user data from:

    Wade Murphy
