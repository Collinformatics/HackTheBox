# Background:

We've been hired to test the security of a early stages web app. In particular, we'll be looking for file upload forms and try to exploit them.



Recon:

After looking around, we see that there is an upload form at:

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


# Testing:

Lets upload a .png and see what happens:

<p align="center">
    <img width="523" height="914" alt="sc_upload" src="https://github.com/user-attachments/assets/77f9265a-e0f7-4d57-a895-c5d9d8784304" />
</p>



