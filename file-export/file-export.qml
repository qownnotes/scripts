import QtQml 2.0
import com.qownnotes.noteapi 1.0
import QOwnNotesTypes 1.0


/**
 * This script creates a menu item and a button to export attachments and media from the note.
 * Select the text with the markdown links you want to export or nothing for all files inside the note.
 * It will automatically used the correct file names of the note (not the scrambled number inside the attachments folder) and create a zipped file if more the one file is selected (Linux only for now).
 * You can also format selected attachments neatly with the format button or context menu.
 */
QtObject {

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [

    ];

    function log(text){
        script.log("[FileExport] "+text)
    }

    property var dialog
    function exportFiles() {
        log("Exporting files ...")
        if (!script.platformIsLinux()) {
            // only will be executed if under Linux
            script.informationMessageBox("The script does only support Linux.", "OS not supported");
            return
        }
        //log("start")
        const regex_media = /\[.+?\]\(.+?\)/gm;
        const regex_name = /\[(.*?]*)\]/gm;
        const regex_path = /\((.*?]*)\)/gm;
        const selectedText = script.noteTextEditSelectedText()

        if(selectedText === null || selectedText.length === 0){
            return // TODO
        }

        const mdFiles = selectedText.match(regex_media)// regex_media.exec(selectedText)

        if(mdFiles === null || mdFiles.length === 0){
            return
        }

        const currentNote = script.currentNote();
        if(currentNote === null){
            script.informationMessageBox("Cannot access current note", "Note not found");
            return
        }

        const folder = currentNote.fullNoteFileDirPath

        var files = []
        mdFiles.forEach(function(element, i, array){
            // get the name with brackets
            var name = element.match(regex_name)[0]// [name.pdf](../attachments/1234.svg)
            // remove brackets
            name = name.substring(1, name.length - 1) //removes last character

            var filePath = element.match(regex_path)[0]
            // remove brackets
            filePath = filePath.substring(1, filePath.length - 1)
            var path = folder+'/'+filePath
            var file = [name, path]
            files.push(file)
        })

        var para = []
        var target
        var cmd
        if(files.length === 1){
            cmd = "cp"
            var suffix = getSuffix(files[0][1])
            target = script.getSaveFileName("Please select a destination to save", files[0][0], "*"+suffix);
            if(target === null || target === ''){
                return // canceled
            }
            target += (target.endsWith(suffix) ? '' : suffix)
            var source = files[0][1]
            para.push(source)
            para.push(target)
        }else{
            cmd = "zip"
            para.push("-j") // no parent folders, _J_UST the files

            target = script.getSaveFileName("Please select a destination to save", "QON_"+getDateString(), "zip (*.zip)");
            if(target === null || target === ''){
                return // canceled
            }

            para.push(target)

            const tmpDir = "/tmp/qon/"+Date.now()+"/"
            script.startSynchronousProcess("mkdir", ["-p",tmpDir]);
            var tmpPara;
            files.forEach(function(element, i, array){
                var name = element[0]
                var path = element[1]
                var suffix = getSuffix(path)
                // attachment names already carry the suffix  [FileExport.qml](../attachments/FileExport-1357526733.qml)
                var tmpPath = tmpDir+name+(name.endsWith(suffix) ? '' : suffix)
                //create symlinks to allow the right file names to be zipped (ln -s wrong_name.txt right_name.txt)
                tmpPara = []
                tmpPara.push("-s")
                tmpPara.push(path)
                tmpPara.push(tmpPath)
                script.startSynchronousProcess("ln", tmpPara) // Why doesn't ["-s", path, tmpPara] work?
                para.push(tmpPath)
            })
            tmpPara = []
            tmpPara.push("-r")
            tmpPara.push(tmpDir)
        }

        var result = script.startSynchronousProcess(cmd, para); //startSynchronousProcess startDetachedProcess

        // remove the temporary soft links
        script.startSynchronousProcess("rm", tmpPara)

        log("Exported file(s) to: "+target)

    }

    /**
      *
      */
    function getSuffix(filepath){
        const regex_suffix = /\.[0-9a-z]+$/i;
        return filepath.match(regex_suffix)[0]
    }


    /**
      *
      */
    function getDateString(){
        function appendLeadingZeroes(n){
          if(n <= 9){
            return "0" + n;
          }
          return n
        }

        let current_datetime = new Date()
        console.log(current_datetime.toString());
        let formatted_date = current_datetime.getFullYear() + "-" + appendLeadingZeroes(current_datetime.getMonth() + 1) + "-" + appendLeadingZeroes(current_datetime.getDate()) + "T" + appendLeadingZeroes(current_datetime.getHours()) + ":" + appendLeadingZeroes(current_datetime.getMinutes()) + ":" + appendLeadingZeroes(current_datetime.getSeconds())
        return formatted_date
    }

    /**
     * Registers a custom action
     *
     * @param identifier the identifier of the action
     * @param menuText the text shown in the menu
     * @param buttonText the text shown in the button
     *                   (no button will be viewed if empty)
     * @param icon the icon file path or the name of a freedesktop theme icon
     *             you will find a list of icons here:
     *             https://specifications.freedesktop.org/icon-naming-spec/icon-naming-spec-latest.html
     * @param useInNoteEditContextMenu if true use the action in the note edit
     *                                 context menu (default: false)
     * @param hideButtonInToolbar if true the button will not be shown in the
     *                            custom action toolbar (default: false)
     * @param useInNoteListContextMenu if true use the action in the note list
     *                                 context menu (default: false)
     */
    function init() {
        script.registerCustomAction("fileExport", "Export selected files", "Export files", "archive-extract", true, false, true);
        script.registerCustomAction("formatAttachments", "Format Attachments/Media links", "Expert filesFormat Attachments/Media links", "edit-guides", true, false, true);
    }


    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier === "fileExport") {
            exportFiles()
        }
        if (identifier === "formatAttachments") {
            formatAttachments()
        }
    }

    /**
      * Add/remove line breaks to align media links neatly
      */
    function formatAttachments(){
        const regex_media = /(\s*)(!?\[.+?\]\(.+?\))/gm; // additional '(' create a group to be used as $1
        const note = script.currentNote();
        var match;

        if(script.noteTextEditSelectedText().length === 0){
            script.noteTextEditSelectAll(); // format entire note if nothing is selected
        }
        var currentSelectedText = script.noteTextEditSelectedText();
        script.noteTextEditWrite(currentSelectedText.replace(regex_media, "\n$2  ")) // "  " -> newline

    }


}
