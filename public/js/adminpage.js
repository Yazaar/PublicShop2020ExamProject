(function(){
    var productImages = document.querySelectorAll('.AdminProductPreview');
    for(var i = 0; i < productImages.length; i++){
        productImages[i].addEventListener('click', function(){
            var response = confirm('Would you like to delete the image forever?');
            if(response === false) {
                return;
            }
            var regex = this.src.match(/\/product_pictures\/(\d+)\/([^$]+)/);
            if(regex === null) {
                return;
            }
            var pid = regex[1];
            var fid = regex[2];
            var form = document.querySelector('#ProductImageSubmitter');
            form.querySelector('.formAction').value = 'delete';
            form.querySelector('.formProductId').value = pid;
            form.querySelector('.formImageId').value = fid;
            form.submit();
        });
    }
})();

(function(){
    var fileData;
    var canvas = document.querySelector('#UploadFile');
    var context = canvas.getContext('2d');
    
    var sendbtn = document.querySelector('#SendImage');
    var previewText = document.querySelector('#PreviewText');
    var imageTextField = document.querySelector('#ImageTextField');
    var publishbtn = document.querySelector('#SendProfilePicture');
    
    document.querySelector('#fileupload').addEventListener('input', function(){
        var image = new Image();
        image.addEventListener('load', function(){
            context.clearRect(0, 0, 126, 126);
            context.drawImage(image, 0, 0, 126, 126);
            fileData = canvas.toDataURL();
            canvas.style.display = '';
            sendbtn.style.display = '';
            previewText.style.display = '';
        });
        image.src = URL.createObjectURL(this.files[0]);
    });
    
    sendbtn.addEventListener('click', function(){
        if (fileData === undefined) {
            return;
        }
        imageTextField.value = fileData;
        publishbtn.click();
    });
})();

(function(){
    var newProductImagePickers = document.querySelectorAll('.NewProductImagePicker');
    for(var i = 0; i < newProductImagePickers.length; i++) {
        newProductImagePickers[i].addEventListener('input', function(){
            var canvas = this.parentElement.querySelector('canvas');
            var context = canvas.getContext('2d');
            var image = new Image();
            image.addEventListener('load', function(){
                canvas.setAttribute('width', this.width);
                canvas.setAttribute('height', this.height);
                context.clearRect(0, 0, this.width, this.height);
                context.drawImage(image, 0, 0, this.width, this.height);
                var form = document.querySelector('#ProductImageSubmitter');
                form.querySelector('.formAction').value = 'upload';
                form.querySelector('.formProductId').value = canvas.getAttribute('data-productid');
                form.querySelector('.formBase64Image').value = canvas.toDataURL();
                form.submit();
            });
            image.src = URL.createObjectURL(this.files[0]);
        });
    }
})();