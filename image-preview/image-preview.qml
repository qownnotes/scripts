import QtQml 2.0

QtObject {
    property int maxWidth;

    property variant settingsVariables: [{
        "identifier": "maxWidth",
        "name": "Max width for image preview",
        "description": "Note that when the original image width is unknown (e.g. when using Markdown-it), images with a smaller width than this setting will be blown-up. This can not be prevented right now.",
        "type": "integer",
        "default": "640",
    }];

    /**
     * This function is called when the markdown html of a note is generated
     *
     * It allows you to modify this html
     * This is for example called before by the note preview
     *
     * @param {Note} note - the note object
     * @param {string} html - the html that is about to being rendered
     * @return {string} the modfied html or an empty string if nothing should be modified
     */
    function noteToMarkdownHtmlHook(note, html) {
        /**
         * This script does two things:
         * 1) Display the image with an user defined width;
         * 2) Wrap the image in an anchor tag that links to the full size image.
         * TODO: do not resize the image when it does not have a width attribute
         * AND is smaller than the maxWidth. Wrapping an image in a table with
         * `<td width="640">` does not work.
         */
        html = html.replace(/<img(?:.[^>]*)/g, handleImg);

        // script.log(html);
        return html;
    }

    /**
     * Handle image.
     * @param imgTag
     * @returns {string}
     */
    function handleImg(imgTag) {
        var src = getImgSrc(imgTag);
        imgTag = handleWidth(imgTag);
        return '<a href="' + src + '">' + imgTag + '></a';
    }

    /**
     * Handle width attribute.
     * @param imgTag
     * @returns {*}
     */
    function handleWidth(imgTag) {
        // Check if the img tag has a width attribute set.
        var widthMatch = /(?:width=")(.[^"]*)/g.exec(imgTag);
        // If the width attribute is larger than maxWidth, change.
        if (widthMatch) {
            var width = widthMatch[1];
            if (width > maxWidth) {
                imgTag = imgTag.replace(widthMatch[0], 'width="' + maxWidth);
            }
        }
        // No width attribute, add one.
        // TODO: blows up the image when original is smaller than maxWidth.
        // This occurs when using Markdown-it for example.
        else {
            imgTag = imgTag.replace('<img', '<img width="' + maxWidth + '" ');
        }

        return imgTag;
    }

    /**
     * Get image src attribute.
     * @param imgTag
     * @returns {string}
     */
    function getImgSrc(imgTag) {
        var srcMatch = /(?:src=")(.[^"]*)/g.exec(imgTag);
        var src = srcMatch[1];
        return src;
    }
}
