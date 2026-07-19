# Background:

We've been hired to test the security of a web app. In particular, we'll be looking for file upload forms and try to exploit them.



Recon:

As we start to look around we'll notice that the site is very early stage as most buttons don't take us anywhere. However if we click in "Contact Us" it will take us to the upload form at:

    http://154.57.164.64:31425/contact/

If we open devtools, we can find:

    <form action="/contact/submit.php" method="get">
            <div class="form-group">
              <label for="name">Name</label>
              <input class="form-control" id="name" type="text" name="Name" required="">
            </div>
            <div class="form-group">
              <label for="email">Email</label>
              <input class="form-control" id="email" type="email" name="Email" required="">
            </div>
            <div class="form-group">
              <label for="message">Message</label>
              <textarea class="form-control" id="message" name="Message" required=""></textarea>
            </div>
            <div>
              <p>Attach a screenshot</p>
              <div class="form-group">
                <div class="input-group">
                  <div class="custom-file">
                    <input name="uploadFile" id="uploadFile" type="file" class="custom-file-input" onchange="checkFile(this)" accept=".jpg,.jpeg,.png">
                    <label id="inputGroupFile01" class="custom-file-label" for="inputGroupFile02" aria-describeby="inputGroupFileAddon02">Select Image</label>
                  </div>
                  <button id="upload"><i class="fa fa-upload"></i></button>
                </div>
              </div>
              <p id="upload_message"></p>
            </div>
            <input class="btn btn-primary" type="submit" value="Submit">
          </form>


If we go to the Network tab in DevTools, script.js shows a basic blacklisting
 function:

    function checkFile(File) {
      var file = File.files[0];
      var filename = file.name;
      var extension = filename.split('.').pop();
    
      if (extension !== 'jpg' && extension !== 'jpeg' && extension !== 'png') {
        $('#upload_message').text("Only images are allowed");
        File.form.reset();
      } else {
        $("#inputGroupFile01").text(filename);
      }
    }
    
    $(document).ready(function () {
      $("#upload").click(function (event) {
        event.preventDefault();
        var fd = new FormData();
        var files = $('#uploadFile')[0].files[0];
        fd.append('uploadFile', files);
    
        if (!files) {
          $('#upload_message').text("Please select a file");
        } else {
          $.ajax({
            url: '/contact/upload.php',
            type: 'post',
            data: fd,
            contentType: false,
            processData: false,
            success: function (response) {
              if (response.trim() != '') {
                $("#upload_message").html(response);
              } else {
                window.location.reload();
              }
            },
          });
        }
      });
    });

- Note:

  The "extension" variable selects the last extention in the string, so if we give it pic.svg.png, extension = .png


# Testing:

Lets upload a .png and see what happens:

<p align="center">
    <img width="523" height="914" alt="sc_upload" src="https://github.com/user-attachments/assets/77f9265a-e0f7-4d57-a895-c5d9d8784304" />
</p>

Notice that the green button allows us to test if the image can be uploaded without needing to fill out the form, lets use test out how restrictive it is for different file extentions.

- Note:

  This report uses a POST request for fuzzing, Firefox sent GET requests, but by switching to Librewolf and then testing the file upload button we could then interception POST requests.

   Also, make sure to not encode the payloads:

    <p align="center">
        <img width="538" height="126" alt="sc-pl_encode" src="https://github.com/user-attachments/assets/59e75291-7ca3-4364-8a2e-a67664aee7b3" />
    </p>

- First we'll up load a .png and use Burp Suite to add an extention before .png. Well use the wordlist: /usr/share/seclists/Discovery/Web-Content/web-extensions.txt


        ------geckoformboundary1c3064ee08fbac913b71e2f796f8229c
        Content-Disposition: form-data; name="uploadFile"; filename="pic$ext$.png"
        Content-Type: image/png


After fuzzing, we can find the successful uploads by looking at the longest the Responces: 


<p align="center">
    <img width="1920" height="1045" alt="sc-fuzz-ext" src="https://github.com/user-attachments/assets/49d9c895-4b11-4bef-ab1d-26564207da60" />
</p>

- We can see that .....

Now lets determine what content-types are acceptable:

- First well make our wordlist:

    cat /usr/share/seclists/Discovery/Web-Content/web-all-content-types.txt | grep image/ > wl-webcontent.txt

<p align="center">
    <img width="1920" height="1045" alt="sc-fuzz-ct" src="https://github.com/user-attachments/assets/4d536c51-e9dc-4e68-8049-fb5cb85d8865" />
</p>


Now that we've determined what parameters can get through the upload filter, lets exploit the vulnerabilities.

- First, lets see if we can use an XXE attact to read a file on the server thats not supposed to be exposed.

<p align="center">
    <img width="1861" height="1045" alt="sc-read_file" src="https://github.com/user-attachments/assets/7a484fb9-bdd1-48f9-b8f4-e9abaecf56be" />
</p>

- As we see, we've got a Remote Code Execution exploit!


Next, lets insepct the upload file to see if we can find where its storint the files:

<p align="center">
    <img width="1861" height="1045" alt="sc-read_sc" src="https://github.com/user-attachments/assets/c13d9c26-0140-4783-9dfe-1cb014ed8331" />
</p>

- If we decode the base64 string we get:



