## Background:

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

## RDP Credentials:

Login to the foothold with:

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

We appear to have credentials that can be read by low privilege users:

      cat Desktop/access-creds.txt
      to manage the blog:
      - admin / admin123!@#  ( keep it simple for the new admins )
      
      to manage Tomcat on apache
      - tomcat / Tomcatadm
      
      
      Change the passwords soon..


## Host 1:

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


## Host 2:

Now we've got our webserver.


## Host 3:

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


















