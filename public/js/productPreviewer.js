(function(){
    var remsize = parseFloat(getComputedStyle(document.documentElement).fontSize);
    var productEntries = document.querySelectorAll('.product');
    for(var i = 0; i < productEntries.length; i++) {
        productEntries[i].addEventListener('mouseenter', function(){
            var previewElement = this.querySelector('.ProductPreview');
            if(previewElement === null) {
                return;
            }
            if (this.offsetWidth >= previewElement.offsetWidth) {
                return;
            }
            previewElement.style.transition = 'all ease-in-out ' + (7 * previewElement.offsetWidth) + 'ms';
            previewElement.style.transform = 'translateX(' + (this.offsetWidth - previewElement.offsetWidth - (2 * remsize)) + 'px)';
        });
        productEntries[i].addEventListener('mouseleave', function(){
            var previewElement = this.querySelector('.ProductPreview');
            if(previewElement === null) {
                return;
            }
            previewElement.style.transition = 'all ease-in-out ' + (3 * previewElement.offsetWidth) + 'ms';
            previewElement.style.transform = 'translateX(0)';
        });
    }
})();