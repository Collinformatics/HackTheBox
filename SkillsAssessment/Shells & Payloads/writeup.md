## Background:

This is is a walk-through for the Hack the Box Academy's module Shells & Payloads.

CAT5's team proided a foothold on Inlanefreight's network. They've also provied recon data for our target. There is a Web app, a Windows, and a Linux host or server on the network and we need to find a sutable payload to exploit each machine. Our goal is to get a shell on each system.

We will need to Remote Desktop Protocol (RDP) into the foothold host and perform out attack from there. 


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

Also there


