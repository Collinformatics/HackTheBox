# Skills Assement: Linux Privilege Escalation

We've ben hired to evaluate the security of an INLANEFREIGHT public servers.

We've been given access to a low privileged account and the goal of escalating our privileges so that we can get the 5 flags.


## Flag1.txt
Login and survey:

    htb-student@nix03:~$ id 
    uid=1002(htb-student) gid=1002(htb-student) groups=1002(htb-student)

    htb-student@nix03:~$ find / 2>/dev/null -name flag?.txt -exec ls -l {} \;
    -rwx------ 1 barry barry 29 Sep  5  2020 /home/barry/flag2.txt
    -rw-r----- 1 root adm 23 Sep  5  2020 /var/log/flag3.txt
    -rw------- 1 tomcat tomcat 25 Sep  5  2020 /var/lib/tomcat9/flag4.txt
