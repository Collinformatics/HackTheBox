# Background:

We've been hired to test the security of a early stages web app. In particular, we'll be looking for file upload forms and try to exploit them.



Recon:

After looking around, we see that there is an upload form at:

    http://154.57.164.64:31425/contact/


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
      
