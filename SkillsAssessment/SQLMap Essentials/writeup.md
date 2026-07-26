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

Lets go to http://154.57.164.73:30418/shop.html and see what we find.

<p align="center">
    <img width="1014" height="925" alt="shop" src="https://github.com/user-attachments/assets/d9b15d79-99f1-40f7-890b-386039012ed4" />
</p>

If we look in 


Lets target this form, first we'll make a request.txt, for this go to DevTools, then the Network tab, right click on the POST entry, and click on Copy Values, then click on Copy Request Headers.

Paste the values into request.txt,

Then go back and Copy POST Data and add it the request file.

- Note: make sure the POST Data is in a JSON format


# Attack:

Now that the request file, has been made see if we can get an injection.

    sqlmap --threads=10 --batch -r request.txt --random-agent



# Capture The Flag:

What's the contents of table final_flag?

