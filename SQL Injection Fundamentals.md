## Purpose:

This writeup detalis how to solve the Skills Assment for the SQL Injection Fundamentals module from Hack THe Box Acadmey.

## Getting Started:

After starting the target, and pasting the ip in the browser youll notice that that the page doesnt load.

- You'll need to ignore the SSL Certificate to go to the page.

Once you are at the webpage click on the "create account" tab navigate to register.php.

- The form will not let you create an account without an "invitation code".

  - However the name="invitationCode" param is vulnerable to an SQL injection.

  - 

