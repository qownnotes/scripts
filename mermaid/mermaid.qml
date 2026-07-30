import QtQml 2.0
import QOwnNotesTypes 1.0

QtObject {
    /**
    * Encodes a string as base64 of its UTF-8 representation
    *
    * This replaces the deprecated Qt.btoa(string) call, which emits a
    * deprecation warning in newer Qt versions
    *
    * @param {string} text - the text to encode
    * @return {string} the base64 encoded text
    */
    function toBase64(text) {
        const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        var bytes = [];

        // encode the string as UTF-8
        for (var i = 0; i < text.length; i++) {
            var cp = text.codePointAt(i);

            if (cp > 0xFFFF) {
                // skip the low surrogate of the surrogate pair
                i++;
            }

            if (cp < 0x80) {
                bytes.push(cp);
            } else if (cp < 0x800) {
                bytes.push(0xC0 | (cp >> 6), 0x80 | (cp & 0x3F));
            } else if (cp < 0x10000) {
                bytes.push(0xE0 | (cp >> 12), 0x80 | ((cp >> 6) & 0x3F), 0x80 | (cp & 0x3F));
            } else {
                bytes.push(0xF0 | (cp >> 18), 0x80 | ((cp >> 12) & 0x3F), 0x80 | ((cp >> 6) & 0x3F), 0x80 | (cp & 0x3F));
            }
        }

        var result = "";

        for (var j = 0; j < bytes.length; j += 3) {
            const b0 = bytes[j];
            const b1 = j + 1 < bytes.length ? bytes[j + 1] : -1;
            const b2 = j + 2 < bytes.length ? bytes[j + 2] : -1;

            result += alphabet[b0 >> 2];
            result += alphabet[((b0 & 0x03) << 4) | (b1 < 0 ? 0 : b1 >> 4)];
            result += b1 < 0 ? "=" : alphabet[((b1 & 0x0F) << 2) | (b2 < 0 ? 0 : b2 >> 6)];
            result += b2 < 0 ? "=" : alphabet[b2 & 0x3F];
        }

        return result;
    }

    /**
    * This function is called before the markdown html of a note is generated
    *
    * It allows you to modify what is passed to the markdown to html converter
    *
    * The method can for example be used in multiple scripts to render code (like LaTeX math or mermaid)
    * to its graphical representation for the preview
    *
    * The note will not be changed in this process
    *
    * @param {NoteApi} note - the note object
    * @param {string} markdown - the markdown that is about to being converted to html
    * @param {string} forExport - true if the html is used for an export, false for the preview
    * @return {string} the modified markdown or an empty string if nothing should be modified
    */
    function preNoteToMarkdownHtmlHook(note, markdown, forExport) {
        var re = /```mermaid\n([\s\S]*?)\n```/gim;
        markdown = markdown.replace(re, function (_, diag) {
            var encodedData = toBase64(diag);
            var ink = '![](https://mermaid.ink/img/' + encodedData + ')';
            return ink;
        });
        return markdown;
    }
}
