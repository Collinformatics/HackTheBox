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

Additionally, the CIDR prefix lengt is 16, giving us the following Subnet Mask: 255.255.0.0 

      ip a
      ...
      2: ens192: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
          link/ether a2:de:ad:10:b2:9c brd ff:ff:ff:ff:ff:ff
          altname enp11s0
          inet 10.129.204.126/16 brd 10.129.255.255 scope global dynamic ens192
             valid_lft 3238sec preferred_lft 3238sec
          inet6 dead:beef::a0de:adff:fe10:b29c/64 scope global dynamic mngtmpaddr 
             valid_lft 86396sec preferred_lft 14396sec
          inet6 fe80::a0de:adff:fe10:b29c/64 scope link 
             valid_lft forever preferred_lft forever
      ...


