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

## Exploit Database:

The "search in conversation" input field uses a GET request to retrieve messages in the database. This represents a potential injection point.

To find the database name we can use the injection:

    ') UNION SELECT 1, 2, 3, database() FROM INFORMATION_SCHEMA.SCHEMATA #

- This returns: chattr

<img width="1223" height="461" alt="chattr" src="https://github.com/user-attachments/assets/ead424ef-36e2-4042-ae94-bc4497f9f337" />






