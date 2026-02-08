# Background

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

# Detemining Attacker IP

To identify the attackers ip lets check auth.log for failed login attempts

    cat /home/linuxforensics/Desktop/cases/HacktiveLegion_15102023/ubuntu/var/log/auth.log | grep -i failed

- We see that kevin has been to brute force his way in from: 192.168.127.130



