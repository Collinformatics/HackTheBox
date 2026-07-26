# Background

We've been given access to a web app with basic protections.

Let's use SQLMap to find the SQLi vulnerabilities and then exploit them!


# Recon:

After clicking around we'll see that the webpage contains many forms, but most contain action="#", which simply sends us to the top of the page, and doesnt seem to send out any data.

Lets use sqlmap to crawl the site:

    $ sqlmap --threads=10 --batch -u http://154.57.164.73:30418 --forms --crawl=3

- This finds 4 targets, and test 2 of them:

      POST http://154.57.164.73:30418/shop.html people=%23&people=%23

      GET http://154.57.164.73:30418/checkout.html?=&optradio=on

- The others were skipped, likely due to a lack of input parameters.



# Attack:





# Capture The Flag:

What's the contents of table final_flag?

