import QtQml 2.0
import QOwnNotesTypes 1.0

// see: https://github.com/jalaali/jalaali-js
import "jalaali.js" as Jalaali

QtObject {
    /**
     * Set a headline for new notes with the current Jalaali date and time
     */
    function handleNewNoteHeadlineHook(headline) {
        const date = new Date();

        // { jy: 1395, jm: 1, jd: 23 }
        const jalaaliDate = Jalaali.toJalaali(date);
        
        var text = "یادداشت " + jalaaliDate.jy + "٫" + pad(jalaaliDate.jm, 2) + "٫" + pad(jalaaliDate.jd, 2) +
            " " + pad(date.getHours(), 2) + "." + pad(date.getMinutes(), 2) + "." + pad(date.getSeconds(), 2);
            
        var underline = "\n";

        // add the underline
        for (var i = 0; i < (text.length - 1); i++) {
            underline += "=";
        }

        return text + underline;
    }

    function pad(num, size) {
        var s = num + "";
        while (s.length < size) s = "0" + s;
        return s;
    }
}
