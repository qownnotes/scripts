import QtQml 2.0
import QOwnNotesTypes 1.0

Script {
    function autocompletionHook() {
        // get the current word plus non-word-characters before the word to also get the "[<"-character
        var word = script.noteTextEditCurrentWord(true);

        if (!word.startsWith("[<")) {
            script.log(word);
        }
        var noteSubFolder = script.currentNoteFolderPath();
        script.log(noteSubFolder);
        // cut the "@" off of the string and do a substring search for tags
        var tags = script.searchTagsByName(word.slice(2,-1));
        script.log(tags);
        return tags;
    }
    
}
