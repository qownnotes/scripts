import QtQml 2.13
import com.qownnotes.noteapi 1.0


/**
 * This script creates LaTex images on the fly with KLatexFormula. e. g. $x^2$ or $[22] x^2$ to create larger images.
 * The images are created once and reused as long as the formula does not change.
 * If you changed the preamble you have to clean the tmp folder to regenerate the images.
 * Don't make it too complicated, this size works though: $[33] \\frac{1}{2\\pi}\\int{-\\infty}^{\\infty}e^{-\\frac{x^2}{a}}dx$
 * Hint: You might want to add the $-signs after writing the formula to prevent intermediate image generation.
 * test cmd: klatexformula -b '#ff0000' --latexinput '\delta(x) = \frac{1}{2\pi} \int e^{ikx}\,dk' --dpi 300 --output dirac-delta.png
 */
QtObject {
    property string settingImageSize;
    property string settingDPI;
    property string executable;
    property string workDir
    property string formulaPrefix;
    property string formulaColor;
    property string formulaBgColor;
    property string usepackages;
    property string customPreamble;
    property bool debug;

    // register your settings variables so the user can set them in the script settings
    property variant settingsVariables: [{
            "identifier": "settingImageSize",
            "name": "Default image height size",
            "description": "The default size of the LaTex image. Change it via parameter e. g. $[14] x^2$",
            "type": "integer",
            "default": "16"
        },
        {
            "identifier": "settingDPI",
            "name": "Default DPI",
            "description": "The default DPI used for the images.",
            "type": "integer",
            "default": "600"
        },
        {
            "identifier": "executable",
            "name": "Executable",
            "description": "Please enter a path to KLatexFormula",
            "type": "file",
            "default": "/usr/bin/klatexformula"
        },
        {
            "identifier": "formulaPrefix",
            "name": "Formula Prefix",
            "description": "Please enter a prefix for all formulas. Remember you might want to leave a space at the end.",
            "type": "string",
            "default": "\\bf "
        },
        {
            "identifier": "formulaColor",
            "name": "Formula Color",
            "description": "Use a different color. Useful for dark mode and the like. Format: #RRGGBB or '-' for transparent",
            "type": "string",
            "default": "#000000"
        },
        {
            "identifier": "formulaBgColor",
            "name": "Formula Background Color",
            "description": "Use a different color. Useful for dark mode and the like. Format: #RRGGBB or '-' for transparent",
            "type": "string",
            "default": "-"
        },
        {
            "identifier": "usepackages",
            "name": "Packages to include in the preamble",
            "description": "Enter the packages comma separated",
            "type": "string",
            "default": "amsmath,amssymb,amsfonts"
        },
        {
            "identifier": "customPreamble",
            "name": "Custom preamble commands",
            "description": "Enter the preamble commands",
            "type": "text",
            "default": "\\newcommand{\\mycmd}[1]{\\bf \\underline{#1}}"
        },
        {
            "identifier": "debug",
            "name": "Debug logs",
            "description": "Display debug logs in the script panel.",
            "type": "boolean",
            "default": "false",
        }
    ];

    function log(text) {
        if (debug) {
            script.log("[LaTex] " + text)
        }
    }

    /**
     * Initializes the custom action
     */
    function init() {
        log("init")
        // create a menu entry to paste Latex code as an image
        script.registerCustomAction("latex-math-refresh", "Refresh LaTex Images", "Latex", "view-refresh");
        workDir = script.cacheDir("latex-math");
        log(workDir)
    }

    /**
     * This function is called when the markdown html of a note is generated
     *
     * It allows you to modify this html
     * This is for example called before by the note preview
     *
     * The method can be used in multiple scripts to modify the html of the preview
     *
     * @param {NoteApi} note - the note object
     * @param {string} html - the html that is about to being rendered
     * @param {string} forExport - the html is used for an export, false for the preview
     * @return {string} the modified html or an empty string if nothing should be modified
     */
    function noteToMarkdownHtmlHook(note, html, forExport) {
        // $ were replaced by <x-equation> tags
        //const regex_latex = /\$(?:\[(\d+)\])?([\s\S]+?)\$(?!\d)/g   // don't allow $4 as closing character
        const regex_latex = /(?:<x-equation>)(?:\[(\d+)\])?([\s\S]+?)(?:<\/x-equation>)/g // don't allow $4 as closing character
        var count = 0;
        var cmdList = [];
        html = html.replace(regex_latex, function(match, matchImageSize, latex, offset) {

            let imageSize = settingImageSize;

            if (matchImageSize != null && matchImageSize.length > 0) {
                imageSize = matchImageSize
            }

            latex = formulaPrefix + latex // add prefix from settings
            latex = latex.trim()
            const latexBase64 = Qt.btoa(latex)
            const filename = Qt.md5(latex)
            const path = workDir + "/" + filename + ".png"

            if (!script.fileExists(path)) { // performance: do not create the same formula twice
                count++;
                var bashCmd = getBashCmd(path, latexBase64)
                //execBashDetached(bashCmd, true)
                cmdList.push([count, path, bashCmd])
            }

            return `<img style='vertical-align: bottom;' height='${imageSize}' src="file://${path}" alt="LaTex">`; //style='vertical-align: middle;'
        });
        if (cmdList.length > 0) {
            execBashList(cmdList); // use a 'thread pool'
        }
        return html
    }

    function getPreamble() {
        var packages = usepackages.split(',')
        var preamble = ""
        // add packages
        packages.forEach(function myFunction(item) {
            preamble += `\\usepackage{${item}}`
        });
        // add custom preamble
        preamble += customPreamble
        return preamble
    }

    function getBashCmd(path, latexBase64) {
        const exec = executable
        const preamble = Qt.btoa(getPreamble())
        const quiet = " --quiet 1"; // --quiet OFF does not work (klatexformula bug?)
        const cmd = `"${exec}" -f "${formulaColor}" -b "${formulaBgColor}" --base64arg --preamble="${preamble}" --base64arg --latexinput="${latexBase64}" --dpi ${settingDPI} ${quiet} --output ${path}`
        //log("cmd: "+cmd)
        return cmd
    }

    /**
     * This function is called when a script thread is done executing.
     * Hint: thread[1]==0 helps to determine if a bulk of started processes for a certain identifier is done.
     *
     * @param {QString} callbackIdentifier - the provided id when calling startDetachedProcess()
     * @param {QString} resultSet - the result of the process
     * @param {QVariantList} cmd - the entire command array [0-executablePath, 1-parameters, 2-exitCode]
     * @param {QVariantList} thread - the thread information array [0-passed callbackParameter, 1-remaining threads for this identifier]
     */
    function onDetachedProcessCallback(callbackIdentifier, resultSet, cmd, thread) {
        if (callbackIdentifier == "callback-latex-math") {
            log("remaining: " + thread[1])
            if (thread[0].length > 0) {
                log("more to do")
                execBashList(thread[0])
            } else {
                log("done")
                script.regenerateNotePreview();
            }
        }
    }

    /**
     * This function invokes a bash command
     * @param cmdList 0-cmdNumber, 1-path, 2-cmd
     * @return the result or [true/false] if detached = true
     */
    function execBashList(cmdList) {
        const linuxExec = "bash";
        log("got cmds: " + cmdList.length)
        if (cmdList.length > 0) {
            const cmd = cmdList.pop();
			const exec = script.platformIsWindows() ? cmd[2] : linuxExec;
            const param = script.platformIsWindows() ? [] : ["-c", cmd[2]];
            log("exec" + cmd[0] + ": " + exec)
            script.startDetachedProcess(exec, param, "callback-latex-math", cmdList);
        }
    }

    /**
     * This function is invoked when a custom action is triggered
     * in the menu or via button
     *
     * @param identifier string the identifier defined in registerCustomAction
     */
    function customActionInvoked(identifier) {
        if (identifier !== "latex-math-refresh") {
            return;
        }
        log("clearing cache dir ...")
        log(script.clearCacheDir("latex-math"))
        script.regenerateNotePreview();
    }

}
