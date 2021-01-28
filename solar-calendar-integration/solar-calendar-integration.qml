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
        
        var text = " یادداشت \n --- \n تاریخ: " + toPersianNum(jalaaliDate.jy) + "٫" + toPersianNum(pad(jalaaliDate.jm, 2)) + "٫" + toPersianNum(pad(jalaaliDate.jd, 2)) +
            "\n --- \n  ساعت: " + toPersianNum(pad(date.getHours(), 2)) + ":" + toPersianNum(pad(date.getMinutes(), 2)) + ":" + toPersianNum(pad(date.getSeconds(), 2))+"\n --- \n";
        
        return text;
    }

    function pad(num, size) {
        var s = num + "";
        while (s.length < size) s = "0" + s;
        return s;
    }
    function toPersianNum( num, dontTrim ) {

    var i = 0,

        dontTrim = dontTrim || false,

        num = dontTrim ? num.toString() : num.toString().trim(),
        len = num.length,

        res = '',
        pos,

        persianNumbers = typeof persianNumber == 'undefined' ?
            ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'] :
            persianNumbers;

    for (; i < len; i++)
        if (( pos = persianNumbers[num.charAt(i)] ))
            res += pos;
        else
            res += num.charAt(i);

    return res;
}

}
