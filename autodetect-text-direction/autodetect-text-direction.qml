import QtQml 2.0

QtObject {

    /**
     * adds 'dir="rtl"' to content tags whose first character with a strong direction is RTL.
     *
     * @param {Note} note - the note object
     * @param {string} html - the html that is about to being rendered
     * @param {string} forExport - true if the html is used for an export, false for the preview
     * @return {string} the modified html or an empty string if nothing should be modified
     */
    function noteToMarkdownHtmlHook(note, html, forExport) {
        // I couldn't get /\p{Bidi_Class=...}/ (or its alias /\p{bc=...}/) for the values 'L', 'R', 'AL'. None of them works in JS, unlike Perl.
        // Even Unicode property escapes `\p{…}` don't work at all, b/c as of 2022 Nov, Qt QML implements ES7, but they were introduced in ES9.
        // So even `\p{scx=Arabic}` or `\p{Punct}` can't work. We need to use plain old character classes with Unicode ranges.

        // https://en.wikipedia.org/wiki/Right-to-left_script
        // U+0600–U+06FF Arabic
        // U+0750–U+077F Arabic Supplement
        // U+08A0–U+08FF Arabic Extended-A
        // U+0870–U+089F Arabic Extended-B
        // U+10EC0–U+10EFF Arabic Extended-C
        // U+FB50–U+FDFF Arabic Pres. Forms-A
        // U+FE70–U+FEFF Arabic Pres. Forms-B
        // U+1EE00–U+1EEFF Arabic Mathematical...
        // U+1EC70–U+1ECBF Indic Siyaq Numbers
        // U+1ED00–U+1ED4F Ottoman Siyaq Numbers
        // U+10E60–U+10E7F Rumi Numeral Symbols
        // U+0700–U+074F Syriac
        // U+0860–U+086F Syriac Supplement
        // U+0780–U+07BF Thaana
        // U+07C0–U+07FF NKo
        // U+0840–U+085F Mandaic
        // U+0800–U+083F Samaritan
        // U+0590–U+05FF Hebrew
        // U+FB1D–U+FB4F Alphabetic Presentation Forms (Hebrew)
        // U+1E900–U+1E95F Adlam
        // U+10D00–U+10D3F Hanifi Rohingya

        // also check:
        // https://en.wikipedia.org/wiki/List_of_Unicode_characters
        // https://en.wikipedia.org/wiki/Latin_script_in_Unicode

        // TODO:
        // - ignore `&*;` entities
        // - ignore inline formatting: `<p><em>أهلا…` and `<p><a …>أهلا…` should still be rtl

        // const rtl = '\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\u0870-\u089F\uFB50-\uFDFF\uFE70-\uFEFF\u0700-\u074F\u0860-\u086F\u0780-\u07BF\u07C0-\u07FF\u0840-\u085F\u0800-\u083F\u0590-\u05FF'  // TODO: beyond BMP
        // const nonletter = '\x00-\x40\x5B-\x60\x7B-\xA9\xAB-\xB9\xBB-\xBF\xD7\xF7'  // TODO
        // const rx = new RegExp(`<((?:p|li|td|th|h[1-6])\b[^>]*)>(?=[${nonletter}]*[${rtl}])`, 'g')
        return html.replace(
            /<((?:p|li|td|th|h[1-6])\b[^>]*)>(?=[\x00-\x40\x5B-\x60\x7B-\xA9\xAB-\xB9\xBB-\xBF\xD7\xF7]*[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\u0870-\u089F\uFB50-\uFDFF\uFE70-\uFEFF\u0700-\u074F\u0860-\u086F\u0780-\u07BF\u07C0-\u07FF\u0840-\u085F\u0800-\u083F\u0590-\u05FF])/g,
            (_, tag) => `<${tag} dir="rtl">`)
    }

}
