## Purpose:

This writeup detalis how to solve the Skills Assessment for the SQL Injection Fundamentals module from Hack THe Box Acadmey.

## Getting Started:

After starting the target, and pasting the ip in the browser youll notice that that the page doesnt load.

- You'll need to ignore the SSL Certificate to go to the page.

Once you are at the webpage click on the "create account" tab navigate to register.php.

- The form will not let you create an account without an "invitation code".

  - However the name="invitationCode" param is vulnerable to an SQL injection.

    - You can bypass the requirment with requests: ' or ''='
   
    - The browser will not let you exploit the form, but using req.py or a proxy like Burp Suite can be used to creat an account.
   
    - Notice that the registration form inclused and action param:
   
          <form action="/api/register.php" method="POST" id="registrationForm">

        We will need to send the request to https://<ip>/api/register.php
